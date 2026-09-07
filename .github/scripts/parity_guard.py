#!/usr/bin/env python3
"""Fail-closed Flutter Web -> Next.js parity guard.

Flutter Web listed parity contracts are the reference/oracle. A normal
implementation PR may change a Next.js target OR the parity gate, never both;
it may never change a Next.js target together with its Flutter oracle.

Shared-product Next.js prefixes are default-deny: every changed file there must
already belong to a parity contract. Unknown behavior is BLOCK, never guessed.

Bootstrap exception: while the base branch does not yet contain the manifest,
the installation PR may add the gate and repair the target together. That
exception disappears automatically after this system reaches main.
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
MANIFEST_REPO_PATH = ".github/parity/contracts.json"

GATE_PATHS = {
    MANIFEST_REPO_PATH,
    ".github/workflows/parity.yml",
    ".github/workflows/teslimat.yml",
    ".github/scripts/parity_guard.py",
    ".github/scripts/parity_delivery_guard.py",
    ".github/scripts/tests/test_parity_guard.py",
    ".github/scripts/tests/test_parity_delivery_guard.py",
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
    if data.get("reference") != "Flutter Web":
        raise ParityError("Parite referansı tam olarak 'Flutter Web' olmalı.")

    policy = data.get("policy")
    if not isinstance(policy, dict):
        raise ParityError("Parite policy alanı zorunlu.")
    if policy.get("allow_unlisted_differences") is not False:
        raise ParityError("allow_unlisted_differences=false olmalı.")
    if policy.get("implementation_may_edit_oracle") is not False:
        raise ParityError("implementation_may_edit_oracle=false olmalı.")
    if policy.get("implementation_may_edit_gate") is not False:
        raise ParityError("implementation_may_edit_gate=false olmalı.")
    if policy.get("unverified_behavior") != "BLOCK":
        raise ParityError("unverified_behavior='BLOCK' olmalı.")

    required_prefixes = policy.get("contract_required_prefixes")
    if not isinstance(required_prefixes, list) or not required_prefixes:
        raise ParityError("contract_required_prefixes boş olamaz.")
    for prefix in required_prefixes:
        if not isinstance(prefix, str) or not normalize(prefix).startswith("public_web/"):
            raise ParityError(f"Geçersiz contract_required_prefix: {prefix!r}")

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


def requires_contract(path: str, manifest: dict[str, Any]) -> bool:
    normalized = normalize(path)
    prefixes = tuple(
        normalize(prefix).rstrip("/") + "/"
        for prefix in manifest["policy"]["contract_required_prefixes"]
    )
    return any(normalized.startswith(prefix) for prefix in prefixes)


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
                "Next implementation PR'ında referans değiştirilemez; "
                "referans değişikliği ayrı PR + manifest kilidi güncellemesi olmalı."
            )

    assertions = contract.get("oracle_assertions", {})
    if not isinstance(assertions, dict) or not assertions:
        raise ParityError(f"{contract_id}: oracle_assertions boş olamaz.")

    for repo_path, required_strings in assertions.items():
        path = root / normalize(repo_path)
        if not path.is_file():
            raise ParityError(f"{contract_id}: assertion oracle dosyası yok: {repo_path}")
        text = path.read_text(encoding="utf-8")
        if not isinstance(required_strings, list) or not required_strings:
            raise ParityError(f"{contract_id}: {repo_path} assertions boş olamaz.")
        for required in required_strings:
            if required not in text:
                raise ParityError(
                    f"{contract_id}: Flutter oracle sözleşmesi doğrulanamadı; "
                    f"{repo_path} içinde beklenen ifade yok: {required!r}"
                )

    flutter_tests = contract.get("flutter_tests", [])
    if not isinstance(flutter_tests, list) or not flutter_tests:
        raise ParityError(f"{contract_id}: flutter_tests boş olamaz.")
    for repo_path in flutter_tests:
        if not (root / normalize(repo_path)).is_file():
            raise ParityError(f"{contract_id}: Flutter oracle testi yok: {repo_path}")

    browser = contract.get("browser")
    if browser:
        expected = browser.get("expected_buttons")
        if not isinstance(expected, list) or not expected:
            raise ParityError(f"{contract_id}: browser.expected_buttons boş olamaz.")
        if len(expected) != len(set(expected)):
            raise ParityError(f"{contract_id}: browser.expected_buttons tekrar içeriyor.")
        if browser.get("enabled") is True:
            if not browser.get("route") or not browser.get("scope_text"):
                raise ParityError(f"{contract_id}: browser route/scope_text zorunlu.")

        button_oracles = browser.get("button_oracle_paths", [])
        if not isinstance(button_oracles, list) or not button_oracles:
            raise ParityError(f"{contract_id}: browser.button_oracle_paths boş olamaz.")
        forbidden = browser.get("forbidden_buttons", [])
        for repo_path in button_oracles:
            path = root / normalize(repo_path)
            if not path.is_file():
                raise ParityError(f"{contract_id}: button oracle dosyası yok: {repo_path}")
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


def base_has_manifest(base: str, root: Path = ROOT) -> bool:
    try:
        result = subprocess.run(
            ["git", "cat-file", "-e", f"{base}:{MANIFEST_REPO_PATH}"],
            cwd=root,
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError:
        return False
    return result.returncode == 0


def evaluate_changes(
    changed: list[str],
    manifest: dict[str, Any],
    root: Path = ROOT,
    *,
    enforce_gate_separation: bool = True,
) -> tuple[bool, list[str]]:
    changed_set = {normalize(path) for path in changed}
    affected_ids: list[str] = []
    errors: list[str] = []

    # Default-deny: ortak Flutter/Next ürün yüzeyinde contract dışında kalan
    # bir Next değişikliği yapılırsa ne amaçlandığını tahmin etmeyiz.
    for path in sorted(changed_set):
        if not requires_contract(path, manifest):
            continue
        if not any(path_matches(path, contract) for contract in manifest["contracts"]):
            errors.append(
                "CONTRACT_REQUIRED: Flutter Web referanslı ortak Next yüzeyinde "
                f"contract olmadan değişiklik yapılamaz: {path}. Önce ayrı bir "
                "referans/contract PR'ı ile Flutter oracle tanımlanmalı."
            )

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
            if enforce_gate_separation and gate_changed_paths:
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
    with Path(path).open("a", encoding="utf-8") as handle:
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
        bootstrap = not base_has_manifest(args.base, ROOT)
        affected, ids = evaluate_changes(
            changed,
            manifest,
            ROOT,
            enforce_gate_separation=not bootstrap,
        )
    except ParityError as exc:
        print(f"::error::Flutter → Next parite kapısı: {exc}", file=sys.stderr)
        return 1

    write_github_output(args.github_output, affected, ids)
    if bootstrap:
        print("Parite kapısı bootstrap PR'ında; gate+hedef ayrımı bu PR için tek seferlik açık.")
    if affected:
        print("Flutter → Next parite hedefi değişti: " + ", ".join(ids))
    else:
        print("Flutter → Next parite hedefi değişmedi; referans kilitleri geçerli.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
