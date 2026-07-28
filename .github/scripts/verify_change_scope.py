#!/usr/bin/env python3
"""Vixrex Kapsam Kontrol Scripti.

PR diff'ini ana dalla karşılaştırır, değişen yolları
.changes/<issue>.yml içindeki izinli yollarla kontrol eder.
"""

import os
import sys
import yaml
import subprocess
from pathlib import Path


def get_changed_files(base_ref: str = "origin/main") -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--name-only", base_ref, "HEAD"],
        capture_output=True, text=True, check=False,
    )
    if result.returncode != 0:
        print(f"::error::Git diff başarısız: {result.stderr}")
        sys.exit(1)
    files = [f.strip() for f in result.stdout.splitlines() if f.strip()]
    print(f"Değişen dosyalar ({len(files)}):")
    for f in files:
        print(f"  {f}")
    return files


def find_change_contract() -> str | None:
    changes_dir = Path(".changes")
    if not changes_dir.exists():
        return None
    yml_files = list(changes_dir.glob("*.yml")) + list(changes_dir.glob("*.yaml"))
    if not yml_files:
        return None
    # En son değiştirilen sözleşmeyi al
    latest = max(yml_files, key=lambda p: p.stat().st_mtime)
    print(f"Kullanılan sözleşme: {latest}")
    return str(latest)


def load_contract(path: str) -> dict:
    with open(path, "r") as f:
        return yaml.safe_load(f)


def check_file_permissions(changed_files: list[str], contract: dict) -> bool:
    allowed = contract.get("izinli_dosyalar", [])
    forbidden = contract.get("yasak_alanlar", [])

    def is_allowed(filepath: str) -> bool:
        for pattern in allowed:
            if filepath.startswith(pattern) or filepath == pattern:
                return True
        return False

    def is_forbidden(filepath: str) -> bool:
        for pattern in forbidden:
            if filepath.startswith(pattern):
                return True
        return False

    all_ok = True
    for f in changed_files:
        if is_allowed(f):
            print(f"  [OK] {f} (izinli)")
        elif is_forbidden(f):
            print(f"  [HATA] {f} (YASAK ALAN)")
            all_ok = False
        else:
            print(f"  [UYARI] {f} (izinli listede yok)")
            all_ok = False

    return all_ok


def check_production_file_limit(changed_files: list[str], max_files: int = 3) -> bool:
    """Varsayılan olarak en fazla 3 production dosyası."""
    production_extensions = {".dart", ".ts", ".tsx", ".js", ".jsx", ".sql", ".yaml", ".yml"}
    production_files = [
        f for f in changed_files
        if Path(f).suffix in production_extensions
        and not f.startswith(".github")
        and not f.startswith("docs/")
        and not f.startswith(".changes")
    ]
    if len(production_files) > max_files:
        print(f"::error::{len(production_files)} production dosyası değişmiş (limit: {max_files})")
        return False
    return True


def main():
    base_ref = os.environ.get("BASE_REF", "origin/main")
    changed = get_changed_files(base_ref)

    contract_path = find_change_contract()
    if contract_path is None:
        print("::warning::Değişiklik sözleşmesi bulunamadı, kapsam kontrolü atlanıyor.")
        # Sadece production dosya limitini kontrol et
        if not check_production_file_limit(changed):
            sys.exit(1)
        sys.exit(0)

    contract = load_contract(contract_path)

    print(f"\nAmaç: {contract.get('amaç', 'Belirtilmemiş')}")
    print()

    if not check_file_permissions(changed, contract):
        print("\n::error::Kapsam dışı dosya değişikliği tespit edildi!")
        sys.exit(1)

    if not check_production_file_limit(changed):
        sys.exit(1)

    print("\n[OK] Kapsam kontrolu basarili")


if __name__ == "__main__":
    main()
