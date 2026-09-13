import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

function read(path: string) {
  return readFileSync(resolve(__dirname, "..", path), "utf8");
}

const ownerPage = read("src/app/app/urunler/page.tsx");
const ownerDetails = read("src/components/owner/OwnerRichProductDetails.tsx");
const publicRoute = read("src/app/api/public-product-rich/route.ts");
const catalog = read("src/app/v/[slug]/ProductCatalog.tsx");
const detail = read("src/app/v/[slug]/urun/[productSlug]/page.tsx");

describe("zengin ürün uçtan uca UI veri akışı", () => {
  it("owner ürün ekranı canlı products çekirdeğindeki zengin alanları okur", () => {
    for (const field of [
      "price_amount",
      "stock_quantity",
      "brand",
      "barcode",
      "vat_rate",
      "metadata",
      "variants",
    ]) {
      expect(ownerPage).toContain(field);
    }
    expect(ownerPage).toContain("OwnerRichProductDetails");
  });

  it("esnaf ürün tipini açıkça seçer; kategori adından profil tahmini yapılmaz", () => {
    expect(ownerDetails).toContain("Ürün tipi seç");
    expect(ownerDetails).toContain("PRODUCT_ATTRIBUTE_SCHEMA.profiles");
    expect(ownerDetails).not.toContain("category.toLowerCase");
    expect(ownerDetails).not.toContain("kategori.toLowerCase");
  });

  it("hızlı görünüm zengin veriyi yalnız yayınlı ve görünür üründen okur", () => {
    expect(publicRoute).toContain('.eq("is_published", true)');
    expect(publicRoute).toContain('.eq("is_active", true)');
    expect(publicRoute).toContain('.eq("is_visible", true)');
    expect(catalog).toContain("QuickProductRichFacts");
  });

  it("detay sayfası gerçek marka ve sayısal fiyatı yapılandırılmış veride kullanır", () => {
    expect(detail).toContain("brand: product.brand");
    expect(detail).toContain("name: product.brand");
    expect(detail).toContain("price: product.priceAmount");
    expect(detail).toContain('"@type": "Service"');
    expect(detail).toContain("normalizeProductVariants");
  });
});
