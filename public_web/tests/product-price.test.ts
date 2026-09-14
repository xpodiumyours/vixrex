import { describe, expect, it } from "vitest";
import { parseProductPriceNumber, parseProductPriceString } from "../src/lib/productPrice";

describe("product price parser", () => {
  it("Türkçe binlik ve ondalık fiyatları tek kuralla ayrıştırır", () => {
    expect(parseProductPriceNumber("1.299 TL")).toBe(1299);
    expect(parseProductPriceNumber("1.299,90 TL")).toBe(1299.9);
    expect(parseProductPriceNumber("1299,90 TL")).toBe(1299.9);
    expect(parseProductPriceNumber("1299.90")).toBe(1299.9);
    expect(parseProductPriceNumber("12.345")).toBe(12345);
  });

  it("geçersiz veya boş fiyatı üretmez", () => {
    expect(parseProductPriceNumber("")).toBeNull();
    expect(parseProductPriceNumber("fiyat yok")).toBeNull();
    expect(parseProductPriceString("fiyat yok")).toBeUndefined();
  });
});
