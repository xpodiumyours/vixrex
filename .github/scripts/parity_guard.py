#!/usr/bin/env python3
"""Fail-closed Flutter Web -> Next.js parity guard.

The Flutter side is the reference/oracle for listed parity contracts. An
implementation PR may change a Next.js target OR the oracle/gate, never both.
Oracle files are locked by Git blob SHA and required assertions.

This guard is intentionally independent of browser tooling so it can always run
first. Browser/Flutter behavior checks live in `.github/workflows/parity.yml`.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / ".github" / "parity" / "contracts.json"
MANIFEST_REPO_PATH = ".github/parity/contracts.json"

GATE_PATHS = {
    MANIFEST_REPO_PATH,
    ".github/workflows/parity.yml",
    ".github/scripts/parity_guard.py",
    ".github/scripts/tests/test_parity_guard.py",
    ".github/scripts/changed_surfaces.py",
    ".github/scripts/tests/test_changed_surfaces.py",
    ".github/scripts/teslimat.py",
    "public_web/e2e/flutter-next-parity.spec.ts",
}


class ParityError(RuntimeError):
    pass


def normalize(path: str) -> str:
    return path.replace("\\", "/").removeprefix("./").strip("/")


def git_blob_sha(path: Path) -> str:
    data = path.read_bytes()
    digest = hashlib.sha1()
    digest.update(f"blob {len(data)}\0".encode("utf-8"))
    digest.update(data)
    return digest.hexdigest()


def load_manifest(root: Path = ROOT) -> dict[str, Any]:
    path = root / MANIFEST_REPO_PATH
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ParityError(f"Parite manifesti okunamadı: {exc}") from exc

    if data.get("version") != 1:
        raise ParityError("Parite manifesti version=1 olmalı.")
    contracts = data.get("contracts")
    if not isinstance(contracts, list) or not contracts:
        raise ParityError("Parite manifestinde en az bir contract olmalı.")
    return data


def path_matches(path: str, contract: dict[str, Any]) -> bool:
    normalized = normalize(path)
    exact = {normalize(p) for p in contract.get("target_paths", [])}
    prefixes = tuple(
        normalize(p).rstrip("/") + "/" for p in contract.get("target_prefixes", [])
    )
    return normalized in exact or any(normalized.startswith(prefix) for prefix in prefixes)


def oracle_paths(contract: dict[str, Any]) -> set[str]:
    locked = contract.get("oracle_git_blobs", {})
    assertions = contract.get("oracle_assertions", {})
    return {normalize(p) for p in {*locked.keys(), *assertions.keys()}}


def validate_contract(contract: dict[str, Any], root: Path = ROOT) -> None:
    contract_id = contract.get("id")
    if not isinstance(contract_id, str) or not contract_id.strip():
        raise ParityError("Her parite contract'ının boş olmayan bir id alanı olmalı.")

    targets = contract.get("target_paths", [])
    prefixes = contract.get("target_prefixes", [])
    if not targets and not prefixes:
        raise ParityError(f"{contract_id}: target_paths veya target_prefixes gerekli.")

    locked = contract.get("oracle_git_blobs")
    if not isinstance(locked, dict) or not locked:
        raise ParityError(f"{contract_id}: oracle_git_blobs boş olamaz.")

    for repo_path, expected_sha in locked.items():
        path = root / normalize(repo_path)
        if not path.is_file():
            raise ParityError(f"{contract_id}: oracle dosyası yok: {repo_path}")
        actual_sha = git_blob_sha(path)
        if actual_sha != expected_sha:
            raise ParityError(
                f"{contract_id}: Flutter referans kilidi değişti: {repo_path} "
                f"(beklenen {expected_sha}, mevcut {actual_sha}). "
                "Next implementation PR'ında referans değiştirilemez. "
                "Referans değişikliği ayrı PR + manifest kilidi güncellemesi olmalı."
            )

    assertions = contract.get("oracle_assertions", {})
    if not isinstance(assertions, dict) or not assertions:
        raise ParityError(f"{contract_id}: oracle_assertions boş olamaz.")

    for repo_path, required_strings in assertions.items():
        path = root / normalize(repo_path)
        if not path.is_file():
            raise ParityError(f"{contract_id}: assertion oracle dosyası yok: {repo_path}")
        text = path.read_text(encoding="utf-8")
        for required in required_strings:
            if required not in text:
                raise ParityError(
                    f"{contract_id}: Flutter oracle sözleşmesi doğrulanamadı; "
                    f"{repo_path} içinde beklenen ifade yok: {required!r}"
                )

    browser = contract.get("browser")
    if browser:
        expected = browser.get("expected_buttons")
        if not isinstance(expected, list) or not expected:
            raise ParityError(f"{contract_id}: browser.expected_buttons boş olamaz.")
        if len(expected) != len(set(expected)):
            raise ParityError(f"{contract_id}: browser.expected_buttons tekrar içeriyor.")

        button_oracles = browser.get("button_oracle_paths", [])
        if not isinstance(button_oracles, list) or not button_oracles:
            raise ParityError(f"{contract_id}: browser.button_oracle_paths boş olamaz.")
        forbidden = browser.get("forbidden_buttons", [])
        for repo_path in button_oracles:
            path = root / normalize(repo_path)
            if not path.is_file():
                raise ParityError(
                    f"{contract_id}: button oracle dosyası yok: {repo_path}"
                )
            text = path.read_text(encoding="utf-8")
            for label in expected:
                if label not in text:
                    raise ParityError(
                        f"{contract_id}: browser butonu Flutter oracle'dan türemiyor; "
                        f"{repo_path} içinde {label!r} yok."
                    )
            for label in forbidden:
                if label in text:
                    raise ParityError(
                        f"{contract_id}: forbidden browser butonu Flutter oracle'da mevcut; "
                        f"{repo_path} içinde {label!r} bulundu."
                    )


def validate_manifest(root: Path = ROOT) -> dict[str, Any]:
    manifest = load_manifest(root)
    ids: set[str] = set()
    for contract in manifest["contracts"]:
        contract_id = contract.get("id")
        if contract_id in ids:
            raise ParityError(f"Tekrarlanan parite contract id: {contract_id}")
        ids.add(contract_id)
        validate_contract(contract, root)
    return manifest


def changed_files(base: str, head: str, root: Path = ROOT) -> list[str]:
    if not base or set(base) == {"0"}:
        raise ParityError("Geçerli bir base SHA bulunamadı.")
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", base, head, "--"],
            cwd=root,
            capture_output=True,
            text=True,
            check=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        raise ParityError(f"Değişen dosyalar okunamadı: {exc}") from exc
    return [normalize(line) for line in result.stdout.splitlines() if line.strip()]


def evaluate_changes(
    changed: list[str], manifest: dict[str, Any], root: Path = ROOT
) -> tuple[bool, list[str]]:
    changed_set = {normalize(path) for path in changed}
    affected_ids: list[str] = []
    errors: list[str] = []

    for contract in manifest["contracts"]:
        contract_id = contract["id"]
        target_changed = any(path_matches(path, contract) for path in changed_set)
        oracle_changed_paths = sorted(changed_set & oracle_paths(contract))
        gate_changed_paths = sorted(changed_set & GATE_PATHS)

        if target_changed:
            affected_ids.append(contract_id)
            if oracle_changed_paths:
                errors.append(
                    f"{contract_id}: Next hedefi ile Flutter oracle aynı PR'da değiştirilemez: "
                    + ", ".join(oracle_changed_paths)
                )
            if gate_changed_paths:
                errors.append(
                    f"{contract_id}: Next hedefi ile parite kapısı/manifesti aynı PR'da "
                    "değiştirilemez: "
                    + ", ".join(gate_changed_paths)
                )

        if oracle_changed_paths and MANIFEST_REPO_PATH not in changed_set:
            errors.append(
                f"{contract_id}: Flutter referansı değişti ama {MANIFEST_REPO_PATH} "
                "kilidi güncellenmedi: "
                + ", ".join(oracle_changed_paths)
            )

    if errors:
        raise ParityError("\n".join(errors))
    return bool(affected_ids), affected_ids


def write_github_output(path: str | None, affected: bool, ids: list[str]) -> None:
    if not path:
        return
    output_path = Path(path)
    with output_path.open("a", encoding="utf-8") as handle:
        handle.write(f"affected={'true' if affected else 'false'}\n")
        handle.write(f"contracts={','.join(ids)}\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", required=True, help="Diff başlangıç SHA'sı")
    parser.add_argument("--head", default="HEAD", help="Diff bitiş SHA'sı")
    parser.add_argument("--github-output", help="GITHUB_OUTPUT dosya yolu")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        manifest = validate_manifest(ROOT)
        changed = changed_files(args.base, args.head, ROOT)
        affected, ids = evaluate_changes(changed, manifest, ROOT)
    except ParityError as exc:
        print(f"::error::Flutter → Next parite kapısı: {exc}", file=sys.stderr)
        return 1

    write_github_output(args.github_output, affected, ids)
    if affected:
        print("Flutter → Next parite hedefi değişti: " + ", ".join(ids))
    else:
        print("Flutter → Next parite hedefi değişmedi; referans kilitleri geçerli.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
