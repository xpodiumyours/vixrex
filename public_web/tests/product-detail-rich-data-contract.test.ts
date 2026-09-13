import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const source = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/urun/[productSlug]/page.tsx"),
  "utf8",
);
const experienceSource = readFileSync(
  resolve(__dirname, "../src/components/ProductDetailExperience.tsx"),
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

  it("stok adedi sıfırsa fiziksel ürünü stokta saymaz", () => {
    expect(source).toContain("product.stockQuantity == null || product.stockQuantity > 0");
    expect(source).toContain("!isService");
  });

  it("kategoriye ait gerçek detayları serverdan interaktif detay bileşenine taşır", () => {
    expect(source).toContain("buildProductDetailFacts");
    expect(source).toContain("ProductDetailExperience");
    expect(source).toContain("detailFacts={detailFacts}");
    expect(experienceSource).toContain("buildVariantOptionGroups");
    expect(experienceSource).toContain("productVariantsForTemplate");
    expect(experienceSource).toContain("findMatchingVariant");
    expect(experienceSource).toContain("metadata.templateKey");
  });

  it("seçili varyant fiyat stok görsel ve WhatsApp bilgisini birlikte değiştirir", () => {
    expect(experienceSource).toContain("selectedVariant?.priceAmount");
    expect(experienceSource).toContain("selectedVariant?.stockQuantity");
    expect(experienceSource).toContain("selectedVariant?.imageUrls");
    expect(experienceSource).toContain("selectedWhatsappUrl");
    expect(experienceSource).toContain("Seçenek: ${selectedVariantText}");
  });

  it("hizmeti Product olarak işaretlemez ve fiziksel ürün alanlarını istemciye taşımaz", () => {
    expect(source).toContain('"@type": "Service"');
    expect(source).toContain('"@type": "Product"');
    expect(source).toContain("serviceType: metadata.service?.serviceType");
    expect(source).toContain("areaServed: product.fulfillmentRegion");
    expect(experienceSource).toContain("!isService && groups.length > 0");
    expect(experienceSource).toContain("!isService && (stockStatus || stockQuantity != null)");
    expect(experienceSource).toContain("WhatsApp’tan hizmeti sor");
  });
});