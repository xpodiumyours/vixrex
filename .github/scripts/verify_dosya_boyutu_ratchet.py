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
  - JSON'da kayıtlı olmayan yeni `lib/controllers/` ve `lib/services/`
    dosyalarına otomatik 400 satır tavanı uygular.
  - Aşarsa kırmızı: ya kod tavanın altına indirilir (yeni bir servise
    taşınarak), ya da — gerçekten gerekiyorsa — aynı PR'da tavan
    YÜKSELTİLİR ve `not` alanına neden yazılır. Bu, sessiz büyümeyi değil,
    görünür/bilinçli büyümeyi zorunlu kılar (`verify_pr_scope.py`'deki
    `Kapsam-Onay:` ile aynı felsefe — burada onay, JSON diff'inin
    kendisinde görünür).
  - Dosya tavanın ALTINDAYSA hata vermez; tavanı otomatik indirmez de —
    küçülünce tavanı elle indirmek isteğe bağlı, ayrı bir temizlik adımı.

YENİ DOSYA İZLEMEK İÇİN
Yeni controller/service dosyaları JSON'a eklenmeden 400 satırda tutulur.
400 satırı bilinçli olarak aşması gerekiyorsa dosyayı JSON'a ekle ve nedeni
`not` alanında açıkla.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

RATCHET_DOSYASI = Path(__file__).resolve().parent.parent / "dosya_boyutu_ratchet.json"
VARSAYILAN_TAVAN = 400
OTOMATIK_KOKLER = ("lib/controllers/", "lib/services/")


def _satir_sayisi(dosya: Path) -> int:
    with dosya.open(encoding="utf-8") as f:
        return sum(1 for _ in f)


def kontrol_et(
    kayitlar: dict, kok: Path, yeni_dosyalar: list[str] | None = None
) -> list[str]:
    """Kayıtlı dosyaları ve yeni controller/service dosyalarını denetler.

    Döndürdüğü liste boşsa her şey tavanın altında demektir. Saf fonksiyon
    (I/O yalnız dosya okuma) — test edilebilir.
    """
    hatalar: list[str] = []
    for yol, bilgi in kayitlar.items():
        tavan = bilgi["tavan"] if isinstance(bilgi, dict) else bilgi
        dosya = kok / yol
        if not dosya.exists():
            continue

        gercek = _satir_sayisi(dosya)
        if gercek > tavan:
            hatalar.append(
                f"{yol} {gercek} satıra çıktı (tavan: {tavan}). Ya kodu "
                "tavanın altına indir (yeni bir servise taşı), ya da "
                "gerçekten gerekliyse .github/dosya_boyutu_ratchet.json'daki "
                "tavanı bu PR'da bilinçli olarak yükselt ve 'not' alanına "
                "nedenini yaz."
            )

    for ham_yol in yeni_dosyalar or []:
        yol = Path(ham_yol).as_posix().removeprefix("./")
        if yol in kayitlar or not yol.startswith(OTOMATIK_KOKLER):
            continue
        dosya = kok / yol
        if not dosya.is_file():
            continue

        gercek = _satir_sayisi(dosya)
        if gercek > VARSAYILAN_TAVAN:
            hatalar.append(
                f"{yol} yeni dosya olarak {gercek} satırla eklendi "
                f"(varsayılan tavan: {VARSAYILAN_TAVAN}). Dosyayı "
                "400 satırın altına indir veya bilinçli istisnayı "
                ".github/dosya_boyutu_ratchet.json'a notuyla ekle."
            )
    return hatalar


def yeni_dosyalari_bul(kok: Path, taban: str) -> list[str]:
    sonuc = subprocess.run(
        [
            "git",
            "diff",
            "--diff-filter=A",
            "--name-only",
            f"{taban}...HEAD",
            "--",
            "lib/controllers/",
            "lib/services/",
        ],
        cwd=kok,
        capture_output=True,
        text=True,
        check=False,
    )
    if sonuc.returncode != 0:
        raise RuntimeError(
            f"Yeni dosya listesi alınamadı ({taban}...HEAD): {sonuc.stderr.strip()}"
        )
    return [satir.strip() for satir in sonuc.stdout.splitlines() if satir.strip()]


def main() -> None:
    if not RATCHET_DOSYASI.exists():
        print(f"[BILGI] {RATCHET_DOSYASI} yok, kontrol atlanıyor.")
        return

    kayitlar = json.loads(RATCHET_DOSYASI.read_text(encoding="utf-8"))
    kok = RATCHET_DOSYASI.parent.parent  # repo kökü
    taban = os.environ.get("BASE_REF") or (
        f"origin/{os.environ['GITHUB_BASE_REF']}"
        if os.environ.get("GITHUB_BASE_REF")
        else "origin/main"
    )

    try:
        yeni_dosyalar = yeni_dosyalari_bul(kok, taban)
    except RuntimeError as hata:
        print(f"::error::{hata}")
        sys.exit(1)

    hatalar = kontrol_et(kayitlar, kok, yeni_dosyalar)
    for yol, bilgi in kayitlar.items():
        dosya = kok / yol
        if not dosya.exists():
            print(f"[BILGI] {yol} artık yok, kontrol atlanıyor.")
            continue
        if not any(yol in h for h in hatalar):
            gercek = _satir_sayisi(dosya)
            tavan = bilgi["tavan"] if isinstance(bilgi, dict) else bilgi
            print(f"[OK] {yol}: {gercek}/{tavan} satır.")

    if hatalar:
        for h in hatalar:
            print(f"::error::{h}")
        sys.exit(1)


if __name__ == "__main__":
    main()
