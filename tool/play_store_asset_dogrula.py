"""Play Store varlıklarının boyut, kanal ve boyut-kilo sözleşmesini doğrular.

Kullanım: python tool/play_store_asset_dogrula.py
PNG IHDR: genişlik(4), yükseklik(4), bit derinliği(1), renk tipi(1).
Renk tipi 6 = RGBA (alpha), 2 = RGB (alfa yok).
"""

import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "android" / "store-assets"

KURALLAR = {
    "icon-512x512.png": {"size": (512, 512), "bit": 8, "color": 6, "max_kb": 1024},
    "feature-graphic-1024x500.png": {"size": (1024, 500), "bit": 8, "color": 2},
}


def png_header(path: Path) -> tuple[int, int, int, int]:
    with path.open("rb") as fh:
        baslik = fh.read(26)
    if baslik[:8] != b"\x89PNG\r\n\x1a\n" or baslik[12:16] != b"IHDR":
        raise ValueError("PNG/IHDR değil")
    genislik, yukseklik, bit, renk = struct.unpack(">IIBB", baslik[16:26])
    return genislik, yukseklik, bit, renk


def kontrol(path: Path, kural: dict) -> list[str]:
    hatalar: list[str] = []
    if not path.exists():
        return [f"eksik: {path.name}"]
    try:
        genislik, yukseklik, bit, renk = png_header(path)
    except (ValueError, OSError) as exc:
        return [f"okunamadi: {path.name} ({exc})"]
    if (genislik, yukseklik) != kural["size"]:
        hatalar.append(f"{path.name}: boyut {genislik}x{yukseklik}, beklenen {kural['size']}")
    if bit != kural["bit"]:
        hatalar.append(f"{path.name}: bit {bit}, beklenen {kural['bit']}")
    if renk != kural["color"]:
        hatalar.append(
            f"{path.name}: renk tipi {renk}, beklenen {kural['color']}"
        )
    if "max_kb" in kural and path.stat().st_size > kural["max_kb"] * 1024:
        hatalar.append(f"{path.name}: {path.stat().st_size} bayt, limit {kural['max_kb']} KB")
    return hatalar


def main() -> int:
    hatalar: list[str] = []
    for ad, kural in KURALLAR.items():
        hatalar.extend(kontrol(OUT / ad, kural))

    ekranlar = sorted(OUT.glob("screenshot-*.png"))
    if len(ekranlar) < 4:
        hatalar.append(f"ekran görüntüsü {len(ekranlar)} adet, en az 4 gerekli")
    for path in ekranlar:
        hatalar.extend(
            kontrol(
                path,
                {"size": (1080, 1920), "bit": 8, "color": 2},
            )
        )

    if hatalar:
        for hata in hatalar:
            print("HATA:", hata)
        print("SONUÇ: varlıklar Play Console koşullarını karşılamıyor")
        return 1
    print(f"TAMAM: {len(KURALLAR)} temel varlık + {len(ekranlar)} ekran görüntüsü")
    return 0


if __name__ == "__main__":
    sys.exit(main())
