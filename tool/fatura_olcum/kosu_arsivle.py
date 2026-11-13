"""Kayıtlı fatura koşularını ölçüm biçimine çevirip arşivler.

Ölçüm aracı (tool/fatura_olcum.py) "gerçek" olarak products dizisi bekler; koşu
çıktıları ise kart biçiminde gelir (iç içe ya da düz). Bu betik ikisini tek
biçime indirir ve her koşuyu tool/fatura_olcum/kosular/ altına yazar.
"""

import argparse
import json
from pathlib import Path

KOK = Path(__file__).resolve().parent
ARSIV = KOK / "kosular"


def _metin(deger):
    return "" if deger is None else str(deger).strip()


def _sayi(deger):
    if isinstance(deger, bool) or deger is None:
        return None
    if isinstance(deger, (int, float)):
        return float(deger)
    metin = str(deger).strip().replace(" ", "")
    if not metin:
        return None
    if "," in metin and "." in metin:
        if metin.rfind(",") > metin.rfind("."):
            metin = metin.replace(".", "").replace(",", ".")
        else:
            metin = metin.replace(",", "")
    elif "," in metin:
        metin = metin.replace(",", ".")
    try:
        return float(metin)
    except ValueError:
        return None


def _ilk(*degerler):
    for deger in degerler:
        if deger is not None and deger != "":
            return deger
    return None


def _nesne(deger):
    return deger if isinstance(deger, dict) else {}


def json_govdesini_ayikla(ham):
    adaylar = [ham]
    bas, son = ham.find("{"), ham.rfind("}")
    if bas >= 0 and son > bas:
        adaylar.append(ham[bas:son + 1])
    for aday in adaylar:
        try:
            govde = json.loads(aday)
        except ValueError:
            continue
        if isinstance(govde, dict) and isinstance(govde.get("items"), list):
            return govde
    return None


def urune_cevir(item):
    ic = _nesne(item.get("vixrex_product_json"))
    kart = {**item, **ic}
    fatura = _nesne(item.get("invoice_data"))
    return {
        "model": _metin(_ilk(kart.get("code"), kart.get("model"))),
        "barcode": _metin(_ilk(item.get("barcode"), kart.get("barcode"))),
        "name": _metin(_ilk(kart.get("title"), kart.get("ad"))),
        "variant": _metin(_ilk(kart.get("variant"), kart.get("varyant"))),
        "size": _metin(_ilk(item.get("beden"), kart.get("size"), kart.get("beden"))),
        "qty": _sayi(_ilk(fatura.get("quantity"), fatura.get("qty"), kart.get("net_quantity"))),
        "buy": _sayi(_ilk(fatura.get("unit_price"), fatura.get("buy"))),
        "total": _sayi(_ilk(fatura.get("total_amount"), fatura.get("total"))),
    }


def kosuyu_oku(dosya):
    govde = json_govdesini_ayikla(Path(dosya).read_text(encoding="utf-8"))
    if not govde:
        raise SystemExit("AYRISTIRILAMADI: " + Path(dosya).name)
    urunler = [urune_cevir(item) for item in govde["items"] if isinstance(item, dict)]
    return {"invoice_id": Path(dosya).name.split("-")[0], "products": urunler}


def main():
    ayar = argparse.ArgumentParser()
    ayar.add_argument("dosyalar", nargs="+")
    ayar.add_argument("--cikti", default=str(ARSIV))
    secim = ayar.parse_args()
    hedef = Path(secim.cikti)
    hedef.mkdir(parents=True, exist_ok=True)
    for dosya in secim.dosyalar:
        kayit = kosuyu_oku(dosya)
        ad = Path(dosya).name.replace(".icerik", "").replace(".txt", "").replace(".json", "") + ".json"
        (hedef / ad).write_text(json.dumps(kayit, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"{ad}: {len(kayit['products'])} urun")


if __name__ == "__main__":
    main()
