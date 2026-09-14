import { describe, expect, it } from "vitest";
import {
  MAX_PRODUCT_IMAGES,
  MIN_PRODUCT_IMAGES,
  MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE,
  validateExternalProductImageUrls,
  validateProductImageDimensions,
  validateProductImageUrls,
} from "../src/lib/productImagePolicy";

const managedImages = Array.from({ length: 11 }, (_, index) =>
  `https://example.supabase.co/storage/v1/object/public/shelf-images/magaza/products/urun/${index + 1}.jpg`,
);
const externalImages = Array.from({ length: 3 }, (_, index) =>
  `https://cdn.example.com/${index + 1}.jpg`,
);

describe("product image policy", () => {
  it("en az 3, en fazla 10 yönetilen owner fotoğrafı kabul eder", () => {
    expect(MIN_PRODUCT_IMAGES).toBe(3);
    expect(MAX_PRODUCT_IMAGES).toBe(10);
    expect(validateProductImageUrls(managedImages.slice(0, 3)).ok).toBe(true);
    expect(validateProductImageUrls(managedImages.slice(0, 10)).ok).toBe(true);
  });

  it("0-2 fotoğrafı reddeder", () => {
    expect(validateProductImageUrls([]).ok).toBe(false);
    expect(validateProductImageUrls(managedImages.slice(0, 1)).ok).toBe(false);
    expect(validateProductImageUrls(managedImages.slice(0, 2)).ok).toBe(false);
  });

  it("10'dan fazla fotoğrafı reddeder", () => {
    expect(validateProductImageUrls(managedImages).ok).toBe(false);
  });

  it("tekrarlı URL'leri tek fotoğraf sayar", () => {
    const result = validateProductImageUrls([
      managedImages[0],
      managedImages[0],
      managedImages[1],
      managedImages[2],
    ]);
    expect(result.ok).toBe(true);
    expect(result.imageUrls).toHaveLength(3);
  });

  it("owner manuel akışında dış bağlantıyı reddeder", () => {
    const result = validateProductImageUrls(externalImages);
    expect(result.ok).toBe(false);
    expect(result.error).toContain("Görsel ekle");
  });

  it("XML/toplu entegrasyonda mevcut http/https CDN uyumluluğunu korur", () => {
    expect(validateExternalProductImageUrls(externalImages).ok).toBe(true);
    expect(
      validateExternalProductImageUrls([
        externalImages[0],
        externalImages[1],
        "http://cdn.example.com/3.jpg",
      ]).ok,
    ).toBe(true);
  });

  it("yeni ürün fotoğrafında kısa kenarı en az 1200 px ister", () => {
    expect(MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE).toBe(1200);
    expect(validateProductImageDimensions(1200, 1600).ok).toBe(true);
    expect(validateProductImageDimensions(1600, 1200).ok).toBe(true);
    expect(validateProductImageDimensions(1199, 1600).ok).toBe(false);
    expect(validateProductImageDimensions(1600, 1199).ok).toBe(false);
    expect(validateProductImageDimensions(0, 1600).ok).toBe(false);
  });
});
