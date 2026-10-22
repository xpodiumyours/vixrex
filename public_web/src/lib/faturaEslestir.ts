// Fatura satırını üretici kataloğuyla buluşturan TEK yer.
//
// Bilerek fotoğrafı KİM okursa okusun (telefon uygulaması, Başak, ileride
// tarayıcı) bu fonksiyona aynı şekilde girer. Katalog eşleştirme mantığı
// burada tek kopya durur; farklı okuyucular kendi eşleştirme kuralını
// yazmaz — ikinci bir "hangi ürün bu" kararı hiçbir yerde tekrarlanmaz.

import type { ProductAttributeValue } from "@/lib/productRichData";

export interface FotografKaniti {
  kaynakSayfa: string;
  kaynakGorsel: string;
  kaynakAlintisi: string;
  lunaGerekcesi: string;
}

export interface HamFaturaSatiri {
  hamSatir?: string;
  model: string;
  ad: string;
  barkod: string;
  varyant: string;
  beden: string;
  marka?: string;
  adet: number | null;
  birim?: string;
  alisBirimFiyat: number | null;
  satirToplam: number | null;
  guven: number;
  siteAciklama?: string;
  siteGorsel?: string;
  siteGorseller?: string[];
  siteKategori?: string;
  siteOzellikler?: ProductAttributeValue[];
  uretici?: string;
  gramaj?: string;
  satirNo?: number | null;
  dogrulamaDurumu?: string;
  eslesenBilgiler?: unknown;
  eksikler?: string[];
  gorselDogrulamaDurumu?: string;
  kaynaklar?: Array<string | Record<string, unknown>>;
  siteUrunVaryantlari?: Array<{ id: string; secenekler: Array<{ key: string; value: string }>; barkod: string; gorseller: string[] }>;
  siteSayfa?: string;
  siteMarka?: string;
  siteEslesti?: boolean;
  siteAd?: string;
  siteDayanak?: "kod" | "barkod" | "ad";
  siteFotografKaniti?: FotografKaniti;
  sayfaDogrulandi?: boolean;
}

/**
 * Her satırın dört sonuçtan biri vardır:
 * kanitli · eksik · celiski · iz-yok.
 */
export type SatirSonucu = "kanitli" | "eksik" | "celiski" | "iz-yok";

export interface KatalogBilgisi {
  firma: string;
  kaynakFirma: string;
  dayanak: "kod" | "barkod" | "ad";
  izinDurumu: "yok" | "bekliyor" | "var";
  resmiAd: string;
  marka: string;
  aciklama: string;
  gorseller: string[];
  gorselAdaylari: string[];
  kategori?: string;
  beden?: string;
  varyant?: string;
  ozellikler?: ProductAttributeValue[];
  uretici?: string;
  gramaj?: string;
  satirNo?: number | null;
  dogrulamaDurumu?: string;
  eslesenBilgiler?: unknown;
  eksikler?: string[];
  gorselDogrulamaDurumu?: string;
  kaynaklar?: Array<string | Record<string, unknown>>;
  urunVaryantlari?: Array<{ id: string; secenekler: Array<{ key: string; value: string }>; barkod: string; gorseller: string[] }>;
  fotografKaniti?: FotografKaniti;
  varyantlar?: Array<{ ad: string; barkod: string; gorseller: string[] }>;
  kaynak: string;
}

export interface CeliskiBilgisi {
  dayanak: "kod" | "barkod" | "ad";
  adaylar: Array<{
    ad: string;
    kaynak: string;
    aciklama?: string;
    gorseller?: string[];
    kod?: string;
    barkod?: string;
    marka?: string;
  }>;
}

export interface EslesmisFaturaSatiri extends HamFaturaSatiri {
  katalog: KatalogBilgisi | null;
  sonuc: SatirSonucu;
  celiski?: CeliskiBilgisi;
  /**
   * Esnafa gösterilecek şüphe notu. Eşleşme kuruldu ama kanıt zayıfsa
   * doldurulur; dolu olan satır toplu onaydan çıkar, tek tek bakılır.
   */
  uyari?: string;
}

export function eslesmeyenSatir(satir: HamFaturaSatiri): EslesmisFaturaSatiri {
  return { ...satir, katalog: null, sonuc: "eksik" };
}

export function siteKartiniUygula(satir: EslesmisFaturaSatiri): EslesmisFaturaSatiri {
  const sayfa = (satir.siteSayfa ?? "").trim();
  const resmiAd = (satir.siteAd ?? "").trim();
  const gorseller = [...new Set([satir.siteGorsel ?? "", ...(satir.siteGorseller ?? [])]
    .map((url) => url.trim()).filter((url) => url.startsWith("https://")))];
  if (satir.siteEslesti !== true || !resmiAd || !sayfa.startsWith("https://"))
    return satir.sonuc === "kanitli" ? { ...satir, sonuc: "eksik" } : satir;
  // Luna has decided the official product identity; technical transport never grades the match.
  return {
    ...satir, sonuc: "kanitli",
    katalog: {
      firma: satir.katalog?.firma ?? "",
      kaynakFirma: satir.siteMarka || satir.katalog?.kaynakFirma || "",
      dayanak: satir.siteDayanak ?? "ad",
      izinDurumu: satir.katalog?.izinDurumu ?? "yok",
      resmiAd, marka: satir.siteMarka || satir.marka || satir.katalog?.marka || "",
      aciklama: (satir.siteAciklama ?? "").trim(),
      gorseller, gorselAdaylari: gorseller,
      kategori: satir.siteKategori ?? "",
      ozellikler: satir.siteOzellikler ?? [],
      urunVaryantlari: satir.siteUrunVaryantlari ?? [],
      kaynak: sayfa,
    },
  };
}

/**
 * Resmî sayfa / kod araştırması bir fotoğraf adayı döndürmüş olabilir.
 * Görsel doğrulanmadan "kanitli" etiketi verilmez. Buna rağmen araştırma
 * adayı ve kaynak URL'si kaybolmaz; sonraki denemede aynı kaynak incelenebilir.
 * Buradaki katalog, ONAYLANMIŞ ürün kimliği veya yayın izni değildir.
 */
export function siteAdayiniKoru(satir: EslesmisFaturaSatiri): EslesmisFaturaSatiri {
  if (satir.sonuc === "kanitli") return satir;
  const kaynak = (satir.siteSayfa ?? "").trim();
  const resmiAd = (satir.siteAd ?? "").trim();
  const dayanak = satir.siteDayanak;
  if (!kaynak.startsWith("https://") || !resmiAd || !dayanak) return satir;
  const gorselAdayi = (satir.siteGorsel ?? "").trim();
  const gorselListesi = [...new Set([gorselAdayi, ...(satir.siteGorseller ?? [])].filter((adres) => adres.startsWith("https://")))];
  return {
    ...satir,
    sonuc: "eksik",
    katalog: {
      firma: satir.katalog?.firma ?? "",
      kaynakFirma: satir.siteMarka || satir.katalog?.kaynakFirma || "",
      dayanak,
      izinDurumu: satir.katalog?.izinDurumu ?? "yok",
      resmiAd,
      marka: satir.siteMarka || satir.marka || "",
      aciklama: (satir.siteAciklama ?? "").trim(),
      gorseller: gorselListesi,
      gorselAdaylari: gorselListesi,
      kategori: satir.siteKategori ?? "",
      ozellikler: satir.siteOzellikler ?? [],
      urunVaryantlari: satir.siteUrunVaryantlari ?? [],
      kaynak,
    },
    uyari: satir.uyari || "Ürün sayfası adayı bulundu; fotoğraf kartta.",
  };
}

export function sonucOzeti(
  satirlar: EslesmisFaturaSatiri[],
): Record<"kanitli" | "eksik" | "celiski" | "izYok", number> {
  const ozet = { kanitli: 0, eksik: 0, celiski: 0, izYok: 0 };
  for (const satir of satirlar) {
    if (satir.sonuc === "iz-yok") ozet.izYok += 1;
    else ozet[satir.sonuc] += 1;
  }
  return ozet;
}
