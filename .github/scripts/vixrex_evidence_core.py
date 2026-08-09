"""VixRex görev snapshot'ını toplar, analiz eder ve insan özetini üretir."""

from __future__ import annotations

import hashlib
import json
import os
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Protocol

from vixrex_evidence_analysis import (
    analyze,
    body_hash,
    claim_binding,
    finalize_manifest,
)


SOURCE_HIERARCHY = (
    "runtime-artifact",
    "repo-diff",
    "executable-source",
    "issue-intent",
    "narrative-claim",
)
FULL_SHA_PATTERN = re.compile(r"^[0-9a-f]{40,64}$", re.IGNORECASE)


class EvidenceError(RuntimeError):
    """Snapshot semantik olarak güvenilir biçimde üretilemedi."""


class Runner(Protocol):
    def text(self, command: list[str], *, cwd: Path) -> str: ...
    def bytes(self, command: list[str], *, cwd: Path) -> bytes: ...


@dataclass(frozen=True)
class EvidenceRequest:
    root: Path
    issue_number: int
    base_ref: str


def _git_text(runner: Runner, root: Path, *arguments: str) -> str:
    return runner.text(["git", "--no-optional-locks", *arguments], cwd=root)


def _git_bytes(runner: Runner, root: Path, *arguments: str) -> bytes:
    return runner.bytes(["git", "--no-optional-locks", *arguments], cwd=root)


def _gh_json(runner: Runner, root: Path, *arguments: str) -> Any:
    raw = runner.text(["gh", *arguments], cwd=root)
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise EvidenceError("GitHub CLI geçerli JSON üretmedi") from exc


def _resolve_root(runner: Runner, candidate: Path) -> Path:
    candidate = candidate.resolve()
    return Path(_git_text(runner, candidate, "rev-parse", "--show-toplevel")).resolve()


def _resolve_commit(runner: Runner, root: Path, reference: str) -> str:
    value = _git_text(
        runner,
        root,
        "rev-parse",
        "--verify",
        "--end-of-options",
        f"{reference}^{{commit}}",
    ).strip()
    if not FULL_SHA_PATTERN.fullmatch(value):
        raise EvidenceError(f"Git referansı commit SHA'ya çözülemedi: {reference}")
    return value.casefold()


def _repository_slug(runner: Runner, root: Path) -> str:
    remote = _git_text(runner, root, "config", "--get", "remote.origin.url").strip()
    match = re.search(r"github\.com(?::|/)([^/\s:]+)/([^/\s]+)$", remote)
    if not match:
        raise EvidenceError("origin GitHub repository kimliğine çözülemedi")
    owner, repository = match.groups()
    if repository.endswith(".git"):
        repository = repository[:-4]
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", f"{owner}/{repository}"):
        raise EvidenceError("GitHub repository kimliği güvenli biçimde ayrıştırılamadı")
    return f"{owner}/{repository}"


def _parse_name_status(raw: bytes) -> list[dict[str, Any]]:
    tokens = raw.split(b"\0")
    if tokens and not tokens[-1]:
        tokens.pop()
    changes: list[dict[str, Any]] = []
    index = 0
    while index < len(tokens):
        status = os.fsdecode(tokens[index])
        index += 1
        path_count = 2 if status[:1] in {"R", "C"} else 1
        if index + path_count > len(tokens):
            raise EvidenceError("Git name-status çıktısı eksik")
        paths = [os.fsdecode(item) for item in tokens[index:index + path_count]]
        index += path_count
        changes.append({"status": status, "paths": paths})
    return sorted(changes, key=lambda item: (item["status"], item["paths"]))


def _parse_paths(raw: bytes) -> list[str]:
    return sorted(os.fsdecode(item) for item in raw.split(b"\0") if item)


def _worktree_fingerprint(runner: Runner, root: Path, untracked: list[str]) -> str:
    digest = hashlib.sha256()
    for label, arguments in (
        (b"staged\0", ("diff", "--cached", "--binary", "--no-ext-diff", "--no-textconv", "--")),
        (b"unstaged\0", ("diff", "--binary", "--no-ext-diff", "--no-textconv", "--")),
    ):
        digest.update(label)
        digest.update(_git_bytes(runner, root, *arguments))
    for value in untracked:
        path = root / Path(value)
        digest.update(b"untracked\0")
        digest.update(os.fsencode(value))
        digest.update(b"\0")
        try:
            if path.is_symlink():
                digest.update(b"symlink\0")
                digest.update(os.fsencode(os.readlink(path)))
                continue
            resolved = path.resolve(strict=True)
            resolved.relative_to(root)
            with resolved.open("rb") as handle:
                for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                    digest.update(chunk)
        except (OSError, ValueError) as exc:
            raise EvidenceError(f"Untracked dosya güvenle hashlenemedi: {value}") from exc
    return digest.hexdigest()


def _collect_changes(
    runner: Runner, root: Path, *, merge_base: str, head_sha: str
) -> dict[str, Any]:
    common = ("--name-status", "-z", "--no-ext-diff")
    committed = _parse_name_status(
        _git_bytes(runner, root, "diff", *common, merge_base, head_sha, "--")
    )
    staged = _parse_name_status(
        _git_bytes(runner, root, "diff", "--cached", *common, "--")
    )
    unstaged = _parse_name_status(_git_bytes(runner, root, "diff", *common, "--"))
    untracked = _parse_paths(
        _git_bytes(runner, root, "ls-files", "--others", "--exclude-standard", "-z", "--")
    )
    return {
        "committed": committed,
        "staged": staged,
        "unstaged": unstaged,
        "untracked": untracked,
        "worktree_sha256": _worktree_fingerprint(runner, root, untracked),
        "dirty": bool(staged or unstaged or untracked),
    }


def _collect_issue(
    runner: Runner, root: Path, *, repository: str, number: int
) -> tuple[dict[str, Any], str]:
    payload = _gh_json(
        runner, root, "issue", "view", str(number), "--repo", repository,
        "--json", "number,body,state,updatedAt,url,labels,comments",
    )
    if not isinstance(payload, dict) or payload.get("number") != number:
        raise EvidenceError(f"Issue #{number} beklenen biçimde alınamadı")
    body = payload.get("body")
    if not isinstance(body, str):
        raise EvidenceError(f"Issue #{number} gövdesi metin değil")
    raw_comments = payload.get("comments") if isinstance(payload.get("comments"), list) else []
    comments = []
    for item in raw_comments:
        if not isinstance(item, dict):
            continue
        comment_body = item.get("body") if isinstance(item.get("body"), str) else ""
        comments.append({
            "created_at": item.get("createdAt", ""),
            "updated_at": item.get("updatedAt", ""),
            "url": item.get("url", ""),
            "body_sha256": body_hash(comment_body),
            "provenance": "narrative-claim",
        })
    labels = payload.get("labels") if isinstance(payload.get("labels"), list) else []
    return ({
        "number": number,
        "state": payload.get("state", ""),
        "updated_at": payload.get("updatedAt", ""),
        "url": payload.get("url", ""),
        "labels": [item.get("name", "") for item in labels if isinstance(item, dict)],
        "comment_count": len(comments),
        "comments": comments,
        "body_sha256": body_hash(body),
        "provenance": "issue-intent",
    }, body)


def _collect_pull_requests(
    runner: Runner, root: Path, *, repository: str, branch: str, head_sha: str
) -> list[dict[str, Any]]:
    if not branch:
        return []
    payload = _gh_json(
        runner, root, "pr", "list", "--head", branch, "--state", "all",
        "--limit", "100", "--repo", repository, "--json",
        "number,body,url,headRefName,headRefOid,baseRefName,baseRefOid,state,updatedAt",
    )
    if not isinstance(payload, list):
        raise EvidenceError("İlişkili PR listesi beklenen biçimde değil")
    pull_requests = []
    for item in payload:
        if not isinstance(item, dict) or str(item.get("headRefOid", "")).casefold() != head_sha:
            continue
        number = item.get("number")
        detail = _gh_json(
            runner, root, "pr", "view", str(number), "--repo", repository,
            "--json", "number,headRefOid,baseRefOid,state,updatedAt,changedFiles,files",
        )
        if not isinstance(detail, dict) or detail.get("number") != number:
            raise EvidenceError(f"PR #{number} dosya listesi alınamadı")
        stable_fields = ("headRefOid", "baseRefOid", "state", "updatedAt")
        if any(detail.get(field) != item.get(field) for field in stable_fields):
            raise EvidenceError(f"PR #{number} snapshot alınırken değişti")
        raw_files = detail.get("files")
        changed_file_count = detail.get("changedFiles")
        if not isinstance(raw_files, list) or not isinstance(changed_file_count, int):
            raise EvidenceError(f"PR #{number} dosya listesi beklenen biçimde değil")
        changed_files = []
        for file_item in raw_files:
            if not isinstance(file_item, dict) or not isinstance(file_item.get("path"), str):
                raise EvidenceError(f"PR #{number} dosya kaydı beklenen biçimde değil")
            changed_files.append({
                "path": file_item["path"],
                "additions": file_item.get("additions", 0),
                "deletions": file_item.get("deletions", 0),
            })
        if len(changed_files) != changed_file_count:
            raise EvidenceError(f"PR #{number} dosya listesi eksik")
        body = item.get("body") if isinstance(item.get("body"), str) else ""
        binding = claim_binding(body, head_sha)
        pull_requests.append({
            "number": number,
            "url": item.get("url", ""),
            "state": item.get("state", ""),
            "head_ref": item.get("headRefName", ""),
            "head_oid": str(item.get("headRefOid", "")).casefold(),
            "base_ref": item.get("baseRefName", ""),
            "base_oid": str(item.get("baseRefOid", "")).casefold(),
            "updated_at": item.get("updatedAt", ""),
            "changed_file_count": changed_file_count,
            "changed_files": sorted(changed_files, key=lambda file_item: file_item["path"]),
            "body_sha256": body_hash(body),
            **binding,
            "provenance": "narrative-claim",
        })
    return sorted(pull_requests, key=lambda item: int(item["number"] or 0))


def collect_snapshot(request: EvidenceRequest, runner: Runner) -> dict[str, Any]:
    root = _resolve_root(runner, request.root)
    repository = _repository_slug(runner, root)
    head_sha = _resolve_commit(runner, root, "HEAD")
    base_sha = _resolve_commit(runner, root, request.base_ref)
    merge_bases = _git_text(runner, root, "merge-base", "--all", head_sha, base_sha).splitlines()
    if len(merge_bases) != 1 or not FULL_SHA_PATTERN.fullmatch(merge_bases[0]):
        raise EvidenceError("Tek ve geçerli merge-base üretilemedi")
    merge_base = merge_bases[0].casefold()
    branch = _git_text(runner, root, "branch", "--show-current").strip()
    git_dir = Path(
        _git_text(runner, root, "rev-parse", "--path-format=absolute", "--git-dir")
    ).resolve()
    changes = _collect_changes(runner, root, merge_base=merge_base, head_sha=head_sha)
    issue, body = _collect_issue(runner, root, repository=repository, number=request.issue_number)
    pull_requests = _collect_pull_requests(
        runner, root, repository=repository, branch=branch, head_sha=head_sha,
    )
    findings, referenced = analyze(root, issue, body, pull_requests, changes)
    refreshed_issue, refreshed_body = _collect_issue(
        runner, root, repository=repository, number=request.issue_number,
    )
    if refreshed_issue != issue or body_hash(refreshed_body) != body_hash(body):
        raise EvidenceError(f"Issue #{request.issue_number} snapshot alınırken değişti")
    refreshed_pull_requests = _collect_pull_requests(
        runner, root, repository=repository, branch=branch, head_sha=head_sha,
    )
    if refreshed_pull_requests != pull_requests:
        raise EvidenceError("PR snapshot alınırken değişti")
    if _resolve_commit(runner, root, "HEAD") != head_sha:
        raise EvidenceError("HEAD snapshot alınırken değişti")
    if _collect_changes(runner, root, merge_base=merge_base, head_sha=head_sha) != changes:
        raise EvidenceError("Worktree snapshot alınırken değişti")
    worktree_id = hashlib.sha256(os.path.normcase(str(git_dir)).encode("utf-8")).hexdigest()[:12]
    git_state = {
        "branch": branch, "head_sha": head_sha, "base_ref": request.base_ref,
        "base_sha": base_sha, "merge_base_sha": merge_base, **changes,
        "provenance": "repo-diff",
    }
    manifest = {
        "schema_version": "1.0",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "mode": "report-only",
        "source_hierarchy": list(SOURCE_HIERARCHY),
        "repository": repository,
        "worktree": {"id": worktree_id, "path": str(root), "git_dir": str(git_dir)},
        "git": git_state,
        "issue": {**issue, "referenced_paths": referenced},
        "pull_requests": pull_requests,
        "findings": findings,
    }
    return finalize_manifest(manifest)


__all__ = ["EvidenceError", "EvidenceRequest", "Runner", "collect_snapshot"]
