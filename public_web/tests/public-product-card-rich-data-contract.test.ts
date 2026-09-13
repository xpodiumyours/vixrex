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
const quickViewSource = readFileSync(
  resolve(__dirname, "../src/components/ProductQuickView.tsx"),
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

  it("kart tıklamasını kategori-duyarlı hızlı incelemeye bağlar", () => {
    expect(catalogSource).toContain("ProductQuickView");
    expect(catalogSource).toContain("normalizeProductMetadata");
    expect(catalogSource).toContain("productVariantLabel(product.variants, metadata.templateKey)");
    expect(catalogSource).toContain("Hızlı incele →");
  });

  it("hızlı inceleme gerçek zengin veriyi ve seçili varyantı kullanır", () => {
    expect(quickViewSource).toContain("buildProductQuickFacts");
    expect(quickViewSource).toContain("buildVariantOptionGroups");
    expect(quickViewSource).toContain("productVariantsForTemplate");
    expect(quickViewSource).toContain("findMatchingVariant");
    expect(quickViewSource).toContain("selectedStockQuantity");
    expect(quickViewSource).toContain("selectedVariant?.priceAmount");
    expect(quickViewSource).toContain("Seçenek: ${selectedVariantText}");
  });

  it("hizmet kartına fiziksel ürün sinyali taşımaz", () => {
    expect(catalogSource).toContain('const isService = metadata.itemKind === "service"');
    expect(catalogSource).toContain('brand = isService ? ""');
    expect(catalogSource).toContain('stockStatus = isService ? ""');
    expect(catalogSource).toContain("Hizmet");
  });

  it("rakip sitelerdeki doğrulanmamış güven sinyallerini taklit etmez", () => {
    const combined = `${catalogSource}\n${quickViewSource}`;
    expect(combined).not.toContain("Kargo Bedava");
    expect(combined).not.toContain("Hızlı Teslimat");
    expect(combined).not.toContain("Ürün puanı");
  });
});