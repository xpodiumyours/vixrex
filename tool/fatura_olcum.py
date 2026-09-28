import argparse
import json
import math
import re
import unicodedata
from pathlib import Path

ALANLAR = (
    "model",
    "barcode",
    "name",
    "variant",
    "size",
    "qty",
    "buy",
    "total",
)


def _metin(value):
    if value is None:
        return ""
    text = str(value).strip().casefold()
    text = unicodedata.normalize("NFKC", text)
    text = re.sub(r"\s+", " ", text)
    return text


def _sayi(value):
    if value is None or value == "":
        return None
    if isinstance(value, (int, float)):
        return float(value)
    text = str(value).strip().replace(" ", "")
    if "," in text and "." in text:
        if text.rfind(",") > text.rfind("."):
            text = text.replace(".", "").replace(",", ".")
        else:
            text = text.replace(",", "")
    elif "," in text:
        text = text.replace(",", ".")
    try:
        return float(text)
    except ValueError:
        return None


def _alan_esit(alan, beklenen, gercek):
    if alan in {"qty", "buy", "total"}:
        b = _sayi(beklenen)
        g = _sayi(gercek)
        if b is None or g is None:
            return b is None and g is None
        return math.isclose(b, g, rel_tol=0.0, abs_tol=0.01)
    return _metin(beklenen) == _metin(gercek)


def _anahtarlar(urun):
    keys = []
    barcode = _metin(urun.get("barcode"))
    model = _metin(urun.get("model"))
    size = _metin(urun.get("size"))
    variant = _metin(urun.get("variant"))
    name = _metin(urun.get("name"))
    if barcode:
        keys.append(("barcode", barcode))
    if model and size and variant:
        keys.append(("model_size_variant", model, size, variant))
    if model and size:
        keys.append(("model_size", model, size))
    if model:
        keys.append(("model", model))
    if name and size and variant:
        keys.append(("name_size_variant", name, size, variant))
    if name:
        keys.append(("name", name))
    return keys


def _eslestir(beklenenler, gercekler):
    kullanilan = set()
    eslesmeler = []
    for beklenen in beklenenler:
        secilen = None
        secilen_yontem = None
        for key in _anahtarlar(beklenen):
            adaylar = []
            for index, gercek in enumerate(gercekler):
                if index in kullanilan:
                    continue
                if key in _anahtarlar(gercek):
                    adaylar.append(index)
            if len(adaylar) == 1:
                secilen = adaylar[0]
                secilen_yontem = key[0]
                break
        if secilen is None:
            eslesmeler.append((beklenen, None, None))
        else:
            kullanilan.add(secilen)
            eslesmeler.append((beklenen, gercekler[secilen], secilen_yontem))
    fazlalar = [g for i, g in enumerate(gercekler) if i not in kullanilan]
    return eslesmeler, fazlalar


def olc(beklenen, gercek):
    beklenen_urunler = list(beklenen.get("products", []))
    gercek_urunler = list(gercek.get("products", []))
    eslesmeler, fazlalar = _eslestir(beklenen_urunler, gercek_urunler)
    alan_sonuclari = {
        alan: {"dogru": 0, "toplam": len(beklenen_urunler)} for alan in ALANLAR
    }
    satirlar = []
    for beklenen_urun, gercek_urun, yontem in eslesmeler:
        alanlar = {}
        if gercek_urun is None:
            for alan in ALANLAR:
                alanlar[alan] = False
        else:
            for alan in ALANLAR:
                dogru = _alan_esit(
                    alan, beklenen_urun.get(alan), gercek_urun.get(alan)
                )
                alanlar[alan] = dogru
                if dogru:
                    alan_sonuclari[alan]["dogru"] += 1
        satirlar.append(
            {
                "expected": beklenen_urun,
                "actual": gercek_urun,
                "match_method": yontem,
                "fields": alanlar,
            }
        )

    beklenen_adet = sum((_sayi(p.get("qty")) or 0) for p in beklenen_urunler)
    gercek_adet = sum((_sayi(p.get("qty")) or 0) for p in gercek_urunler)
    beklenen_tutar = sum((_sayi(p.get("total")) or 0) for p in beklenen_urunler)
    gercek_tutar = 0.0
    for p in gercek_urunler:
        total = _sayi(p.get("total"))
        if total is None:
            qty = _sayi(p.get("qty")) or 0
            buy = _sayi(p.get("buy")) or 0
            total = qty * buy
        gercek_tutar += total

    eslesen = sum(1 for _, gercek_urun, _ in eslesmeler if gercek_urun is not None)
    toplam_kontrol = len(beklenen_urunler) * len(ALANLAR)
    dogru_kontrol = sum(x["dogru"] for x in alan_sonuclari.values())
    skor = (
        100.0
        if toplam_kontrol == 0
        else (dogru_kontrol / toplam_kontrol) * 100.0
    )

    for sonuc in alan_sonuclari.values():
        sonuc["oran"] = (
            100.0
            if sonuc["toplam"] == 0
            else (sonuc["dogru"] / sonuc["toplam"]) * 100.0
        )

    return {
        "invoice_id": beklenen.get("invoice_id"),
        "expected_product_count": len(beklenen_urunler),
        "actual_product_count": len(gercek_urunler),
        "matched_product_count": eslesen,
        "missing_product_count": len(beklenen_urunler) - eslesen,
        "extra_product_count": len(fazlalar),
        "expected_quantity": beklenen_adet,
        "actual_quantity": gercek_adet,
        "expected_total": round(beklenen_tutar, 2),
        "actual_total": round(gercek_tutar, 2),
        "fields": alan_sonuclari,
        "overall_score": round(skor, 2),
        "rows": satirlar,
        "extra_products": fazlalar,
    }


def _tr_para(value):
    text = f"{value:,.2f}"
    return text.replace(",", "X").replace(".", ",").replace("X", ".")


def insan_raporu(sonuc):
    lines = [
        "FATURA ÖLÇÜM RAPORU",
        f"Ürün satırı: {sonuc['matched_product_count']}/{sonuc['expected_product_count']} eşleşti",
        f"Eksik ürün: {sonuc['missing_product_count']} | Fazla ürün: {sonuc['extra_product_count']}",
        f"Toplam adet: {int(sonuc['actual_quantity'])}/{int(sonuc['expected_quantity'])}",
        f"Toplam tutar: {_tr_para(sonuc['actual_total'])}/{_tr_para(sonuc['expected_total'])} TL",
    ]
    etiketler = {
        "model": "Model",
        "barcode": "Barkod",
        "name": "Ürün adı",
        "variant": "Renk/Varyant",
        "size": "Beden",
        "qty": "Adet",
        "buy": "Birim alış fiyatı",
        "total": "Satır toplamı",
    }
    for alan in ALANLAR:
        d = sonuc["fields"][alan]
        lines.append(f"{etiketler[alan]}: {d['dogru']}/{d['toplam']} doğru")
    lines.append(f"Genel alan doğruluğu: %{sonuc['overall_score']:.2f}")
    return "\n".join(lines)


def _oku(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--beklenen", required=True)
    parser.add_argument("--gercek", required=True)
    parser.add_argument("--json-rapor")
    args = parser.parse_args()
    sonuc = olc(_oku(args.beklenen), _oku(args.gercek))
    print(insan_raporu(sonuc))
    if args.json_rapor:
        Path(args.json_rapor).write_text(
            json.dumps(sonuc, ensure_ascii=False, indent=2), encoding="utf-8"
        )


if __name__ == "__main__":
    main()
