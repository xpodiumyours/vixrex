import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const routeSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/urun/[productSlug]/page.tsx"),
  "utf8",
);
const source = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/urun/[productSlug]/PublicProductDetailPage.tsx"),
  "utf8",
);
const ownerSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/urun/[productSlug]/OwnerProductDetailPreview.tsx"),
  "utf8",
);
const experienceSource = readFileSync(
  resolve(__dirname, "../src/components/ProductDetailExperience.tsx"),
  "utf8",
);
const experienceBaseSource = readFileSync(
  resolve(__dirname, "../src/components/ProductDetailExperienceBase.tsx"),
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
    expect(experienceBaseSource).toContain("buildVariantOptionGroups");
    expect(experienceBaseSource).toContain("productVariantsForTemplate");
    expect(experienceBaseSource).toContain("findMatchingVariant");
    expect(experienceBaseSource).toContain("metadata.templateKey");
  });

  it("seçili varyant fiyat stok görsel ve WhatsApp bilgisini birlikte değiştirir", () => {
    expect(experienceBaseSource).toContain("selectedVariant?.priceAmount");
    expect(experienceBaseSource).toContain("selectedVariant?.stockQuantity");
    expect(experienceBaseSource).toContain("selectedVariant?.imageUrls");
    expect(experienceBaseSource).toContain("selectedWhatsappUrl");
    expect(experienceBaseSource).toContain("Seçenek: ${selectedVariantText}");
  });

  it("hızlı incelemeden gelen varyant seçimini ilk detay seçimi olarak açar", () => {
    expect(experienceSource).toContain('searchParams.get("variant")');
    expect(experienceSource).toContain("normalizeProductVariants");
    expect(experienceSource).toContain("variants.findIndex");
    expect(experienceSource).toContain("[selected, ...variants.filter");
  });

  it("ürün konumu/yol tarifi tıklamasını Vixrex ölçümüne ürün bağlamıyla taşır", () => {
    expect(experienceSource).toContain("trackDirectionsClick");
    expect(experienceSource).toContain('clickLocation: "product_detail"');
    expect(experienceSource).toContain("productSlug: props.productSlug");
  });

  it("yayınlanmamış sahip ürün detayını public RLS'yi gevşetmeden açar", () => {
    expect(routeSource).toContain("OwnerProductDetailPreview");
    expect(routeSource).toContain("PublicProductDetailPage");
    expect(ownerSource).toContain("verifyOwnerSession");
    expect(ownerSource).toContain('supabase.rpc("get_working_draft_for_session"');
    expect(ownerSource).toContain('supabase.rpc("get_owner_catalog_for_session"');
    expect(ownerSource).toContain('data-vixrex-owner-preview="true"');
    expect(ownerSource).not.toContain("getSupabaseAdmin");
  });

  it("hizmeti Product olarak işaretlemez ve fiziksel ürün alanlarını istemciye taşımaz", () => {
    expect(source).toContain('"@type": "Service"');
    expect(source).toContain('"@type": "Product"');
    expect(source).toContain("serviceType: metadata.service?.serviceType");
    expect(source).toContain("areaServed: product.fulfillmentRegion");
    expect(experienceBaseSource).toContain("!isService && groups.length > 0");
    expect(experienceBaseSource).toContain("!isService && (stockStatus || stockQuantity != null)");
    expect(experienceBaseSource).toContain("WhatsApp’tan hizmeti sor");
  });
});