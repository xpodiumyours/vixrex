import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const pageSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/page.tsx"),
  "utf-8",
);
const catalogSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/ProductCatalog.tsx"),
  "utf-8",
);

describe("public ürün kartı zengin veri hattı", () => {
  it("aynı products sorgusundan zengin alanları okur", () => {
    for (const field of [
      "stock_quantity",
      "brand",
      "barcode",
      "metadata",
      "variants",
    ]) {
      expect(pageSource).toContain(field);
    }
  });

  it("zengin alanları visibleProducts üzerinden karta taşır", () => {
    for (const mapping of [
      "stockQuantity:",
      "brand:",
      "barcode:",
      "metadata:",
      "variants:",
    ]) {
      expect(pageSource).toContain(mapping);
    }
  });

  it("kart ve hızlı görünüm yalnız ortak sunum yardımcılarını kullanır", () => {
    expect(catalogSource).toContain("buildProductQuickFacts");
    expect(catalogSource).toContain("productVariantLabel");
    expect(catalogSource).toContain("product.brand");
    expect(catalogSource).toContain("product.stockQuantity");
  });

  it("rakip sitelerdeki doğrulanmamış güven sinyallerini taklit etmez", () => {
    expect(catalogSource).not.toContain("Kargo Bedava");
    expect(catalogSource).not.toContain("Hızlı Teslimat");
    expect(catalogSource).not.toContain("Ürün puanı");
  });
});
