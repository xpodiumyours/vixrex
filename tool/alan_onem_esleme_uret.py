#!/usr/bin/env python3
"""46 vitrin alanı x 19 esnaf kategorisi önem eşleştirmesini üretir.

Bu script CI'ın schema-drift kontrolüne dahil DEĞİL — shared/*.json'daki
gibi Flutter/Next.js'in okuduğu bir üretim şeması üretmiyor, yalnız
docs/alan-onem-eslemesi.md ve docs/alan-onem-eslemesi.json'u üretiyor.
Kural seti (KATEGORILER, hesapla()) burada elle tutulur; dokümanları
değiştirmek isteyen biri önce burayı değiştirir, sonra bu script'i
tekrar çalıştırır — dokümanlar elle düzenlenmez.

Yöntem: docs/esnaf-bilgi-tabani.md'de anlatılan 8 iş-modeli özniteliği
(A..H) her kategori için tanımlanır; her alanın önemi bu özniteliklerden
kural ile hesaplanır (bkz. hesapla()). Rastgele/elle 46x19=874 hücre
doldurmak yerine, "neden bu alan bu kategoride önemli" sorusunun her
zaman tek bir izlenebilir kurala bağlı olması hedeflendi.

Kullanım:
    python3 tool/alan_onem_esleme_uret.py
"""
import json
import pathlib

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
DOCS_DIR = REPO_ROOT / "docs"

# ── 19 kanonik kategori + "diger" — iş modeli öznitelikleri ─────────────────
# grup: shared/business_categories.json'daki gerçek templateGroup.
# A_ziyaret:   evet | kismen | hayir   — müşteri işletmenin fiziksel adresine mi geliyor
# B_randevu:   yuksek | orta | dusuk   — çalışma saati/randevu kaçırmanın maliyeti
# C_sunum:     urun | menu | hizmet | ders | karma — otomatikVitrinIcerik.ts'teki
#              urunBolumBaslik metinleriyle birebir (Ürünlerimiz/Menümüz/Hizmetlerimiz/Derslerimiz)
# D_guven:     yuksek | orta | dusuk   — "kime emanet ediyorum" kararının ağırlığı
# E_gorsel:    yuksek | orta | dusuk   — önce/sonra veya ürün-görünüm kanıtının satış gücü
# F_kampanya:  yuksek | orta | dusuk   — fiyat/indirim bandının işe yarama olasılığı
# G_sosyal:    yuksek | orta | dusuk   — Instagram/sosyal kanıt kültürünün gücü
# H_icerik:    yuksek | orta | dusuk   — blog/SSS'in uzmanlık kanıtı olarak değeri
KATEGORILER = {
    "giyim":               dict(grup="perakende", A="evet",   B="orta",   C="urun",   D="orta",   E="yuksek", F="yuksek", G="yuksek", H="dusuk"),
    "butik":                dict(grup="perakende", A="evet",   B="orta",   C="urun",   D="orta",   E="yuksek", F="yuksek", G="yuksek", H="dusuk"),
    "gida":                 dict(grup="gida",       A="evet",   B="yuksek", C="urun",   D="orta",   E="orta",   F="yuksek", G="orta",   H="dusuk"),
    "firin":                dict(grup="gida",       A="evet",   B="yuksek", C="urun",   D="orta",   E="orta",   F="yuksek", G="orta",   H="dusuk"),
    "kozmetik":             dict(grup="perakende", A="evet",   B="orta",   C="urun",   D="orta",   E="yuksek", F="yuksek", G="yuksek", H="orta"),
    "dekorasyon":           dict(grup="perakende", A="evet",   B="orta",   C="urun",   D="orta",   E="yuksek", F="orta",   G="yuksek", H="orta"),
    "elektronik":           dict(grup="perakende", A="evet",   B="orta",   C="urun",   D="orta",   E="dusuk",  F="yuksek", G="dusuk",  H="orta"),
    "kirtasiye":            dict(grup="perakende", A="evet",   B="orta",   C="urun",   D="dusuk",  E="dusuk",  F="orta",   G="dusuk",  H="dusuk"),
    "kafe_lokanta":         dict(grup="gida",       A="evet",   B="yuksek", C="menu",   D="orta",   E="yuksek", F="yuksek", G="yuksek", H="orta"),
    "kuafor":               dict(grup="hizmet",     A="evet",   B="yuksek", C="hizmet", D="yuksek", E="yuksek", F="orta",   G="yuksek", H="dusuk"),
    "teknik_servis":        dict(grup="hizmet",     A="evet",   B="yuksek", C="hizmet", D="yuksek", E="orta",   F="orta",   G="dusuk",  H="orta"),
    "hizmet_danismanlik":   dict(grup="hizmet",     A="kismen", B="orta",   C="hizmet", D="yuksek", E="dusuk",  F="dusuk",  G="dusuk",  H="yuksek"),
    "egitim_ders":          dict(grup="hizmet",     A="kismen", B="orta",   C="ders",   D="yuksek", E="dusuk",  F="orta",   G="orta",   H="yuksek"),
    "ev_temizlik":          dict(grup="hizmet",     A="hayir",  B="yuksek", C="hizmet", D="yuksek", E="yuksek", F="orta",   G="dusuk",  H="dusuk"),
    "spor_fitness":         dict(grup="hizmet",     A="evet",   B="yuksek", C="hizmet", D="orta",   E="orta",   F="yuksek", G="yuksek", H="orta"),
    "pet_shop_veteriner":   dict(grup="perakende", A="evet",   B="yuksek", C="karma",  D="yuksek", E="orta",   F="orta",   G="orta",   H="orta"),
    "saglik_yasam":         dict(grup="hizmet",     A="evet",   B="yuksek", C="hizmet", D="yuksek", E="dusuk",  F="dusuk",  G="dusuk",  H="yuksek"),
    "oto_arac":             dict(grup="hizmet",     A="evet",   B="yuksek", C="hizmet", D="yuksek", E="yuksek", F="orta",   G="dusuk",  H="orta"),
    "diger":                dict(grup="diger",      A="kismen", B="orta",   C="hizmet", D="orta",   E="orta",   F="orta",   G="orta",   H="orta"),
}

LABELS = {
    "giyim": "Giyim", "butik": "Butik", "gida": "Gıda", "firin": "Fırın",
    "kozmetik": "Kozmetik", "dekorasyon": "Dekorasyon", "elektronik": "Elektronik",
    "kirtasiye": "Kırtasiye", "kafe_lokanta": "Kafe / Lokanta", "kuafor": "Kuaför",
    "teknik_servis": "Teknik Servis", "hizmet_danismanlik": "Danışmanlık",
    "egitim_ders": "Eğitim", "ev_temizlik": "Ev Temizlik", "spor_fitness": "Spor / Fitness",
    "pet_shop_veteriner": "Pet / Veteriner", "saglik_yasam": "Sağlık / Yaşam",
    "oto_arac": "Oto / Araç", "diger": "Diğer",
}

# ── 46 alan: anahtar, etiket, bölüm — public_web/src/lib/vitrinFieldSchema.ts ile birebir ─
FIELDS = [
    ("isletmeAdi", "İşletme Adı", "hero"),
    ("heroRozet", "Hero Rozet Metni", "hero"),
    ("kisaTanitim", "Kısa Tanıtım", "hero"),
    ("konumMetni", "Hero Konum Metni", "hero"),
    ("kategori", "İşletme Kategorisi", "hero"),
    ("isletmeTuru", "İşletme Türü", "hero"),
    ("logo", "Logo", "hero"),
    ("kapakGorseli", "Kapak / Hero Görseli", "hero"),
    ("whatsapp", "WhatsApp Numarası", "contact"),
    ("telefon", "Telefon", "contact"),
    ("eposta", "E-posta", "contact"),
    ("adres", "Açık Adres", "contact"),
    ("il", "İl", "contact"),
    ("ilce", "İlçe", "contact"),
    ("mahalle", "Mahalle", "contact"),
    ("haritaEtiketi", "Harita Kartı Etiketi", "contact"),
    ("calismaSaatleri", "Çalışma Saatleri", "contact"),
    ("instagram", "Instagram Kullanıcı Adı", "contact"),
    ("website", "Web Sitesi", "contact"),
    ("haritaLinki", "Google İşletme / Harita Bağlantısı", "contact"),
    ("enlem", "Konum — Enlem", "contact"),
    ("boylam", "Konum — Boylam", "contact"),
    ("yolTarifiGoster", "Yol Tarifi Butonunu Göster", "contact"),
    ("kategoriBolumBaslik", "Kategori Bölümü Başlığı", "categories"),
    ("urunBolumBaslik", "Ürün Bölümü Başlığı", "products"),
    ("bantEtiket", "Kampanya Etiketi", "featured"),
    ("bantBaslik", "Kampanya Başlığı", "featured"),
    ("bantAciklama", "Kampanya Açıklaması", "featured"),
    ("bantGorsel", "Kampanya Görseli", "featured"),
    ("bantFiyat", "Kampanya Fiyat Metni", "featured"),
    ("hakkindaUstBaslik", "Hakkımızda Üst Başlık", "about"),
    ("hakkindaBaslik", "Hakkımızda Başlığı", "about"),
    ("hakkindaMetin", "Hakkımızda Yazısı", "about"),
    ("hakkindaGorsel", "Hakkımızda Görseli", "about"),
    ("hakkindaGorselAlt", "Görsel Alt Yazısı", "about"),
    ("referansLinki", "Referanslar Bağlantısı", "about"),
    ("galeriUstBaslik", "Galeri Üst Başlık", "gallery"),
    ("galeriBaslik", "Galeri Başlığı", "gallery"),
    ("galeriAksiyonMetni", "Galeri Buton Metni", "gallery"),
    ("galeriAksiyonLinki", "Galeri Buton Bağlantısı", "gallery"),
    ("blogUstBaslik", "Blog Üst Başlık", "blog"),
    ("blogBaslik", "Blog Bölüm Başlığı", "blog"),
    ("sssUstBaslik", "SSS Üst Başlık", "faq"),
    ("sssBaslik", "SSS Bölüm Başlığı", "faq"),
    ("sssAciklama", "SSS Bölüm Açıklaması", "faq"),
    ("puanGoster", "Değerlendirme Puanını Göster", "hero"),
]
assert len(FIELDS) == 46, f"46 alan bekleniyordu, {len(FIELDS)} bulundu"

TEMEL, DEGERLI, DURUMA, ILGISIZ = "temel", "degerli", "duruma-bagli", "ilgisiz"
TIER_LABEL = {TEMEL: "Temel", DEGERLI: "Değerli", DURUMA: "Duruma bağlı", ILGISIZ: "İlgisiz"}
TIER_ORDER = [TEMEL, DEGERLI, DURUMA, ILGISIZ]


def hesapla(anahtar: str, k: dict) -> str:
    """Bir alanın bir kategori için önemini, o kategorinin 8 özniteliğinden hesaplar."""
    A, B, C, D, E, F, G, H = k["A"], k["B"], k["C"], k["D"], k["E"], k["F"], k["G"], k["H"]

    if anahtar in ("isletmeAdi", "kategori", "whatsapp"):
        return TEMEL  # platform genelinde zaten zorunlu — kategoriden bağımsız
    if anahtar == "heroRozet":
        return DURUMA if C == "diger" else DEGERLI
    if anahtar == "kisaTanitim":
        return TEMEL if C in ("hizmet", "ders", "karma") else DEGERLI
    if anahtar == "konumMetni":
        return {"evet": DEGERLI, "kismen": DURUMA, "hayir": ILGISIZ}[A]
    if anahtar == "isletmeTuru":
        return DEGERLI
    if anahtar == "logo":
        return DEGERLI
    if anahtar == "kapakGorseli":
        return TEMEL if E == "yuksek" else DEGERLI
    if anahtar == "telefon":
        return DEGERLI if B == "yuksek" else DURUMA
    if anahtar == "eposta":
        return DURUMA if C in ("hizmet", "ders", "karma") else ILGISIZ
    if anahtar == "adres":
        return TEMEL if A == "evet" else DURUMA
    if anahtar in ("il", "ilce"):
        return TEMEL if A == "evet" else DEGERLI
    if anahtar == "mahalle":
        return DEGERLI if A == "evet" else DURUMA
    if anahtar == "haritaEtiketi":
        return DEGERLI if A == "evet" else ILGISIZ
    if anahtar == "calismaSaatleri":
        return {"yuksek": TEMEL, "orta": DEGERLI, "dusuk": DURUMA}[B]
    if anahtar == "instagram":
        return DEGERLI if G == "yuksek" else DURUMA
    if anahtar == "website":
        return DEGERLI if C in ("hizmet", "ders") else DURUMA
    if anahtar in ("haritaLinki", "enlem", "boylam", "yolTarifiGoster"):
        return DEGERLI if A == "evet" else ILGISIZ
    if anahtar == "kategoriBolumBaslik":
        return DEGERLI if C in ("urun", "menu", "karma") else DURUMA
    if anahtar == "urunBolumBaslik":
        return TEMEL if C in ("urun", "menu") else DEGERLI
    if anahtar in ("bantEtiket", "bantBaslik", "bantAciklama", "bantGorsel", "bantFiyat"):
        return {"yuksek": DEGERLI, "orta": DURUMA, "dusuk": ILGISIZ}[F]
    if anahtar == "hakkindaUstBaslik":
        return DURUMA if D in ("yuksek", "orta") else ILGISIZ
    if anahtar == "hakkindaBaslik":
        return DEGERLI if D == "yuksek" else DURUMA
    if anahtar == "hakkindaMetin":
        return {"yuksek": TEMEL, "orta": DEGERLI, "dusuk": DURUMA}[D]
    if anahtar == "hakkindaGorsel":
        return DEGERLI if D == "yuksek" else DURUMA
    if anahtar == "hakkindaGorselAlt":
        return DURUMA
    if anahtar == "referansLinki":
        if D == "yuksek" and C in ("hizmet", "ders", "karma"):
            return DEGERLI
        return ILGISIZ if C in ("urun", "menu") else DURUMA
    if anahtar in ("galeriUstBaslik", "galeriBaslik", "galeriAksiyonMetni", "galeriAksiyonLinki"):
        return {"yuksek": DEGERLI, "orta": DURUMA, "dusuk": ILGISIZ}[E]
    if anahtar in ("blogUstBaslik", "blogBaslik"):
        return {"yuksek": DEGERLI, "orta": DURUMA, "dusuk": ILGISIZ}[H]
    if anahtar in ("sssUstBaslik", "sssBaslik", "sssAciklama"):
        return DEGERLI if (C in ("hizmet", "ders", "karma") or D == "yuksek") else DURUMA
    if anahtar == "puanGoster":
        return DEGERLI if (D == "yuksek" or B == "yuksek") else DURUMA

    raise ValueError(f"'{anahtar}' için kural tanımlı değil")


def uret_grid() -> dict:
    return {
        kat_id: {anahtar: hesapla(anahtar, k) for anahtar, _etiket, _bolum in FIELDS}
        for kat_id, k in KATEGORILER.items()
    }


def yaz_json(grid: dict, hedef: pathlib.Path) -> None:
    veri = {
        "_uretim": "tool/alan_onem_esleme_uret.py — ELLE DÜZENLEME (script'i çalıştır)",
        "_yontem": "docs/esnaf-bilgi-tabani.md — her kategori 8 iş-modeli özniteliğiyle (A..H) tanımlanır, "
                   "her alanın önemi docs/alan-onem-eslemesi.md'deki kurallarla bu özniteliklerden hesaplanır",
        "onem_siniflari": TIER_ORDER,
        "kategoriler": {
            kat_id: {
                "etiket": LABELS[kat_id],
                "grup": k["grup"],
                "oznitelikler": {kk: vv for kk, vv in k.items() if kk != "grup"},
            }
            for kat_id, k in KATEGORILER.items()
        },
        "alanlar": grid,
    }
    hedef.write_text(json.dumps(veri, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def kategori_blogu(kat_id: str, grid: dict) -> str:
    k = KATEGORILER[kat_id]
    satirlar = [
        f"### {LABELS[kat_id]}\n",
        f"*İş modeli: {k['grup']} · fiziksel ziyaret: {k['A']} · randevu kritikliği: {k['B']} · "
        f"sunum: {k['C']} · güven ağırlığı: {k['D']} · görsel kanıt: {k['E']} · "
        f"kampanya: {k['F']} · sosyal medya: {k['G']} · içerik/SEO: {k['H']}*\n",
    ]
    by_tier: dict[str, list[str]] = {t: [] for t in TIER_ORDER}
    for anahtar, etiket, _bolum in FIELDS:
        by_tier[grid[kat_id][anahtar]].append(etiket)
    for t in TIER_ORDER:
        if by_tier[t]:
            satirlar.append(f"- **{TIER_LABEL[t]}:** " + ", ".join(by_tier[t]))
    return "\n".join(satirlar)


def yaz_markdown(grid: dict, hedef: pathlib.Path) -> None:
    on_soz = """# Alan × İşletme Türü Önem Eşleştirmesi

> **BU DOSYA ELLE DÜZENLENMEZ.** `tool/alan_onem_esleme_uret.py` tarafından
> üretilir — kuralı değiştirmek için önce o script'i güncelle, sonra tekrar
> çalıştır (`python3 tool/alan_onem_esleme_uret.py`). Makine tarafı:
> `docs/alan-onem-eslemesi.json`.

Esnaf danışma isteğinde tarif edilen dört adımlı planın **üçüncü adımı**:
`docs/vitrin-alan-semasi.md` (46 alan Vixrex'te ne işe yarar) ile
`docs/esnaf-bilgi-tabani.md` (19 kategorinin iş-modeli öznitelikleri)
birleşiyor — her kategori için 46 alanın hangisi **temel**, hangisi
**değerli**, hangisi **duruma bağlı**, hangisi **ilgisiz**.

## Önem sınıfları — bu doküman özelinde

Bunlar `docs/vitrin-alan-semasi.md`'deki platform-geneli `zorunlu`/`kalite`/
`isteğe bağlı` sınıflandırmasıyla **aynı şey değil**. O sınıflandırma
"vitrin yayına hazır mı" sorusuna cevap verir ve kategoriden bağımsızdır.
Buradaki dört sınıf "bu işletme türü için bu alanın dolu olması ne kadar
değer yaratır" sorusuna cevap verir ve kategoriye göre değişir — ikisi
kasıtlı olarak ayrışabilir. Örnek: `adres` platformda her zaman zorunludur
(yayın kapısı), ama tamamen uzaktan çalışan bir danışmanlık için işletme
türü açısından yalnız "duruma bağlı" — esnaf doldurur çünkü platform
istiyor, ama dolmaması müşteri deneyimini bozmaz.

| Sınıf | Anlamı |
|---|---|
| **Temel** | Bu işletme türünde boşsa müşteri deneyimi doğrudan bozulur veya vitrin eksik/yanıltıcı görünür. |
| **Değerli** | Boşsa vitrin çalışır ama bu işletme türü için somut bir fırsat kaçar (güven, SEO, dönüşüm). |
| **Duruma bağlı** | İşletmenin kendi tercihine kalmış — bazı işletmeler için işe yarar, bazıları için nötr. |
| **İlgisiz** | Bu işletme türünün iş modeliyle örtüşmüyor; boş kalması beklenir. |

## Yöntem

`docs/esnaf-bilgi-tabani.md`'deki 8 öznitelikten (A fiziksel ziyaret,
B randevu kritikliği, C sunum türü, D güven ağırlığı, E görsel kanıt,
F kampanya eğilimi, G sosyal medya, H içerik/SEO) her alan için bir kural
üretir — 46 alanın 46'sı da `tool/alan_onem_esleme_uret.py` içindeki
`hesapla()` fonksiyonunda tek tek tanımlı. Kural örnekleri:

- `çalışma saatleri` → B'ye bağlı: B=yüksek olan kategoride (kuaför, teknik
  servis, oto/araç, ev temizlik, spor/fitness, sağlık/yaşam, gıda, fırın,
  kafe/lokanta, pet/veteriner) **temel**; B=orta olanlarda (perakende grubu,
  danışmanlık, eğitim) **değerli**.
- `hakkında yazısı` → D'ye bağlı: D=yüksek olan (çoğu hizmet kategorisi)
  **temel**; D=orta (perakende/gıda/spor) **değerli**; D=düşük (kırtasiye)
  **duruma bağlı**.
- `adres`/`harita*`/`enlem`/`boylam`/`yol tarifi` → A'ya bağlı: A=hayır
  (yalnız Ev Temizlik) olduğunda konum alanlarının çoğu **ilgisiz**'e düşer.
- `kampanya bandı` (5 alan) → F'ye bağlı: F=düşük olan Danışmanlık ve
  Sağlık/Yaşam'da **ilgisiz**; perakende/gıda grubunda F=yüksek olduğu için
  **değerli**.

Bu bir **ilk-geçiş sezgisel model** — planın dördüncü adımı (gerçek Vixrex
kullanım verisiyle doğrulama) henüz yapılmadı. Kurallar yanlışsa,
`tool/alan_onem_esleme_uret.py`'deki `hesapla()` veya `docs/esnaf-bilgi-tabani.md`'deki
öznitelik tablosu düzeltilir, script tekrar çalıştırılır — bu dosya elle
yamanmaz.

## 19 kategori + Diğer

"""
    with open(hedef, "w", encoding="utf-8") as f:
        f.write(on_soz)
        for kat_id in KATEGORILER:
            f.write(kategori_blogu(kat_id, grid) + "\n\n")


def main() -> None:
    grid = uret_grid()
    yaz_json(grid, DOCS_DIR / "alan-onem-eslemesi.json")
    yaz_markdown(grid, DOCS_DIR / "alan-onem-eslemesi.md")
    print(f"Üretildi: {len(FIELDS)} alan x {len(KATEGORILER)} kategori")


if __name__ == "__main__":
    main()
