import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const core = readFileSync(resolve(__dirname, "../src/lib/productCoreServer.ts"), "utf8");
const route = readFileSync(resolve(__dirname, "../src/app/api/products/route.ts"), "utf8");

describe("zengin ürün yazma güvenlik sözleşmesi", () => {
  it("mevcut Product CORE RPC'lerini korur", () => {
    expect(core).toContain('rpc("create_store_product_v2"');
    expect(core).toContain('rpc("update_store_product"');
    expect(core).not.toContain("create_store_product_v3");
  });

  it("zengin alanları yalnız ürün + mağaza eşleşmesine yazar", () => {
    expect(core).toContain('.eq("id", args.productId)');
    expect(core).toContain('.eq("store_id", args.storeId)');
    expect(core).toContain('import "server-only"');
  });

  it("owner API profil, sayı, boyut ve varyant doğrulaması yapar", () => {
    expect(route).toContain("isProductProfileKey");
    expect(route).toContain("normalizeProductMetadata");
    expect(route).toContain("normalizeProductVariants");
    expect(route).toContain("20000");
    expect(route).toContain("50000");
    expect(route).toContain("stockQuantity");
    expect(route).toContain("vatRate");
  });

  it("eski basit ürün formu zengin alanları veya sayısal fiyatı sessizce temizlemez", () => {
    expect(route).toContain("if (!hasRichPayload) return undefined");
    expect(route).toContain('hasOwn(body, "priceAmount")');
    expect(core).toContain("if (args.priceAmount !== undefined)");
    expect(core).toContain("args.priceAmount === null");
  });
});
