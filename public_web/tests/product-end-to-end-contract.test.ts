import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const ownerApp = readFileSync(resolve(__dirname, "../src/app/app/page.tsx"), "utf8");
const ownerManager = readFileSync(
  resolve(__dirname, "../src/components/owner/OwnerProductManager.tsx"),
  "utf8",
);
const publicCatalogPage = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/page.tsx"),
  "utf8",
);
const productCatalog = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/ProductCatalog.tsx"),
  "utf8",
);
const quickView = readFileSync(
  resolve(__dirname, "../src/components/ProductQuickViewBase.tsx"),
  "utf8",
);
const detailPage = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/urun/[productSlug]/PublicProductDetailPage.tsx"),
  "utf8",
);
const flutterController = readFileSync(
  resolve(__dirname, "../../lib/controllers/store_editor_controller.dart"),
  "utf8",
);
const publishService = readFileSync(
  resolve(__dirname, "../../lib/services/store_publish_service.dart"),
  "utf8",
);
const storeIdMigration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260914224500_store_id_for_edit_token.sql",
  ),
  "utf8",
);

describe("ürün veri girişi → kart → detay canlı sözleşmesi", () => {
  it("sahip ekranı zengin Product CORE alanlarını eksiksiz hydrate eder", () => {
    for (const field of [
      "price_amount",
      "old_price_amount",
      "badge_tag",
      "fulfillment_region",
      "stock_quantity",
      "brand",
      "barcode",
      "metadata",
      "variants",
      "product_template_key",
    ]) {
      expect(ownerApp, `${field} sahip sorgusunda kaybolmuş`).toContain(field);
    }
    expect(ownerManager).toContain("setEditing(product)");
  });

  it("public kart aynı zengin alanları Product CORE'dan alır", () => {
    for (const field of [
      "old_price_amount",
      "fulfillment_region",
      "stock_quantity",
      "brand",
      "barcode",
      "metadata",
      "variants",
    ]) {
      expect(publicCatalogPage, `${field} public katalog sorgusunda kaybolmuş`).toContain(field);
    }
    expect(productCatalog).toContain("productVariantLabel");
    expect(productCatalog).toContain("MapPinIcon");
    expect(productCatalog).toContain("storeLocationText");
    expect(productCatalog).toContain("fulfillmentRegion");
  });

  it("hızlı görünüm ve detay aynı metadata/varyant/stok/konum hattını kullanır", () => {
    expect(quickView).toContain("buildProductQuickFacts");
    expect(quickView).toContain("product.variants");
    expect(quickView).toContain("selectedStockQuantity");
    expect(quickView).toContain("fulfillmentRegion");
    expect(quickView).toContain("storeLocationText");

    for (const field of ["brand", "barcode", "metadata", "variants", "stock_quantity"]) {
      expect(detailPage, `${field} detay sayfasında kaybolmuş`).toContain(field);
    }
    expect(detailPage).toContain("buildProductDetailFacts");
  });

  it("ilk yayın Product CORE tamamlanmadan public başarı üretmez", () => {
    expect(publishService).toContain("_stageCatalogBeforePublish");
    expect(publishService).toContain("save_store_draft_with_token");
    expect(publishService).toContain("catalogService.syncCatalog");

    const publishStart = flutterController.indexOf("Future<String?> publish() async");
    expect(publishStart).toBeGreaterThan(-1);
    const publishBlock = flutterController.slice(publishStart);
    expect(publishBlock).toContain("publishService.publishStore");
    expect(publishBlock).not.toContain("await syncCatalogToRemote(");
  });

  it("draft store-id lookup privileged işi private şemada tutar", () => {
    expect(storeIdMigration).toContain(
      "private.get_store_id_for_edit_token_internal",
    );
    expect(storeIdMigration).toContain("security definer");
    expect(storeIdMigration).toContain("set search_path = ''");
    expect(storeIdMigration).toContain("security invoker");
    expect(storeIdMigration).toContain("to authenticated");
    expect(storeIdMigration).not.toContain(
      "grant execute on function public.get_store_id_for_edit_token(text, text)\n  to anon",
    );
  });
});
