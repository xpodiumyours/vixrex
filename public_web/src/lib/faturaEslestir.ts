import { ureticiUrunuBul } from "@/lib/ureticiKatalog";

// Fatura satırını üretici kataloğuyla buluşturan TEK yer.
//
// Bilerek fotoğrafı KİM okursa okusun (telefon uygulaması, Başak, ileride
// tarayıcı) bu fonksiyona aynı şekilde girer. Katalog eşleştirme mantığı
// burada tek kopya durur; farklı okuyucular kendi eşleştirme kuralını
// yazmaz — ikinci bir "hangi ürün bu" kararı hiçbir yerde tekrarlanmaz.

export interface HamFaturaSatiri {
  model: string;
  ad: string;
  barkod: string;
  varyant: string;
  beden: string;
  adet: number | null;
  alisBirimFiyat: number | null;
  satirToplam: number | null;
  guven: number;
}

export interface KatalogBilgisi {
  firma: string;
  dayanak: "kod" | "barkod";
  izinDurumu: "yok" | "bekliyor" | "var";
  resmiAd: string;
  marka: string;
  aciklama: string;
  gorseller: string[];
  kaynak: string;
}

export interface EslesmisFaturaSatiri extends HamFaturaSatiri {
  katalog: KatalogBilgisi | null;
}

export function faturaSatiriniEslestir(satir: HamFaturaSatiri): EslesmisFaturaSatiri {
  const eslesme = ureticiUrunuBul({ model: satir.model || null, barkod: satir.barkod || null });
  if (!eslesme) return { ...satir, katalog: null };

  return {
    ...satir,
    katalog: {
      firma: eslesme.firma.ad,
      dayanak: eslesme.dayanak,
      izinDurumu: eslesme.firma.izinDurumu,
      resmiAd: eslesme.urun.ad,
      marka: eslesme.urun.marka,
      aciklama: eslesme.urun.aciklama,
      gorseller: eslesme.urun.gorseller,
      kaynak: eslesme.urun.kaynak,
    },
  };
}

export function faturaSatirlariniEslestir(satirlar: HamFaturaSatiri[]): EslesmisFaturaSatiri[] {
  return satirlar.map(faturaSatiriniEslestir);
}
