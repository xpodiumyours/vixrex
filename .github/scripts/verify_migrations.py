#!/usr/bin/env python3
"""Migration zinciri bekçisi.

NEDEN VAR
2026-08-05'te migration zinciri tamamen kırıldı: `supabase db reset` ilk
dosyada duruyordu. Üç sebep vardı — çekirdek şema bir yıl yanlış
tarihlenmişti, 12 sürüm numarası ÇİFTLENMİŞTİ ve bazı nesneler hiç
migration'a girmeden veritabanında oluşturulmuştu. Toparlamak 51 dosya
adı değişikliği ve bir taban şema çıkarmayı gerektirdi; o sırada yerel
veritabanı da kayboldu.

Bu betik o günün ucuz sigortası: sürüm numaraları benzersiz ve sıralı mı.
Veritabanı gerektirmez, saniyede biter.
"""

import re
import sys
from pathlib import Path

KLASOR = Path("supabase/migrations")
DESEN = re.compile(r"^(\d{14})_[a-z0-9_]+\.sql$")


def main() -> None:
    if not KLASOR.exists():
        print("[OK] Migration klasoru yok, kontrol atlandi")
        return

    dosyalar = sorted(p.name for p in KLASOR.glob("*.sql"))
    hata = False
    surumler: dict[str, str] = {}

    for ad in dosyalar:
        eslesme = DESEN.match(ad)
        if not eslesme:
            print(
                f"::error::{ad}: ad biçimi yanlış. "
                "Beklenen: 14 haneli sürüm + '_' + küçük harf ad + '.sql'"
            )
            hata = True
            continue

        surum = eslesme.group(1)
        if surum in surumler:
            print(
                f"::error::Sürüm çiftlenmiş: {surum}\n"
                f"  {surumler[surum]}\n  {ad}\n"
                "İki migration aynı sırayı alamaz; zincir kırılır."
            )
            hata = True
        else:
            surumler[surum] = ad

    if hata:
        sys.exit(1)

    print(f"[OK] {len(dosyalar)} migration, surumler benzersiz ve sirali")


if __name__ == "__main__":
    main()
