#!/usr/bin/env python3
"""Repository katmanı dışındaki doğrudan Supabase erişimini dondurur."""

import json
import sys
from pathlib import Path

RATCHET_DOSYASI = (
    Path(__file__).resolve().parent.parent / "supabase_erisim_ratchet.json"
)


def erisim_dosyalarini_bul(kok: Path) -> list[str]:
    lib = kok / "lib"
    if not lib.exists():
        return []

    bulunanlar: list[str] = []
    for dosya in lib.rglob("*.dart"):
        yol = dosya.relative_to(kok)
        if yol.parts[:2] == ("lib", "repositories"):
            continue
        icerik = dosya.read_text(encoding="utf-8")
        if "Supabase.instance" in icerik:
            bulunanlar.append(yol.as_posix())
    return sorted(bulunanlar)


def kontrol_et(kayit: dict, kok: Path) -> list[str]:
    mevcut_sayi = kayit["mevcut_sayi"]
    bulunanlar = erisim_dosyalarini_bul(kok)
    if len(bulunanlar) <= mevcut_sayi:
        return []

    return [
        "Repository dışındaki doğrudan Supabase erişimi "
        f"{mevcut_sayi} dosyadan {len(bulunanlar)} dosyaya çıktı. Yeni erişimi "
        "lib/repositories/ altına taşı; sayı azaldıysa "
        ".github/supabase_erisim_ratchet.json içindeki mevcut_sayi değerini "
        "elle düşür."
    ]


def main() -> None:
    if not RATCHET_DOSYASI.exists():
        print(f"[BILGI] {RATCHET_DOSYASI} yok, kontrol atlanıyor.")
        return

    kayit = json.loads(RATCHET_DOSYASI.read_text(encoding="utf-8"))
    kok = RATCHET_DOSYASI.parent.parent
    bulunanlar = erisim_dosyalarini_bul(kok)
    hatalar = kontrol_et(kayit, kok)

    if hatalar:
        for hata in hatalar:
            print(f"::error::{hata}")
        sys.exit(1)

    print(
        f"[OK] Repository dışı Supabase erişimi: "
        f"{len(bulunanlar)}/{kayit['mevcut_sayi']} dosya."
    )


if __name__ == "__main__":
    main()
