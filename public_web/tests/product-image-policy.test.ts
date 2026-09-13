import { describe, expect, it } from "vitest";
import {
  MAX_PRODUCT_IMAGES,
  MIN_PRODUCT_IMAGES,
  validateProductImageUrls,
} from "../src/lib/productImagePolicy";

const images = Array.from({ length: 11 }, (_, index) =>
  `https://example.com/${index + 1}.jpg`,
);

describe("product image policy", () => {
  it("en az 3, en fazla 10 fotoğraf kabul eder", () => {
    expect(MIN_PRODUCT_IMAGES).toBe(3);
    expect(MAX_PRODUCT_IMAGES).toBe(10);
    expect(validateProductImageUrls(images.slice(0, 3)).ok).toBe(true);
    expect(validateProductImageUrls(images.slice(0, 10)).ok).toBe(true);
  });

  it("0-2 fotoğrafı reddeder", () => {
    expect(validateProductImageUrls([]).ok).toBe(false);
    expect(validateProductImageUrls(images.slice(0, 1)).ok).toBe(false);
    expect(validateProductImageUrls(images.slice(0, 2)).ok).toBe(false);
  });

  it("10'dan fazla fotoğrafı reddeder", () => {
    expect(validateProductImageUrls(images).ok).toBe(false);
  });

  it("tekrarlı URL'leri tek fotoğraf sayar", () => {
    const result = validateProductImageUrls([
      images[0],
      images[0],
      images[1],
      images[2],
    ]);
    expect(result.ok).toBe(true);
    expect(result.imageUrls).toHaveLength(3);
  });

  it("http/https dışındaki değerleri reddeder", () => {
    expect(
      validateProductImageUrls([images[0], images[1], "file:///urun.jpg"]).ok,
    ).toBe(false);
  });
});
