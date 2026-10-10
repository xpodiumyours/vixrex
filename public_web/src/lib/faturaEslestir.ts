// Fatura satırını üretici kataloğuyla buluşturan TEK yer.
//
// Bilerek fotoğrafı KİM okursa okusun (telefon uygulaması, Başak, ileride
// tarayıcı) bu fonksiyona aynı şekilde girer. Katalog eşleştirme mantığı
// burada tek kopya durur; farklı okuyucular kendi eşleştirme kuralını
// yazmaz — ikinci bir "hangi ürün bu" kararı hiçbir yerde tekrarlanmaz.

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
  siteSayfa?: string;
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
  const aciklama = (satir.siteAciklama ?? "").trim();
  const gorsel = (satir.siteGorsel ?? "").trim();
  const sayfa = (satir.siteSayfa ?? "").trim();
  const fotografKaniti = satir.siteFotografKaniti;
  if (
    satir.sayfaDogrulandi === true && aciklama && gorsel.startsWith("https://") && sayfa.startsWith("https://") &&
    fotografKaniti?.kaynakSayfa === sayfa && fotografKaniti.kaynakGorsel === gorsel &&
    fotografKaniti.kaynakAlintisi.length > 0 && fotografKaniti.lunaGerekcesi.length > 0
  ) {
    return {
      ...satir,
      sonuc: "kanitli",
      katalog: {
        firma: satir.katalog?.firma ?? "",
        kaynakFirma: satir.katalog?.kaynakFirma ?? "",
        dayanak: satir.siteDayanak ?? satir.katalog?.dayanak ?? "kod",
        izinDurumu: satir.katalog?.izinDurumu ?? "yok",
        resmiAd: (satir.siteAd ?? "").trim() || satir.katalog?.resmiAd || satir.ad,
        marka: satir.katalog?.marka || satir.marka || "",
        aciklama,
        gorseller: [gorsel],
        gorselAdaylari: [gorsel],
        fotografKaniti,
        kaynak: sayfa,
      },
    };
  }
  if (satir.sonuc !== "kanitli" || !satir.katalog) return satir;
  return {
    ...satir,
    sonuc: "eksik",
    katalog: { ...satir.katalog, aciklama: "", gorseller: [] },
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
  return {
    ...satir,
    sonuc: "eksik",
    katalog: {
      firma: satir.katalog?.firma ?? "",
      kaynakFirma: satir.katalog?.kaynakFirma ?? "",
      dayanak,
      izinDurumu: satir.katalog?.izinDurumu ?? "yok",
      resmiAd,
      marka: satir.marka ?? "",
      aciklama: (satir.siteAciklama ?? "").trim(),
      gorseller: [],
      gorselAdaylari: gorselAdayi.startsWith("https://") ? [gorselAdayi] : [],
      kaynak,
    },
    uyari: satir.uyari || "Ürün sayfası adayı bulundu; doğru fotoğraf henüz doğrulanmadı. Yayınlanamaz.",
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