import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import sharp from "sharp";
import {
  gorseliSikistir,
  ONBELLEK_SANIYE,
  UZUN_KENAR,
} from "@/lib/gorselSikistir";

/**
 * GÖRSEL SIKIŞTIRMA SÖZLEŞMESİ (2026-08-28).
 *
 * Canlıdan ölçüldü: Mayıs'ta yüklenen dosyaların ortalaması 1157 kB, en
 * büyüğü 6442 kB'dı. Flutter'a sıkıştırma eklendikten sonra Ağustos
 * ortalaması 108 kB'ye düştü. Web tarafında hiç sıkıştırma yoktu ve
 * 26 Ağustos'ta web ana kapı oldu — 100 vitrinin görselleri buradan
 * gelecek. Ücretsiz planda 1 GB depo ve aylık 5 GB trafik sınırı var.
 *
 * Bu test, sıkıştırmanın yükleme yolundan çıkarılmasını engelliyor.
 */

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

/** Sıkıştırılabilir, gürültülü bir test görseli üretir. */
async function ornekJpeg(genislik: number, yukseklik: number) {
  const pikseller = Buffer.alloc(genislik * yukseklik * 3);
  for (let i = 0; i < pikseller.length; i++) {
    pikseller[i] = (i * 97) % 256;
  }
  return sharp(pikseller, {
    raw: { width: genislik, height: yukseklik, channels: 3 },
  })
    .jpeg({ quality: 100 })
    .toBuffer();
}

async function ornekSeffafPng(genislik: number, yukseklik: number) {
  const pikseller = Buffer.alloc(genislik * yukseklik * 4);
  for (let y = 0; y < yukseklik; y++) {
    for (let x = 0; x < genislik; x++) {
      const idx = (y * genislik + x) * 4;
      pikseller[idx] = Math.floor((x * 255) / Math.max(1, genislik - 1));
      pikseller[idx + 1] = Math.floor((y * 255) / Math.max(1, yukseklik - 1));
      pikseller[idx + 2] = ((x * 7 + y * 13) % 256);
      pikseller[idx + 3] = x < genislik / 4 ? 0 : x < genislik / 2 ? 128 : 255;
    }
  }
  return sharp(pikseller, {
    raw: { width: genislik, height: yukseklik, channels: 4 },
  })
    .png({ compressionLevel: 9 })
    .toBuffer();
}

describe("görsel sıkıştırma", () => {
  it("1600 pikselden büyük görseli küçültür", async () => {
    const kaynak = await ornekJpeg(3000, 2000);
    const sonuc = await gorseliSikistir(new Uint8Array(kaynak), "image/jpeg");

    const olcu = await sharp(Buffer.from(sonuc.bayt)).metadata();
    expect(Math.max(olcu.width ?? 0, olcu.height ?? 0)).toBeLessThanOrEqual(
      UZUN_KENAR
    );
    expect(sonuc.bayt.length).toBeLessThan(kaynak.length);
    expect(sonuc.tur).toBe("image/jpeg");
    expect(sonuc.uzanti).toBe("jpg");
  }, 10_000);

  it("küçük görseli büyütmez", async () => {
    const kaynak = await ornekJpeg(800, 600);
    const sonuc = await gorseliSikistir(new Uint8Array(kaynak), "image/jpeg");

    const olcu = await sharp(Buffer.from(sonuc.bayt)).metadata();
    expect(olcu.width).toBe(800);
    expect(olcu.height).toBe(600);
  });

  it("WebP girdisine dokunmaz", async () => {
    // Flutter da WebP'yi olduğu gibi geçiriyor; yeniden kodlamak kaliteyi
    // boşuna düşürür.
    const kaynak = await sharp(await ornekJpeg(2000, 2000))
      .webp()
      .toBuffer();
    const sonuc = await gorseliSikistir(new Uint8Array(kaynak), "image/webp");

    expect(sonuc.bayt.length).toBe(kaynak.length);
    expect(sonuc.uzanti).toBe("webp");
  });

  it("bozuk veriyi anlaşılır hatayla reddeder", async () => {
    await expect(
      gorseliSikistir(new Uint8Array([1, 2, 3, 4]), "image/jpeg")
    ).rejects.toThrow(/Görsel/);
  });

  it("boş girdiyi reddeder", async () => {
    await expect(
      gorseliSikistir(new Uint8Array(), "image/jpeg")
    ).rejects.toThrow();
  });

  it("PNG girdisini WebP olarak sıkıştırır, 256+ rengi ve şeffaflığı korur", async () => {
    const kaynak = await ornekSeffafPng(400, 400);
    const sonuc = await gorseliSikistir(new Uint8Array(kaynak), "image/png");

    expect(sonuc.tur).toBe("image/webp");
    expect(sonuc.uzanti).toBe("webp");
    expect(sonuc.bayt.length).toBeLessThan(kaynak.length * 0.5);

    const olcu = await sharp(Buffer.from(sonuc.bayt)).metadata();
    expect(olcu.format).toBe("webp");
    expect(olcu.hasAlpha).toBe(true);

    const { data, info } = await sharp(Buffer.from(sonuc.bayt))
      .ensureAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });

    const renkler = new Set<number>();
    let seffafPikselVar = false;
    let opakPikselVar = false;
    for (let i = 0; i < data.length; i += info.channels) {
      renkler.add((data[i] << 16) | (data[i + 1] << 8) | data[i + 2]);
      const alfa = data[i + 3];
      if (alfa === 0) seffafPikselVar = true;
      if (alfa === 255) opakPikselVar = true;
    }

    expect(renkler.size).toBeGreaterThan(256);
    expect(seffafPikselVar).toBe(true);
    expect(opakPikselVar).toBe(true);
  });

  it("sıkıştırma PNG kaynaktan büyük veya eşit çıkarsa kaynağı korur", async () => {
    const kaynak = await sharp({
      create: {
        width: 2,
        height: 2,
        channels: 4,
        background: { r: 255, g: 0, b: 0, alpha: 0.5 },
      },
    })
      .png({ compressionLevel: 9 })
      .toBuffer();

    const sonuc = await gorseliSikistir(new Uint8Array(kaynak), "image/png");

    expect(sonuc.tur).toBe("image/png");
    expect(sonuc.uzanti).toBe("png");
    expect(sonuc.bayt.length).toBe(kaynak.length);
  });
});

describe("yükleme yolları sıkıştırmadan geçiyor", () => {
  it("sahip yükleme rotası ham baytı depoya yazmıyor", () => {
    const kaynak = oku("src/app/api/owner-upload/route.ts");
    expect(kaynak).toMatch(/gorseliSikistir\(bayt, tur\)/);
    // Ham `bayt` doğrudan upload'a verilirse sıkıştırma atlanmış olur.
    expect(kaynak).not.toMatch(/\.upload\(\s*yol,\s*bayt\b/);
    expect(kaynak).toMatch(/upload\(yol, sikistirilmis\.bayt/);
  });

  it("Instagram içe aktarma da sıkıştırıyor", () => {
    const kaynak = oku("src/app/api/instagram/import/route.ts");
    expect(kaynak).toMatch(/gorseliSikistir\(/);
    expect(kaynak).not.toMatch(/\.upload\(objectPath,\s*buffer\b/);
  });

  it("her iki rota da bir yıllık önbellek yazıyor", () => {
    for (const yol of [
      "src/app/api/owner-upload/route.ts",
      "src/app/api/instagram/import/route.ts",
    ]) {
      expect(oku(yol)).toMatch(/cacheControl: ONBELLEK_SANIYE/);
    }
    // Varsayılan bir saat, tekrar eden ziyaretlerde trafik yakıyordu.
    expect(ONBELLEK_SANIYE).toBe("31536000");
  });

  it("Flutter yüklemesi de aynı önbellek süresini kullanıyor", () => {
    const dart = readFileSync(
      resolve(KOK, "../lib/services/store_shelf_upload_service.dart"),
      "utf8"
    );
    expect(dart).toMatch(/_onbellekSaniye = '31536000'/);
    expect(dart).toMatch(/cacheControl: _onbellekSaniye/);
  });
});
