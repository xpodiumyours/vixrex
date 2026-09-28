import { afterEach, describe, expect, it, vi } from "vitest";
import {
  MAX_PRODUCT_IMAGES,
  MIN_PRODUCT_IMAGES,
  validateProductImageUrlsAllowingFewerImages,
  validateProductImageUrls,
} from "../src/lib/productImagePolicy";

const SUPABASE_URL = "https://ornekproje.supabase.co";
const yonetilenGorsel = (dosyaAdi: string) =>
  `${SUPABASE_URL}/storage/v1/object/public/shelf-images/magaza-1/products/${dosyaAdi}`;

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("validateProductImageUrls (mevcut sıkı kapı)", () => {
  it("3'ten az fotoğrafta engel olur", () => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", SUPABASE_URL);
    const sonuc = validateProductImageUrls([yonetilenGorsel("a.jpg")]);
    expect(sonuc.ok).toBe(false);
    expect(sonuc.error).toContain(`en az ${MIN_PRODUCT_IMAGES}`);
  });
});

describe("validateProductImageUrlsAllowingFewerImages (taslak kapısı)", () => {
  it("tek fotoğrafla dahi geçer, engel olmaz", () => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", SUPABASE_URL);
    const sonuc = validateProductImageUrlsAllowingFewerImages([yonetilenGorsel("a.jpg")]);
    expect(sonuc.ok).toBe(true);
    expect(sonuc.imageUrls).toEqual([yonetilenGorsel("a.jpg")]);
  });

  it("hiç fotoğraf olmasa da geçer", () => {
    const sonuc = validateProductImageUrlsAllowingFewerImages([]);
    expect(sonuc.ok).toBe(true);
    expect(sonuc.imageUrls).toEqual([]);
  });

  it(`${MAX_PRODUCT_IMAGES}'i aşınca yine de engel olur`, () => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", SUPABASE_URL);
    const cok = Array.from({ length: MAX_PRODUCT_IMAGES + 1 }, (_, i) => yonetilenGorsel(`${i}.jpg`));
    const sonuc = validateProductImageUrlsAllowingFewerImages(cok);
    expect(sonuc.ok).toBe(false);
    expect(sonuc.error).toContain(`en fazla ${MAX_PRODUCT_IMAGES}`);
  });

  it("Vixrex dışı bağlantıda yine engel olur", () => {
    const sonuc = validateProductImageUrlsAllowingFewerImages(["https://baska-site.com/gorsel.jpg"]);
    expect(sonuc.ok).toBe(false);
    expect(sonuc.error).toContain("Görsel ekle alanından");
  });

  it("http (https olmayan) bağlantıda engel olur", () => {
    const sonuc = validateProductImageUrlsAllowingFewerImages([
      "http://ornekproje.supabase.co/storage/v1/object/public/shelf-images/magaza-1/products/a.jpg",
    ]);
    expect(sonuc.ok).toBe(false);
  });
});
