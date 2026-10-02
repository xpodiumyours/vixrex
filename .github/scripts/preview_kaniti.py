#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import changed_surfaces

KANIT_ORUNTUSU = re.compile(r"^Preview-Kanit:\s*(https://\S+)", re.MULTILINE)


def kanit_adresi(mesajlar: list[str]) -> str | None:
    for mesaj in mesajlar:
        eslesme = KANIT_ORUNTUSU.search(mesaj)
        if eslesme:
            return eslesme.group(1).rstrip(".,;)")
    return None


def calisma_yuzeyi_degisti(yollar: list[str]) -> bool:
    sonuc = changed_surfaces.classify_paths(yollar)
    return bool(sonuc.get("flutter") or sonuc.get("schema") or sonuc.get("public_web"))


def secim_mesajlari(base: str, head: str) -> list[str]:
    root = changed_surfaces.repository_root()
    cikti = subprocess.run(
        ["git", "log", "-z", "--format=%B", base + ".." + head],
        cwd=root,
        capture_output=True,
        text=True,
        check=False,
    )
    if cikti.returncode != 0:
        raise SystemExit("git log çalışmadı: " + cikti.stderr.strip())
    return [parca for parca in cikti.stdout.split("\0") if parca.strip()]


def denetle(yollar: list[str], mesajlar: list[str]) -> tuple[bool, bool, str | None]:
    if not calisma_yuzeyi_degisti(yollar):
        return (True, False, None)
    adres = kanit_adresi(mesajlar)
    if adres is None:
        return (False, True, None)
    return (True, True, adres)


def main() -> int:
    secici = argparse.ArgumentParser()
    secici.add_argument("--base", required=True)
    secici.add_argument("--head", required=True)
    args = secici.parse_args()
    try:
        yollar = changed_surfaces.changed_files(args.base, args.head)
    except (OSError, subprocess.CalledProcessError, ValueError):
        yollar = ["public_web/"]
    try:
        mesajlar = secim_mesajlari(args.base, args.head)
    except SystemExit as hata:
        print("preview-kaniti: FAIL (" + str(hata) + ")")
        return 1
    gecti, gerekli, adres = denetle(yollar, mesajlar)
    if not gerekli:
        print("preview-kaniti: SKIP (çalışma yüzeyi değişmedi)")
        return 0
    if not gecti:
        print("preview-kaniti: FAIL (commit mesajlarında 'Preview-Kanit: https://...' yok)")
        return 1
    print("preview-kaniti: PASS (" + str(adres) + ")")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
