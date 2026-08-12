#!/usr/bin/env python3
"""Kapsam bekçisi.

NEDEN VAR
2026-08-12'de ayrı bir bulut Claude Code oturumu, kullanıcıdan (Casper)
gerçek zamanlı onay almadan ~5 saat boyunca tek bir dalda dev bir iş yaptı:
StoreEditorController'ı 5 modüle böldü VE üstüne VIXREX_RULES'un "vitrin
yalnız Next.js'te render edilir" ve "iki düzenleme kapısı, üçüncüsü yok"
kurallarına aykırı olabilecek yepyeni bir "Ownership Channel" akışı kurdu
(PR #134, hiç merge edilmedi ama saatlerce kontrolsüz büyüdü). AGENTS.md'deki
skill yönlendirmesi ("büyük iş -> grill-with-docs -> to-spec -> to-tickets
-> implement") bunu yakalayamadı çünkü sadece dokümantasyon, uygulayan bir
mekanizma yoktu.

Casper kodu okuyarak bir PR'ın kapsamının doğru olup olmadığını kendi
kendine göremiyor (konuşarak yönetiyor, kod okumuyor). Bu betik onun
yerine bakar: PR beklenmedik büyüklükteyse görünür biçimde durur, sessizce
geçmez.

NE YAPAR
  - Değişen dosya sayısı ve satır sayısı bir eşiği aşarsa PR'ı kırmızıya
    düşürür (üretilmiş/lock dosyaları sayıma girmez).
  - Kaçış yolu: PR açıklamasına kullanıcıdan alınan onayı gösteren
    `Kapsam-Onay: <kısa özet>` satırı eklenir. Bu, ajanın sessizce
    doğaçlamasını değil, onayı AÇIKÇA YAZMASINI zorunlu kılar — geriye
    dönük denetlenebilir bir iz bırakır.
  - Eşiğin altındaki her PR için de kısa bir kapsam özeti basar; böylece
    Casper kodu okumadan "bu PR ne kadar büyük, nereye dokunmuş" görebilir.

Eşikleri ayarlamak gerekirse burada değiştirilir; başka yerde kopyası yok.
"""

import os
import re
import subprocess
import sys
from collections import Counter

DOSYA_ESIGI = 12
SATIR_ESIGI = 600

# Üretilmiş/kilit dosyaları saymak yanlış alarm üretir — insan/agent bunları
# elle büyütmüyor, araç büyütüyor.
SAYIMA_GIRMEYEN = re.compile(
    r"(^|/)(pubspec\.lock|package-lock\.json|.*\.g\.dart|.*\.freezed\.dart|.*\.lock)$"
)

ONAY_DESENI = re.compile(r"kapsam-onay\s*:\s*\S", re.IGNORECASE)


def git(*args: str) -> str:
    sonuc = subprocess.run(
        ["git", *args], capture_output=True, text=True, check=False
    )
    if sonuc.returncode != 0:
        print(f"::error::git {' '.join(args)} başarısız: {sonuc.stderr}")
        sys.exit(1)
    return sonuc.stdout


def degisen_dosyalar(taban: str) -> list[str]:
    return [
        y.strip()
        for y in git("diff", "--name-only", taban, "HEAD").splitlines()
        if y.strip() and not SAYIMA_GIRMEYEN.search(y.strip())
    ]


def satir_sayisi(taban: str, dosyalar: list[str]) -> int:
    if not dosyalar:
        return 0
    toplam = 0
    for satir in git("diff", "--numstat", taban, "HEAD", "--", *dosyalar).splitlines():
        parca = satir.split("\t")
        if len(parca) < 2:
            continue
        for deger in parca[:2]:
            if deger.isdigit():
                toplam += int(deger)
    return toplam


def alan_ozeti(dosyalar: list[str]) -> Counter:
    sayac: Counter = Counter()
    for yol in dosyalar:
        ilk = yol.split("/", 1)[0]
        sayac[ilk] += 1
    return sayac


def main() -> None:
    taban = os.environ.get("BASE_REF", "origin/main")
    pr_metni = (
        os.environ.get("PR_TITLE", "") + "\n" + os.environ.get("PR_BODY", "")
    )

    dosyalar = degisen_dosyalar(taban)
    satirlar = satir_sayisi(taban, dosyalar)
    ozet = alan_ozeti(dosyalar)

    print(f"[BILGI] {len(dosyalar)} dosya, {satirlar} satır değişti.")
    if ozet:
        for alan, adet in ozet.most_common():
            print(f"  - {alan}/: {adet} dosya")

    asildi = len(dosyalar) > DOSYA_ESIGI or satirlar > SATIR_ESIGI
    if not asildi:
        print("[OK] Kapsam sınırlar içinde.")
        return

    if ONAY_DESENI.search(pr_metni):
        print(
            "[OK] Kapsam büyük ama PR açıklamasında 'Kapsam-Onay:' satırı var, "
            "kullanıcı onayı işaretli kabul edildi."
        )
        return

    print(
        f"::error::Bu PR {len(dosyalar)} dosya / {satirlar} satır değiştiriyor "
        f"(eşik: {DOSYA_ESIGI} dosya / {SATIR_ESIGI} satır). AGENTS.md kuralına "
        "göre bu boyutta iş grill-with-docs -> to-spec -> to-tickets -> "
        "implement akışından, yani kullanıcı onayından geçmeli."
    )
    print(
        "::error::Kullanıcıdan onay aldıysan PR açıklamasına şu satırı ekle: "
        "'Kapsam-Onay: <neyi neden onayladığının kısa özeti>'. Onay yoksa "
        "işi küçük, tek amaçlı PR'lara böl (bkz. 2026-08-12 PR #134 dersi)."
    )
    sys.exit(1)


if __name__ == "__main__":
    main()
