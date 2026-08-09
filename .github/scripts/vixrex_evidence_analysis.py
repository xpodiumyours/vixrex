"""Issue/PR anlatısını repo kanıtıyla karşılaştıran saf evidence analizi."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any


HEADING_PATTERN = re.compile(r"^#{2,6}\s+(.+?)\s*$", re.MULTILINE)
PATH_TOKEN_PATTERN = re.compile(r"`([^`\r\n]{1,240})`")
SAFE_PATH_PATTERN = re.compile(r"^[\w./\\ \-\[\]]+$", re.UNICODE)
COMMAND_PREFIX_PATTERN = re.compile(
    r"^(?:dart|flutter|gh|git|npm|npx|pnpm|powershell|pwsh|python3?|yarn)\s",
    re.IGNORECASE,
)
NEGATIVE_PATH_PATTERN = re.compile(
    r"\b(?:bulunmaz|kaldırıldı|kullanılmaz|oluşturulmaz|silindi|tutulmaz|yasaktır)\b",
    re.IGNORECASE,
)
UNCHECKED_TASK_PATTERN = re.compile(r"^\s*[-*]\s+\[\s\]", re.MULTILINE)
CLAIM_PATTERN = re.compile(
    r"(?:canlı(?:da)?\s+doğrulan|production.{0,80}(?:doğrulan|uygulan)|"
    r"\b\d+\s+test.{0,60}geçt|test(?:ler)?\s+geçt|migration.{0,80}uygulan|"
    r"\bçalışıyor\b(?!\s+m[ıiuü]\b)|\bci\s+(?:yeşil|green|passed)\b|"
    r"\bsmoke(?:\s+test)?\s+(?:başarılı|geçti|passed)\b|"
    r"\b(?:all\s+)?tests?\s+(?:passed|green)\b|"
    r"\b(?:tüm\s+)?test(?:ler)?\s+(?:başarılı|yeşil)\b)",
    re.IGNORECASE | re.DOTALL,
)
ARTIFACT_PATTERN = re.compile(
    r"(?:https://github\.com/[^\s)]+/actions/runs/\d+|[\w./\\-]*evidence\.json)",
    re.IGNORECASE,
)
PATH_SUFFIXES = {
    ".dart", ".json", ".md", ".mjs", ".ps1", ".py", ".sql",
    ".toml", ".ts", ".tsx", ".yaml", ".yml",
}
IGNORED_PATH_SECTIONS = {
    "acceptance", "allowed files", "kabul", "kabul ölçütleri", "kapsam dışı", "kırmızı kanıt",
    "out of scope", "outcome", "red evidence", "required facts", "sonuç",
    "izinli dosyalar", "zorunlu bilgiler",
}


def body_hash(body: str) -> str:
    return hashlib.sha256(body.encode("utf-8")).hexdigest()


def claim_binding(body: str, head_sha: str) -> dict[str, bool]:
    return {
        "contains_verification_claim": bool(CLAIM_PATTERN.search(body)),
        "claim_bound_to_head": head_sha in body.casefold(),
        "claim_mentions_artifact": bool(ARTIFACT_PATTERN.search(body)),
    }


def _claim_sections(body: str) -> list[str]:
    matches = list(HEADING_PATTERN.finditer(body))
    sections = [body[:matches[0].start()]] if matches else [body]
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(body)
        heading = " ".join(match.group(1).split()).casefold()
        if heading not in IGNORED_PATH_SECTIONS:
            sections.append(body[match.end():end])
    return sections


def _looks_like_repo_path(value: str) -> bool:
    if not value or value.startswith(("-", "/", "http://", "https://")):
        return False
    if COMMAND_PREFIX_PATTERN.search(value):
        return False
    if not SAFE_PATH_PATTERN.fullmatch(value) or ".." in Path(value).parts:
        return False
    return Path(value.replace("\\", "/")).suffix.casefold() in PATH_SUFFIXES


def referenced_paths(body: str) -> list[str]:
    paths: list[str] = []
    for section in _claim_sections(body):
        for match in PATH_TOKEN_PATTERN.finditer(section):
            value = match.group(1).strip()
            line_start = section.rfind("\n", 0, match.start()) + 1
            line_end = section.find("\n", match.end())
            line = section[line_start:] if line_end == -1 else section[line_start:line_end]
            if NEGATIVE_PATH_PATTERN.search(line):
                continue
            if _looks_like_repo_path(value) and value not in paths:
                paths.append(value)
    return paths


def _safe_path(root: Path, value: str) -> Path | None:
    resolved = (root / Path(value.replace("\\", "/"))).resolve()
    try:
        resolved.relative_to(root)
    except ValueError:
        return None
    return resolved


def _finding(
    code: str, status: str, source: str, detail: str, severity: str = "warning"
) -> dict[str, str]:
    return {
        "code": code,
        "status": status,
        "severity": severity,
        "source": source,
        "detail": detail,
    }


def analyze(
    root: Path,
    issue: dict[str, Any],
    body: str,
    pull_requests: list[dict[str, Any]],
    changes: dict[str, Any],
) -> tuple[list[dict[str, str]], list[str]]:
    findings: list[dict[str, str]] = []
    referenced = referenced_paths(body)
    missing = []
    for value in referenced:
        path = _safe_path(root, value)
        if path is None or not path.exists():
            missing.append(value)
    if missing:
        findings.append(_finding(
            "missing_referenced_path", "contradicted", "repo-diff",
            "Issue repoda bulunmayan yolu gösteriyor: " + ", ".join(missing),
        ))
    if str(issue.get("state", "")).upper() == "CLOSED" and UNCHECKED_TASK_PATTERN.search(body):
        findings.append(_finding(
            "closed_issue_with_unchecked_tasks", "contradicted", "issue-intent",
            f"Issue #{issue['number']} kapalı fakat tamamlanmamış görev kutuları içeriyor.",
        ))
    for pull_request in pull_requests:
        if pull_request["contains_verification_claim"]:
            findings.append(_finding(
                "unbound_pr_claim", "unverified", "narrative-claim",
                f"PR #{pull_request['number']} iddiasını doğrulayan "
                "HEAD-bağlı runtime artefaktı yok.",
            ))
    if changes["dirty"]:
        count = len(changes["staged"]) + len(changes["unstaged"]) + len(changes["untracked"])
        findings.append(_finding(
            "dirty_worktree", "verified", "repo-diff",
            f"Worktree {count} yerel değişiklik içeriyor.", "info",
        ))
    return findings, referenced


def result(findings: list[dict[str, str]]) -> dict[str, Any]:
    counts = {
        status: sum(item["status"] == status for item in findings)
        for status in ("verified", "unverified", "contradicted")
    }
    if counts["contradicted"]:
        status, would_exit = "contradicted", 1
    elif counts["unverified"]:
        status, would_exit = "unverified", 3
    else:
        status, would_exit = "verified", 0
    return {
        "status": status,
        "counts": counts,
        "blocking_findings": [
            item["code"] for item in findings if item["status"] != "verified"
        ],
        "would_exit": would_exit,
        "effective_exit": 0,
    }


def _sources(manifest: dict[str, Any]) -> list[dict[str, str]]:
    repository = manifest["repository"]
    git_state = manifest["git"]
    issue = manifest["issue"]
    sources = [{
        "id": "git:snapshot",
        "kind": "repo-diff",
        "locator": repository,
        "revision": git_state["head_sha"],
        "retrieval": "success",
    }, {
        "id": f"issue:{issue['number']}",
        "kind": "issue-intent",
        "locator": issue["url"],
        "revision": issue["updated_at"],
        "sha256": issue["body_sha256"],
        "retrieval": "success",
    }]
    sources.extend({
        "id": f"pr:{item['number']}",
        "kind": "narrative-claim",
        "locator": item["url"],
        "revision": item["head_oid"],
        "sha256": item["body_sha256"],
        "retrieval": "success",
    } for item in manifest["pull_requests"])
    return sources


def _integrity(manifest: dict[str, Any]) -> dict[str, str]:
    canonical = {
        key: value
        for key, value in manifest.items()
        if key not in {"generated_at_utc", "integrity"}
    }
    encoded = json.dumps(canonical, ensure_ascii=True, sort_keys=True, separators=(",", ":"))
    return {
        "canonical_fields_version": "2",
        "snapshot_sha256": hashlib.sha256(encoded.encode()).hexdigest(),
    }


def finalize_manifest(manifest: dict[str, Any]) -> dict[str, Any]:
    manifest["sources"] = _sources(manifest)
    manifest["result"] = result(manifest["findings"])
    manifest["integrity"] = _integrity(manifest)
    return manifest


def render_summary(manifest: dict[str, Any]) -> str:
    git_state, issue, outcome = manifest["git"], manifest["issue"], manifest["result"]
    lines = [
        "# VixRex görev kanıtı", "",
        f"- Üretim zamanı (UTC): `{manifest['generated_at_utc']}`",
        f"- Repo / worktree: `{manifest['repository']}` / `{manifest['worktree']['path']}`",
        f"- Branch / HEAD: `{git_state['branch']}` / `{git_state['head_sha']}`",
        f"- Base / merge-base: `{git_state['base_ref']}` / `{git_state['merge_base_sha']}`",
        f"- Issue: [#{issue['number']}]({issue['url']}) — `{issue['state']}`",
        f"- Sonuç: **{outcome['status']}** (report-only; enforce exit `{outcome['would_exit']}`)",
        f"- Snapshot: `{manifest['integrity']['snapshot_sha256']}`", "", "## Bulgular", "",
    ]
    if manifest["findings"]:
        lines.extend(
            f"- `{item['code']}` — **{item['status']}** ({item['source']}): {item['detail']}"
            for item in manifest["findings"]
        )
    else:
        lines.append("- Başlangıç çelişkisi bulunmadı.")
    lines.extend([
        "",
        "> PR ve doküman metni iddiadır; bu özet JSON manifestten türetilmiştir.",
        "",
    ])
    return "\n".join(lines)


__all__ = [
    "analyze",
    "body_hash",
    "claim_binding",
    "finalize_manifest",
    "referenced_paths",
    "render_summary",
    "result",
]
