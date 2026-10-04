import sharp from "sharp";

/**
 * SUNUCU TARAFI GÖRSEL SIKIŞTIRMA.
 *
 * NEDEN VAR (2026-08-28 ölçümü): `shelf-images` kovasında Mayıs'ta yüklenen
 * dosyaların ortalaması 1157 kB, en büyüğü 6442 kB'dı. Flutter'a
 * `ImageOptimizationService` eklendikten sonra Ağustos ortalaması 108 kB'ye
 * düştü. Web tarafında ise hiç sıkıştırma yoktu — 26 Ağustos'ta web ana kapı
 * olduğu için 100 vitrinin görselleri buradan gelecek. Sıkıştırma olmadan
 * ücretsiz plandaki 1 GB depo ve aylık 5 GB trafik sınırı zorlanır.
 *
 * NEDEN SUNUCUDA, TARAYICIDA DEĞİL: istemci tarafı sıkıştırma atlanabilir.
 * Depoya giden tek yol bu modülden geçer.
 *
 * PARAMETRELER FLUTTER İLE BİREBİR AYNI — iki yüzey aynı boyutta görsel
 * üretmeli, yoksa aynı vitrin uygulamada bir, webde başka ağırlıkta olur.
 * Ölçüt dosya: `lib/services/image_optimization_service.dart`.
 *
 * EXIF: sharp varsayılan olarak meta veriyi taşımaz. Telefon fotoğrafları
 * GPS konumu taşıyabildiği için bu KVKK açısından da doğru davranış —
 * `withMetadata()` çağırma.
 */

export const UZUN_KENAR = 1600;
export const YEDEK_UZUN_KENAR = 1200;
export const KALITE = 82;
export const YEDEK_KALITE = 65;
export const TERCIH_EDILEN_EN_FAZLA_BAYT = 1024 * 1024;

/** Depoya yazılan nesnelerin önbellek süresi: 1 yıl. */
export const ONBELLEK_SANIYE = "31536000";

export class GorselSikistirmaHatasi extends Error {}

export type SikistirilmisGorsel = {
  bayt: Uint8Array;
  tur: string;
  uzanti: string;
};

/**
 * Görseli en fazla 1600 px uzun kenara indirir ve yeniden kodlar.
 *
 * WebP girdisi olduğu gibi geçer — Flutter da öyle yapıyor; WebP zaten
 * sıkıştırılmış geliyor ve yeniden kodlamak kaliteyi boşuna düşürür.
 *
 * @param tur `gercekTur()` ile BAYTLARDAN doğrulanmış MIME türü. İstemcinin
 *   söylediği content-type buraya verilmemeli.
 */
export async function gorseliSikistir(
  bayt: Uint8Array,
  tur: string,
  secenekler: { minShortEdge?: number } = {},
): Promise<SikistirilmisGorsel> {
  if (bayt.length === 0) {
    throw new GorselSikistirmaHatasi("Görsel okunamadı.");
  }

  if ((secenekler.minShortEdge ?? 0) > 0) {
    try {
      const metadata = await sharp(Buffer.from(bayt), { failOn: "none" }).metadata();
      const width = metadata.width ?? 0;
      const height = metadata.height ?? 0;
      if (width <= 0 || height <= 0) throw new Error("dimensions");
      if (Math.min(width, height) < secenekler.minShortEdge!) {
        throw new GorselSikistirmaHatasi(`Ürün fotoğrafının kısa kenarı en az ${secenekler.minShortEdge} px olmalıdır.`);
      }
    } catch (error) {
      if (error instanceof GorselSikistirmaHatasi) throw error;
      throw new GorselSikistirmaHatasi("Ürün fotoğrafının ölçüleri okunamadı.");
    }
  }
  if (tur === "image/webp") {
    return { bayt, tur, uzanti: "webp" };
  }

  const pngMi = tur === "image/png";

  try {
    const kaynak = Buffer.from(bayt);
    const ilk = await kodla(kaynak, pngMi, UZUN_KENAR, KALITE);

    // Flutter'daki ikinci deneme: 1 MB'ı aşarsa daha sert sıkıştır.
    // PNG'de ayrıca uzun kenar 1200'e iner (fotoğrafik PNG çok şişiyor).
    if (ilk.length > TERCIH_EDILEN_EN_FAZLA_BAYT) {
      const ikinci = await kodla(
        kaynak,
        pngMi,
        pngMi ? YEDEK_UZUN_KENAR : UZUN_KENAR,
        YEDEK_KALITE
      );
      if (ikinci.length > 0 && ikinci.length < ilk.length) {
        return sonuc(ikinci, pngMi);
      }
    }

    if (ilk.length === 0) {
      throw new GorselSikistirmaHatasi("Görsel işlenemedi.");
    }

    // Sıkıştırma kaynaktan büyük çıkarsa kaynağı koru — küçük ve zaten
    // optimize edilmiş görsellerde olabiliyor.
    if (ilk.length >= bayt.length) {
      return { bayt, tur, uzanti: pngMi ? "png" : "jpg" };
    }

    return sonuc(ilk, pngMi);
  } catch (hata) {
    if (hata instanceof GorselSikistirmaHatasi) throw hata;
    throw new GorselSikistirmaHatasi(
      "Görsel işlenemedi. JPG, PNG veya WebP olarak tekrar dene."
    );
  }
}

async function kodla(
  kaynak: Buffer,
  pngMi: boolean,
  uzunKenar: number,
  kalite: number
): Promise<Buffer> {
  const boru = sharp(kaynak, { failOn: "none" }).rotate().resize({
    width: uzunKenar,
    height: uzunKenar,
    fit: "inside",
    // Küçük görsel büyütülmez — Flutter da olduğu gibi bırakıyor.
    withoutEnlargement: true,
  });

  return pngMi
    ? boru.png({ compressionLevel: 9, palette: true, quality: kalite }).toBuffer()
    : boru.jpeg({ quality: kalite, mozjpeg: true }).toBuffer();
}

function sonuc(bayt: Buffer, pngMi: boolean): SikistirilmisGorsel {
  return {
    bayt: new Uint8Array(bayt),
    tur: pngMi ? "image/png" : "image/jpeg",
    uzanti: pngMi ? "png" : "jpg",
  };
}
