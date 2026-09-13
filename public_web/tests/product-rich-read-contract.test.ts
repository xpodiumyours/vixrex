import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const schema = JSON.parse(
  readFileSync(resolve(__dirname, "../../shared/product_attribute_schema.json"), "utf8"),
) as { version: number; profiles: Array<{ key: string }>; fields: Record<string, unknown> };
const model = readFileSync(resolve(__dirname, "../../lib/models/store_product.dart"), "utf8");
const repo = readFileSync(
  resolve(__dirname, "../../lib/repositories/supabase_product_repository.dart"),
  "utf8",
);

describe("zengin ürün okuma sözleşmesi", () => {
  it("ortak ürün profillerini ve temel zengin alanları tanımlar", () => {
    expect(schema.version).toBe(1);
    expect(schema.profiles.map((item) => item.key)).toEqual(
      expect.arrayContaining(["general_product", "apparel", "electronics", "beauty", "food", "home", "auto_part", "service"]),
    );
    expect(schema.fields).toHaveProperty("brand");
    expect(schema.fields).toHaveProperty("barcode");
    expect(schema.fields).toHaveProperty("duration_minutes");
  });

  it("Flutter modeli ve Supabase okuyucusu zengin alanları kaybetmez", () => {
    for (const token of ["priceAmount", "stockQuantity", "brand", "barcode", "sku", "vatRate", "variants", "metadata"]) {
      expect(model).toContain(token);
    }
    for (const column of ["price_amount", "stock_quantity", "brand", "barcode", "vat_rate", "variants", "metadata"]) {
      expect(repo).toContain(`row['${column}']`);
    }
  });

  it("bu aşamada mevcut yazma sözleşmesini değiştirmez", () => {
    expect(repo).toContain("'create_store_product_v2'");
    expect(repo).toContain("'update_store_product'");
    expect(repo).not.toContain("create_store_product_v3");
  });
});
