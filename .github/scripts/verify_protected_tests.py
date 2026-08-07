#!/usr/bin/env python3
"""Korunan test bekçisi.

NEDEN VAR
Bu proje kararlarını sözleşme testleriyle kilitliyor: bir davranış doğru
kabul edildiğinde ona bakan bir test yazılıyor. Kaymayı yakalayan şey o
testler. Ama test silinirse ya da beklentisi gevşetilirse kimse fark
etmiyor — Casper'ın "düzelttik, geri geldi" dediği döngünün sebebi bu.

2026-08-07'de somut örneği çıktı: `test/public_site_config_test.dart`
içindeki iki test YANLIŞ davranışı kilitliyordu ("ayar boşsa uygulamanın
kendi adresine düş"). Canlıda tam olarak o oldu ve testler yeşildi.

Bu betik iki şeye bakar:
  1. Korunan bir test dosyası SİLİNMİŞ mi
  2. Değişen test dosyalarına susturma eklenmiş mi (skip/only/xit)

Uyarlama notu (2026-08-07): özgün betik `test/contracts/` gibi
klasörleri koruyordu; bu depoda sözleşme testleri `test/` ve
`public_web/tests/` altında DÜZ duruyor. Olduğu gibi alınsaydı hiçbir
şeyi korumazdı. Desenler gerçek yapıya göre yazıldı.
"""

import os
import re
import subprocess
import sys

# Korunan test desenleri — bu depodaki gerçek yerleşim.
PROTECTED_TEST_PATTERNS = [
    r"^test/.*_test\.dart$",
    r"^public_web/tests/.*\.test\.ts$",
    r"^integration_test/.*\.dart$",
    r"^supabase/tests/.*$",
]

# Testi sessizce devre dışı bırakan kalıplar.
SUSPICIOUS_PATTERNS = [
    (r"\.skip\b", "Test `.skip` kullanımı"),
    (r"\.only\b", "Test `.only` kullanımı"),
    (r"\bskip\s*:\s*true", "Test `skip: true`"),
    (r"\bxit\s*\(", "Test `xit(` (pending)"),
    (r"\bxdescribe\s*\(", "Test `xdescribe(` (pending)"),
    (r"\btest\.todo\b", "Test `test.todo`"),
]


def korunuyor_mu(yol: str) -> bool:
    return any(re.match(p, yol) for p in PROTECTED_TEST_PATTERNS)


def git(*args: str) -> str:
    sonuc = subprocess.run(
        ["git", *args], capture_output=True, text=True, check=False
    )
    if sonuc.returncode != 0:
        print(f"::error::git {' '.join(args)} başarısız: {sonuc.stderr}")
        sys.exit(1)
    return sonuc.stdout


def silinen_testler(taban: str) -> list[str]:
    silinen = []
    for satir in git("diff", "--name-status", taban, "HEAD").splitlines():
        if satir.startswith("D\t"):
            yol = satir[2:].strip()
            if korunuyor_mu(yol):
                silinen.append(yol)
    return silinen


def degisen_testler(taban: str) -> list[str]:
    return [
        y.strip()
        for y in git("diff", "--name-only", taban, "HEAD").splitlines()
        if y.strip() and korunuyor_mu(y.strip())
    ]


def susturma_bulgulari(yollar: list[str]) -> list[tuple[str, str]]:
    bulgular = []
    for yol in yollar:
        if not os.path.exists(yol):
            continue
        try:
            with open(yol, "r", encoding="utf-8") as f:
                icerik = f.read()
        except Exception:
            continue

        # Yorum satırları sayılmaz: açıklamada geçmesi hata değil.
        kod = "\n".join(
            s for s in icerik.splitlines() if not s.strip().startswith(("//", "#"))
        )

        for desen, aciklama in SUSPICIOUS_PATTERNS:
            if re.search(desen, kod):
                bulgular.append((yol, aciklama))
    return bulgular


def main() -> None:
    taban = os.environ.get("BASE_REF", "origin/main")
    hata = False

    silinen = silinen_testler(taban)
    if silinen:
        print("::error::Korunan test dosyaları silinmiş:")
        for yol in silinen:
            print(f"  x {yol}")
        print(
            "::error::Bir test artık doğru değilse GÜNCELLE ve nedenini yaz; "
            "silmek kararı geri alır."
        )
        hata = True

    for yol, aciklama in susturma_bulgulari(degisen_testler(taban)):
        print(f"::error::{yol}: {aciklama}")
        hata = True

    if hata:
        sys.exit(1)

    print("[OK] Korunan test kontrolleri basarili")


if __name__ == "__main__":
    main()
