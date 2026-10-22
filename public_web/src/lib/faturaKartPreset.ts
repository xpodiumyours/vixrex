import type { GoruSatiri, GoruSonucu } from "@/lib/faturaGoru";

export const OKUMA_FATURA_PRESET = "@preset/vixrex-qwen-fatura-okuma-suzme";
export const KART_FATURA_PRESET = "@preset/vixrex-fatura-otomatik-kart";

const KART_JSON_ISTEGI = `
Aşağıdaki JSON, ilk aşamada faturadan güvenilir biçimde okunmuş ürün satırlarıdır. Her satır için Vixrex ürün kartı hazırlama araştırmasını yap. Yalnızca aşağıdaki JSON'daki satırları kullan; yeni fatura satırı ekleme ve satır sırasını değiştirme.

Cevabı yalnızca JSON olarak ve tam olarak şu şemayla döndür:
{
  "tedarikci": "...",
  "satirlar": [
    {
      "satir_no": 1,
      "ham_satir": "ilk JSON'dan aynen",
      "model": "ilk JSON'dan aynen",
      "ad": "resmi ürün adı",
      "barkod": "ilk JSON'dan aynen",
      "marka": "ilk JSON'dan aynen veya güvenilir kaynakta doğrulanan marka",
      "varyant": "ilk JSON'dan aynen",
      "beden": "ilk JSON'dan aynen",
      "adet": "ilk JSON'dan aynen",
      "birim": "ilk JSON'dan aynen",
      "birim_fiyat": "ilk JSON'dan aynen",
      "tutar": "ilk JSON'dan aynen",
      "okuma_guveni": "ilk JSON'dan aynen",
      "site_aciklama": "ürün kartı açıklaması",
      "site_gorseller": ["https://..."],
      "site_sayfa": "https://...",
      "kategori": "...",
      "uretici": "...",
      "gramaj": "...",
      "ozellikler": [],
      "dogrulama_durumu": "doğrulandı veya uygun eksik durum",
      "eslesen_bilgiler": [],
      "eksikler": [],
      "gorsel_dogrulama_durumu": "...",
      "kaynaklar": []
    }
  ]
}

Kritik kurallar: adet, birim_fiyat, tutar, model, barkod, varyant, beden ve ham_satir ilk JSON'dan aynen korunur. Bunlar ikinci aşamada tahmin edilmez ve değiştirilmez. Resmi kaynak bulunamazsa bunu açıkça belirt, sahte URL/görsel üretme ve satırı yine de döndür.
`.trim();

export function faturaKartIstekGovdesi(okuma: GoruSonucu): Record<string, unknown> {
  return {
    model: KART_FATURA_PRESET,
    stream: true,
    response_format: { type: "json_object" },
    provider: { require_parameters: true },
    messages: [{
      role: "user",
      content: `${KART_JSON_ISTEGI}\n\nFATURA_OKUMA_JSON:\n${JSON.stringify(okuma)}`,
    }],
  };
}

function metin(deger: unknown): string { return typeof deger === "string" ? deger : ""; }

/** İkinci preset katalog alanlarını doldurur; fatura alanları ilk presetten korunur. */
export function faturaKartSonucunuBirlestir(ilk: GoruSonucu, kart: GoruSonucu): GoruSonucu {
  if (kart.satirlar.length !== ilk.satirlar.length) throw new Error("FATURA_KART_SATIR_ESLESMEDI");
  return {
    ...ilk,
    uyarilar: [...new Set([...(ilk.uyarilar ?? []), ...(kart.uyarilar ?? [])])],
    gruplar: kart.gruplar?.length ? kart.gruplar : ilk.gruplar,
    satirlar: ilk.satirlar.map((faturaSatiri, index): GoruSatiri => {
      const kartSatiri = kart.satirlar[index];
      return {
        ...faturaSatiri,
        ad: metin(kartSatiri.ad) || faturaSatiri.ad,
        siteAciklama: kartSatiri.siteAciklama || faturaSatiri.siteAciklama,
        siteGorsel: kartSatiri.siteGorsel || faturaSatiri.siteGorsel,
        siteGorseller: kartSatiri.siteGorseller?.length ? kartSatiri.siteGorseller : faturaSatiri.siteGorseller,
        siteSayfa: kartSatiri.siteSayfa || faturaSatiri.siteSayfa,
        siteKategori: kartSatiri.siteKategori || faturaSatiri.siteKategori,
        uretici: kartSatiri.uretici || faturaSatiri.uretici,
        gramaj: kartSatiri.gramaj || faturaSatiri.gramaj,
        ozellikler: kartSatiri.ozellikler?.length ? kartSatiri.ozellikler : faturaSatiri.ozellikler,
        dogrulamaDurumu: kartSatiri.dogrulamaDurumu || faturaSatiri.dogrulamaDurumu,
        eslesenBilgiler: kartSatiri.eslesenBilgiler ?? faturaSatiri.eslesenBilgiler,
        eksikler: kartSatiri.eksikler?.length ? kartSatiri.eksikler : faturaSatiri.eksikler,
        gorselDogrulamaDurumu: kartSatiri.gorselDogrulamaDurumu || faturaSatiri.gorselDogrulamaDurumu,
        kaynaklar: kartSatiri.kaynaklar?.length ? kartSatiri.kaynaklar : faturaSatiri.kaynaklar,
      };
    }),
  };
}
