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
const quickViewBaseSource = readFileSync(
  resolve(__dirname, "../src/components/ProductQuickViewBase.tsx"),
  "utf-8",
);
const batchRouteSource = readFileSync(
  resolve(__dirname, "../src/app/api/products/batch/route.ts"),
  "utf-8",
);
const bulkUploadSource = readFileSync(
  resolve(__dirname, "../src/components/owner/BulkProductUpload.tsx"),
  "utf-8",
);
const parityMigrationSource = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260913154000_owner_catalog_and_bulk_rich_consistency.sql",
  ),
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
    expect(quickViewBaseSource).toContain("buildProductQuickFacts");
    expect(quickViewBaseSource).toContain("buildVariantOptionGroups");
    expect(quickViewBaseSource).toContain("productVariantsForTemplate");
    expect(quickViewBaseSource).toContain("findMatchingVariant");
    expect(quickViewBaseSource).toContain("selectedStockQuantity");
    expect(quickViewBaseSource).toContain("selectedVariant?.priceAmount");
    expect(quickViewBaseSource).toContain("Seçenek: ${selectedVariantText}");
  });

  it("hızlı inceleme seçili varyantı tam detay sayfasına taşır", () => {
    expect(quickViewSource).toContain("findMatchingVariant");
    expect(quickViewSource).toContain("?variant=${encodeURIComponent(selectedVariant.id)}");
    expect(quickViewSource).toContain('clickLocation: "product_quick_view"');
    expect(quickViewSource).toContain("trackWhatsAppClick");
    expect(quickViewSource).toContain("trackDirectionsClick");
  });

  it("owner katalogu yayınlı vitrinle aynı zengin Product CORE alanlarını taşır", () => {
    expect(parityMigrationSource).toContain("public.get_owner_catalog_for_session");
    expect(parityMigrationSource).toContain("'product_template_key', c.product_template_key");
    expect(parityMigrationSource).toContain("'stock_quantity', p.stock_quantity");
    expect(parityMigrationSource).toContain("'metadata', p.metadata");
    expect(parityMigrationSource).toContain("'variants', p.variants");
    expect(parityMigrationSource).toContain(
      "pg_catalog.encode(pg_catalog.sha256(v_token::bytea), 'hex')",
    );
  });

  it("toplu yükleme kategori ve stok verisini aynı Product CORE yazımına taşır", () => {
    expect(bulkUploadSource).toContain("MIN_PRODUCT_IMAGES");
    expect(bulkUploadSource).toContain("collectImageUrls");
    expect(bulkUploadSource).toContain("category_name: product.category || null");
    expect(bulkUploadSource).toContain("stock_status: product.stockStatus");
    expect(batchRouteSource).toContain("category_name: cleanString(p.category_name)");
    expect(batchRouteSource).toContain("stock_status: cleanString(p.stock_status)");
    expect(parityMigrationSource).toContain("public.create_store_product_v3(");
  });

  it("bilinmeyen toplu kategoriye tip uydurmaz, generic açar", () => {
    expect(parityMigrationSource).toContain("public.upsert_store_category_v2(");
    expect(parityMigrationSource).toContain("p_template_key => 'generic'");
    expect(parityMigrationSource).toContain(
      "case when v_template_key = 'service' then 'service' else 'physical' end",
    );
  });

  it("hizmet kartına fiziksel ürün sinyali taşımaz", () => {
    expect(catalogSource).toContain('const isService = metadata.itemKind === "service"');
    expect(catalogSource).toContain('brand = isService ? ""');
    expect(catalogSource).toContain('stockStatus = isService ? ""');
    expect(catalogSource).toContain('emptyLabel={isService ? "Hizmet görseli yok" : "Ürün görseli yok"}');
    expect(catalogSource).toContain("Hizmet");
  });

  it("rakip sitelerdeki doğrulanmamış güven sinyallerini taklit etmez", () => {
    const combined = `${catalogSource}\n${quickViewSource}\n${quickViewBaseSource}`;
    expect(combined).not.toContain("Kargo Bedava");
    expect(combined).not.toContain("Hızlı Teslimat");
    expect(combined).not.toContain("Ürün puanı");
  });
});
