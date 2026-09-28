import { firmaAnahtariniCoz, ureticiUrunuBul } from "@/lib/ureticiKatalog";

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
  /**
   * Esnafa gösterilecek şüphe notu. Eşleşme kuruldu ama kanıt zayıfsa
   * doldurulur; dolu olan satır toplu onaydan çıkar, tek tek bakılır.
   */
  uyari?: string;
}

export function faturaSatiriniEslestir(
  satir: HamFaturaSatiri,
  firmaAnahtari: string | null = null,
): EslesmisFaturaSatiri {
  const eslesme = ureticiUrunuBul({
    model: satir.model || null,
    barkod: satir.barkod || null,
    firmaAnahtari,
  });
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

/**
 * Fatura satırlarını kataloğa bağlar ve TEDARİKÇİ TUTARLILIĞINI gözetir.
 *
 * Bir fatura tek tedarikçiden gelir. Belgede tedarikçi yazıyorsa onun
 * kataloğu öncelikli aranır. Yazmıyorsa (ölçülen gerçek faturada yazmıyordu)
 * satırların hangi firmalara dağıldığına bakılır: çoğunluk bir firmadaysa,
 * tek tük başka firmadan gelen eşleşme şüphelidir — aynı ürün kodu iki
 * firmada olabilir. O satırlar yanlış ürünle eşleşmiş olabileceği için
 * işaretlenir ve güveni düşürülür; silinmez, esnafa sorulur.
 */
export function faturaSatirlariniEslestir(
  satirlar: HamFaturaSatiri[],
  tedarikciAdi = "",
): EslesmisFaturaSatiri[] {
  const firmaAnahtari = tedarikciAdi ? firmaAnahtariniCoz(tedarikciAdi) : null;
  const eslesenler = satirlar.map((satir) => faturaSatiriniEslestir(satir, firmaAnahtari));

  const sayim = new Map<string, number>();
  for (const satir of eslesenler) {
    if (!satir.katalog) continue;
    sayim.set(satir.katalog.firma, (sayim.get(satir.katalog.firma) ?? 0) + 1);
  }
  if (sayim.size < 2) return eslesenler;

  const [baskinFirma] = [...sayim.entries()].sort((a, b) => b[1] - a[1])[0];

  return eslesenler.map((satir) => {
    if (!satir.katalog || satir.katalog.firma === baskinFirma) return satir;
    return {
      ...satir,
      guven: Math.min(satir.guven, 0.5),
      uyari: `Bu satır ${satir.katalog.firma} ürünüyle eşleşti; faturadaki diğer ürünler ${baskinFirma} firmasından. Kontrol et.`,
    };
  });
}
