import type { GoruSatiri } from "@/lib/faturaGoru";
import type { EslesmisFaturaSatiri, SatirSonucu } from "@/lib/faturaEslestir";
import { faturaKatalogMetadatasi } from "@/lib/faturaUrunIcerigi";

export function presetDurumunuAktar(durum: string | undefined): SatirSonucu {
  const etiket = (durum ?? "").replace(/^[✓?✗⚠\s]+/, "").trim().toLocaleLowerCase("tr-TR");
  if (["doğrulandı", "dogrulandi", "doğrulanmış", "verified"].includes(etiket)) return "kanitli";
  if (["bulunamadı", "bulunamadi", "not_found"].includes(etiket)) return "iz-yok";
  return "eksik";
}

export function resmiUrunBasliginiTemizle(ad: string | undefined, model?: string): string {
  const ham = (ad ?? "").trim();
  if (!ham) return (model ?? "").trim();
  const kodsuz = ham.replace(/^[A-Z]{2,5}\d{3,8}\s+(?=[A-ZÇĞİÖŞÜa-zçğıöşü]{2,})/u, "").trim();
  return kodsuz || ham;
}

export function faturaSatiriniAktar(satir: GoruSatiri, tedarikci: string): EslesmisFaturaSatiri {
  const gorseller = satir.siteGorseller ?? [];
  const ozellikler = satir.siteVaryant
    ? faturaKatalogMetadatasi({ ozellikler: satir.ozellikler, varyant: satir.varyant }).attributes
    : satir.ozellikler;
  const eksikler = [...(satir.eksikler ?? [])];
  if (!satir.dogrulamaDurumu) eksikler.push("OpenRouter doğrulama durumu bildirmedi.");
  if (satir.okumaGuveni === null) eksikler.push("OpenRouter okuma güveni bildirmedi.");
  const temizAd = resmiUrunBasliginiTemizle(satir.ad, satir.model);
  const ekler = {
    satirNo: satir.satirNo, uretici: satir.uretici, gramaj: satir.gramaj,
    dogrulamaDurumu: satir.dogrulamaDurumu, eslesenBilgiler: satir.eslesenBilgiler,
    eksikler, gorselDogrulamaDurumu: satir.gorselDogrulamaDurumu,
    duplicateGroup: satir.duplicateGroup ?? null, canonicalRowId: satir.canonicalRowId ?? null,
    kaynaklar: satir.kaynaklar,
  };
  return {
    ...ekler,
    hamSatir: satir.hamSatir, model: satir.model, ad: temizAd,
    barkod: satir.barkod, varyant: satir.varyant, beden: satir.beden, marka: satir.marka,
    adet: satir.adet, birim: satir.birim, alisBirimFiyat: satir.birimFiyat, satirToplam: satir.tutar,
    guven: satir.okumaGuveni ?? 0,
    siteAd: temizAd, siteAciklama: satir.siteAciklama,
    siteGorsel: gorseller[0] ?? "", siteGorseller: gorseller, siteSayfa: satir.siteSayfa,
    siteKategori: satir.siteKategori, siteOzellikler: ozellikler,
    siteMarka: satir.siteMarka,
    sonuc: presetDurumunuAktar(satir.dogrulamaDurumu),
    uyari: eksikler.length ? eksikler.join(" · ") : undefined,
    katalog: {
      ...ekler, firma: tedarikci, kaynakFirma: satir.uretici || satir.siteMarka || satir.marka || tedarikci,
      dayanak: "ad", izinDurumu: "yok",
      resmiAd: temizAd, marka: satir.siteMarka || satir.marka,
      aciklama: satir.siteAciklama ?? "", gorseller, gorselAdaylari: gorseller,
      kaynak: satir.siteSayfa ?? "", kategori: satir.siteKategori, ozellikler,
      beden: satir.beden, varyant: satir.siteVaryant || satir.varyant,
    },
  };
}
