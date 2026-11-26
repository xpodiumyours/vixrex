"""Play Store mağaza varlıklarını mevcut Vixrex logosundan üretir.

Kullanım: python tool/play_store_varlik_uret.py
Ekran görüntüleri bu betikle üretilmez; gerçek uygulamadan alınır.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "android" / "store-assets"
LOGO = ROOT / "android" / "app" / "src" / "main" / "res" / "mipmap-xxxhdpi" / "ic_launcher.png"
FOREGROUND = (
    ROOT
    / "android"
    / "app"
    / "src"
    / "main"
    / "res"
    / "mipmap-xxxhdpi"
    / "ic_launcher_foreground.png"
)

BG = (5, 11, 26)      # #050B1A
BLUE = (20, 125, 255)  # #147DFF
WHITE = (247, 251, 255)


def font(size: int, bold: bool = True) -> ImageFont.FreeTypeFont:
    name = "segoeuib.ttf" if bold else "segoeui.ttf"
    return ImageFont.truetype(str(Path("C:/Windows/Fonts") / name), size)


def build_icon() -> None:
    src = Image.open(LOGO).convert("RGBA")
    icon = src.resize((512, 512), Image.Resampling.LANCZOS)
    icon.save(OUT / "icon-512x512.png", format="PNG", optimize=True)


def build_feature() -> None:
    img = Image.new("RGB", (1024, 500), BG)
    draw = ImageDraw.Draw(img)

    draw.rectangle((0, 0, 1024, 12), fill=BLUE)
    draw.rectangle((72, 386, 952, 390), fill=BLUE)

    mark = Image.open(FOREGROUND).convert("RGBA")
    mark.thumbnail((250, 250), Image.Resampling.LANCZOS)
    img.paste(
        mark,
        (1024 - mark.width - 70, (500 - mark.height) // 2 - 10),
        mark,
    )

    draw.text((72, 150), "Vixrex", font=font(104), fill=WHITE)
    draw.text(
        (76, 276),
        "Dijital vitrinini oluştur, link ve QR ile paylaş.",
        font=font(34, bold=False),
        fill=BLUE,
    )
    img.save(OUT / "feature-graphic-1024x500.png", format="PNG", optimize=True)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    build_icon()
    build_feature()
    print(f"uretlendi: {OUT}")


if __name__ == "__main__":
    main()
