#!/usr/bin/env python3
"""Dosya büyüklüğü rateti (ratchet).

NEDEN VAR
`lib/controllers/store_editor_controller.dart` 2026-08 içinde 1388 satıra
kadar büyüdü. AGENTS.md'nin 400 satır kuralı vardı ama hiçbir yerde
otomatik kontrol edilmiyordu — yalnız insan/ajan hatırlarsa uygulanıyordu.
Dokuz fazlık bir parçalama operasyonuyla (bkz.
docs/agents/store-editor-controller-parcalama.md) 1072'ye indirildi. Bu
betik o kazanımı KORUR: izlenen dosyalar buradaki kayıtlı tavanın üstüne
çıkarsa PR kırmızıya düşer — "unuttuk, sessizce büyüdü" bir daha olmaz.

NE YAPAR
  - `.github/dosya_boyutu_ratchet.json`'daki her dosyanın bu PR sonrası
    GERÇEK satır sayısını kayıtlı tavanla karşılaştırır.
  - Aşarsa kırmızı: ya kod tavanın altına indirilir (yeni bir servise
    taşınarak), ya da — gerçekten gerekiyorsa — aynı PR'da tavan
    YÜKSELTİLİR ve `not` alanına neden yazılır. Bu, sessiz büyümeyi değil,
    görünür/bilinçli büyümeyi zorunlu kılar (`verify_pr_scope.py`'deki
    `Kapsam-Onay:` ile aynı felsefe — burada onay, JSON diff'inin
    kendisinde görünür).
  - Dosya tavanın ALTINDAYSA hata vermez; tavanı otomatik indirmez de —
    küçülünce tavanı elle indirmek isteğe bağlı, ayrı bir temizlik adımı.

YENİ DOSYA İZLEMEK İÇİN
`.github/dosya_boyutu_ratchet.json`'a yeni bir satır ekle, ilk tavanı o
dosyanın MEVCUT satır sayısı yap.
"""

import json
import sys
from pathlib import Path

RATCHET_DOSYASI = Path(__file__).resolve().parent.parent / "dosya_boyutu_ratchet.json"


def kontrol_et(kayitlar: dict, kok: Path) -> list[str]:
    """Her kayıtlı dosyanın gerçek satır sayısını tavanla karşılaştırır.

    Döndürdüğü liste boşsa her şey tavanın altında demektir. Saf fonksiyon
    (I/O yalnız dosya okuma) — test edilebilir.
    """
    hatalar: list[str] = []
    for yol, bilgi in kayitlar.items():
        tavan = bilgi["tavan"] if isinstance(bilgi, dict) else bilgi
        dosya = kok / yol
        if not dosya.exists():
            continue

        with dosya.open(encoding="utf-8") as f:
            gercek = sum(1 for _ in f)
        if gercek > tavan:
            hatalar.append(
                f"{yol} {gercek} satıra çıktı (tavan: {tavan}). Ya kodu "
                "tavanın altına indir (yeni bir servise taşı), ya da "
                "gerçekten gerekliyse .github/dosya_boyutu_ratchet.json'daki "
                "tavanı bu PR'da bilinçli olarak yükselt ve 'not' alanına "
                "nedenini yaz."
            )
    return hatalar


def main() -> None:
    if not RATCHET_DOSYASI.exists():
        print(f"[BILGI] {RATCHET_DOSYASI} yok, kontrol atlanıyor.")
        return

    kayitlar = json.loads(RATCHET_DOSYASI.read_text(encoding="utf-8"))
    kok = RATCHET_DOSYASI.parent.parent  # repo kökü

    hatalar = kontrol_et(kayitlar, kok)
    for yol, bilgi in kayitlar.items():
        dosya = kok / yol
        if not dosya.exists():
            print(f"[BILGI] {yol} artık yok, kontrol atlanıyor.")
            continue
        if not any(yol in h for h in hatalar):
            with dosya.open(encoding="utf-8") as f:
                gercek = sum(1 for _ in f)
            tavan = bilgi["tavan"] if isinstance(bilgi, dict) else bilgi
            print(f"[OK] {yol}: {gercek}/{tavan} satır.")

    if hatalar:
        for h in hatalar:
            print(f"::error::{h}")
        sys.exit(1)


if __name__ == "__main__":
    main()
