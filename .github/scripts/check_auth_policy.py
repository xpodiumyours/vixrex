#!/usr/bin/env python3
"""Vixrex auth policy guard.

Kalıcı hesap = Google.
Ücretsiz 14 günlük kiralık vitrin denemesi = anonim/misafir.
Şifreli auth yolu üretim koduna geri dönemez.
"""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
SCAN_ROOTS = (ROOT / "lib", ROOT / "public_web" / "src")
SUFFIXES = {".dart", ".ts", ".tsx", ".js", ".jsx"}

FORBIDDEN = {
    "signInWithPassword": re.compile(r"signInWithPassword\s*\("),
    "password signup": re.compile(r"\.auth\.signUp\s*\("),
    "password reset": re.compile(r"resetPasswordForEmail\s*\("),
    "password update": re.compile(r"updateUser\s*\(\s*\{\s*password\s*:"),
}

errors: list[str] = []

for root in SCAN_ROOTS:
    for path in root.rglob("*"):
        if path.suffix not in SUFFIXES or not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for label, pattern in FORBIDDEN.items():
            if pattern.search(text):
                errors.append(f"{path.relative_to(ROOT)}: yasak şifre auth yolu: {label}")

contracts = {
    ROOT / "public_web/src/app/app/page.tsx": (
        "signInAnonymously(",
        "Next.js /app anonim oturumu korumuyor",
    ),
    ROOT / "public_web/src/lib/useKesfetKirala.ts": (
        "!session.user.is_anonymous",
        "Keşfet kiralama kalıcı hesap/misafir ayrımını kaybetti",
    ),
    ROOT / "public_web/src/app/rent-demo/page.tsx": (
        "14 gün",
        "14 günlük ücretsiz deneme sözleşmesi kayboldu",
    ),
    ROOT / "lib/config/app_router.dart": (
        "14 gün ücretsiz deneme süresi",
        "Flutter misafir kiralama sözleşmesi kayboldu",
    ),
}

for path, (needle, message) in contracts.items():
    text = path.read_text(encoding="utf-8")
    if needle not in text:
        errors.append(f"{path.relative_to(ROOT)}: {message}")

if errors:
    for error in errors:
        print(f"::error::{error}")
    raise SystemExit(1)

print("Auth policy OK: anonim deneme korunuyor; kalıcı hesapta şifreli yol yok.")
