import sharp from "sharp";
import { describe, expect, it } from "vitest";
import { gorseliSikistir } from "../src/lib/gorselSikistir";
import { MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE } from "../src/lib/productImagePolicy";

async function makeJpeg(width: number, height: number) {
  const buffer = await sharp({
    create: {
      width,
      height,
      channels: 3,
      background: { r: 245, g: 245, b: 245 },
    },
  })
    .jpeg({ quality: 90 })
    .toBuffer();
  return new Uint8Array(buffer);
}

describe("product image source quality", () => {
  it("1200 px altındaki kısa kenarı depoya gitmeden reddeder", async () => {
    const source = await makeJpeg(MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE - 1, 1200);
    await expect(
      gorseliSikistir(source, "image/jpeg", {
        minShortEdge: MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE,
      }),
    ).rejects.toMatchObject({
      message: `Ürün fotoğrafının kısa kenarı en az ${MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE} px olmalıdır.`,
    });
  });

  it("1200 px kısa kenarlı ürünü kabul eder ve uzun kenarı 1600 px içinde tutar", async () => {
    const source = await makeJpeg(1200, 1800);
    const result = await gorseliSikistir(source, "image/jpeg", {
      minShortEdge: MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE,
    });
    const metadata = await sharp(Buffer.from(result.bayt)).metadata();
    expect(result.tur).toBe("image/jpeg");
    expect(metadata.width).toBeGreaterThan(0);
    expect(metadata.height).toBeGreaterThan(0);
    expect(Math.max(metadata.width ?? 0, metadata.height ?? 0)).toBeLessThanOrEqual(1600);
  });
});
