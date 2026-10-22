import type { GoruSatiri } from "@/lib/faturaGoru";
import type { EslesmisFaturaSatiri, SatirSonucu } from "@/lib/faturaEslestir";

/** Etiket çevirisi; ikinci bir araştırma veya ürün doğrulama kararı değildir. */
export function presetDurumunuAktar(durum: string | undefined): SatirSonucu {
  const etiket = (durum ?? "").replace(/^[✓?✗⚠\s]+/, "").trim().toLocaleLowerCase("tr-TR");
  if (["doğrulandı", "dogrulandi", "doğrulanmış", "verified"].includes(etiket)) return "kanitli";
  if (["bulunamadı", "bulunamadi", "not_found"].includes(etiket)) return "iz-yok";
  return "eksik";
}

export function faturaSatiriniAktar(satir: GoruSatiri, tedarikci: string): EslesmisFaturaSatiri {
  const gorseller = satir.siteGorseller ?? [];
  const eksikler = [...(satir.eksikler ?? [])];
  if (!satir.dogrulamaDurumu) eksikler.push("OpenRouter doğrulama durumu bildirmedi.");
  if (satir.okumaGuveni === null) eksikler.push("OpenRouter okuma güveni bildirmedi.");
  const ekler = {
    satirNo: satir.satirNo, uretici: satir.uretici, gramaj: satir.gramaj,
    dogrulamaDurumu: satir.dogrulamaDurumu, eslesenBilgiler: satir.eslesenBilgiler,
    eksikler, gorselDogrulamaDurumu: satir.gorselDogrulamaDurumu, kaynaklar: satir.kaynaklar,
  };
  return {
    ...ekler,
    hamSatir: satir.hamSatir, model: satir.model, ad: satir.ad || satir.model,
    barkod: satir.barkod, varyant: satir.varyant, beden: satir.beden, marka: satir.marka,
    adet: satir.adet, birim: satir.birim, alisBirimFiyat: satir.birimFiyat, satirToplam: satir.tutar,
    // Eski Vixrex değerlendirme arayüzü sayısal güven ister; bilinmeyen, tam güvene çevrilmez.
    guven: satir.okumaGuveni ?? 0,
    siteAd: satir.ad || satir.model, siteAciklama: satir.siteAciklama,
    siteGorsel: gorseller[0] ?? "", siteGorseller: gorseller, siteSayfa: satir.siteSayfa,
    siteKategori: satir.siteKategori, siteOzellikler: satir.ozellikler,
    sonuc: presetDurumunuAktar(satir.dogrulamaDurumu),
    uyari: eksikler.length ? eksikler.join(" · ") : undefined,
    katalog: {
      ...ekler, firma: tedarikci, kaynakFirma: satir.uretici || satir.marka || tedarikci,
      // Kod/barkodun mevcut olması onların resmî kaynakla doğrulandığı anlamına gelmez.
      dayanak: "ad", izinDurumu: "yok", resmiAd: satir.ad || satir.model, marka: satir.marka,
      aciklama: satir.siteAciklama ?? "", gorseller, gorselAdaylari: gorseller,
      kaynak: satir.siteSayfa ?? "", kategori: satir.siteKategori, ozellikler: satir.ozellikler,
      beden: satir.beden, varyant: satir.varyant,
    },
  };
}
