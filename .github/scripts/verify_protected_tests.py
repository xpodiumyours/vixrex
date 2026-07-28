#!/usr/bin/env python3
"""Vixrex Korunan Test Kontrol Scripti.

Test dosyalarının silinmesini, skip/.only eklenmesini,
beklentilerin gevşetilmesini ve test bypass'larını kontrol eder.
"""

import os
import re
import sys
import subprocess
from pathlib import Path


PROTECTED_TEST_DIRS = [
    "test/contracts/",
    "test/",
    "integration_test/",
    "public_web/src/__tests__/contracts/",
    "public_web/src/",
    "supabase/tests/",
]

SUSPICIOUS_PATTERNS = [
    (r"\.skip\b", "Test `.skip` kullanımı"),
    (r"\.only\b", "Test `.only` kullanımı"),
    (r"skip\s*:\s*true", "Test `skip: true`"),
    (r"skip\s*=\s*true", "Test `skip = true`"),
    (r"xit\(", "Test `xit(` (pending)"),
    (r"xdescribe\(", "Test `xdescribe(` (pending)"),
]

BYPASS_PATTERNS = [
    (r"if\s*\(.*test.*\)", "Test ortamı bypass'ı"),
    (r"process\.env\.(?:NODE_ENV|CI|TEST)", "Env tabanlı bypass"),
    (r"kIsWeb\s*&&\s*kDebugMode", "Flutter web debug bypass"),
]


def get_changed_test_files(base_ref: str = "origin/main") -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--name-only", base_ref, "HEAD"],
        capture_output=True, text=True, check=False,
    )
    if result.returncode != 0:
        print(f"::error::Git diff başarısız: {result.stderr}")
        sys.exit(1)

    files = [f.strip() for f in result.stdout.splitlines() if f.strip()]
    test_files = []
    for f in files:
        for d in PROTECTED_TEST_DIRS:
            if f.startswith(d):
                test_files.append(f)
                break
    return test_files


def check_deleted_tests(base_ref: str = "origin/main") -> list[str]:
    """Silinmiş test dosyalarını kontrol eder."""
    result = subprocess.run(
        ["git", "diff", "--name-status", base_ref, "HEAD"],
        capture_output=True, text=True, check=False,
    )
    if result.returncode != 0:
        return []

    deleted = []
    for line in result.stdout.splitlines():
        if line.startswith("D\t"):
            path = line[2:].strip()
            for d in PROTECTED_TEST_DIRS:
                if path.startswith(d):
                    deleted.append(path)
                    break
    return deleted


def check_suspicious_patterns(file_paths: list[str]) -> list[tuple[str, str]]:
    findings = []
    for fp in file_paths:
        if not os.path.exists(fp):
            continue
        try:
            with open(fp, "r") as f:
                content = f.read()
        except Exception:
            continue

        for pattern, desc in SUSPICIOUS_PATTERNS + BYPASS_PATTERNS:
            if re.search(pattern, content, re.IGNORECASE):
                findings.append((fp, desc))
    return findings


def main():
    base_ref = os.environ.get("BASE_REF", "origin/main")
    changed_tests = get_changed_test_files(base_ref)
    deleted_tests = check_deleted_tests(base_ref)

    errors = False

    if deleted_tests:
        print("::error::Korunan test dosyaları silinmiş:")
        for f in deleted_tests:
            print(f"  ✗ {f}")
        errors = True

    if changed_tests:
        findings = check_suspicious_patterns(changed_tests)
        for fp, desc in findings:
            print(f"::error::{fp}: {desc}")
            errors = True

    if not errors:
        print("✓ Korunan test kontrolleri başarılı")
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
