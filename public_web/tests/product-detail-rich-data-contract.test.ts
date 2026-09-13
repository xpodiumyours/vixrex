import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const source = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/urun/[productSlug]/page.tsx"),
  "utf8",
);

describe("ürün detay — zengin veri okuma sözleşmesi", () => {
  it("mevcut products çekirdeğindeki zengin kolonları okur", () => {
    for (const field of [
      "price_amount",
      "currency",
      "stock_quantity",
      "brand",
      "barcode",
      "metadata",
      "variants",
      "seo_title",
      "seo_description",
    ]) {
      expect(source).toContain(field);
    }
  });

  it("marka yokken işletme adını ürün markası diye üretmez", () => {
    expect(source).toContain("brand: product.brand");
    expect(source).not.toMatch(/brand:\s*\{[\s\S]{0,120}name:\s*store\.name/);
  });

  it("yapılandırılmış fiyat için numeric price_amount alanını önceliklendirir", () => {
    expect(source).toContain("product.priceAmount != null");
    expect(source).toContain("priceCurrency: product.currency || \"TRY\"");
  });

  it("stok adedi sıfırsa ürünü stokta saymaz", () => {
    expect(source).toContain("product.stockQuantity == null || product.stockQuantity > 0");
  });
});
