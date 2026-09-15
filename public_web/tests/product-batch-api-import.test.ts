import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  MAX_PRODUCT_IMAGES,
  validateExternalProductImageUrls,
  validateExternalProductImageUrlsForImport,
} from "../src/lib/productImagePolicy";

const routeSource = readFileSync(
  resolve(__dirname, "../src/app/api/products/batch/route.ts"),
  "utf8",
);
const migrationSource = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260915110000_product_batch_rich_core.sql",
  ),
  "utf8",
);

describe("toplu ürün içe aktarma görsel kuralı", () => {
  it("taslak içe aktarmada 0-2 görseli kabul eder", () => {
    expect(validateExternalProductImageUrlsForImport([]).ok).toBe(true);
    expect(
      validateExternalProductImageUrlsForImport([
        "https://cdn.example.com/a.jpg",
        "https://cdn.example.com/b.jpg",
      ]).ok,
    ).toBe(true);
  });

  it("yayın kalite kuralındaki minimum 3 görseli değiştirmez", () => {
    const result = validateExternalProductImageUrls([
      "https://cdn.example.com/a.jpg",
      "https://cdn.example.com/b.jpg",
    ]);
    expect(result.ok).toBe(false);
    expect(result.error).toContain("en az 3");
  });

  it("11 üst sınırını ve URL biçimini içe aktarmada korur", () => {
    const tooMany = Array.from(
      { length: MAX_PRODUCT_IMAGES + 1 },
      (_, index) => `https://cdn.example.com/${index}.jpg`,
    );
    expect(validateExternalProductImageUrlsForImport(tooMany).ok).toBe(false);
    expect(
      validateExternalProductImageUrlsForImport(["cdn.example.com/a.jpg"]).ok,
    ).toBe(false);
  });
});

describe("toplu ürün API sözleşmesi", () => {
  it("tek hatalı satırı ayrı tutup geçerli satırları batch yoluna gönderir", () => {
    expect(routeSource).toContain("const rowErrors: BatchErrorDetail[] = []");
    expect(routeSource).toContain("const validRows:");
    expect(routeSource).toContain("rowErrors.push({ index: index + 1");
    expect(routeSource).toContain("JSON.stringify(validRows.map((row) => row.product))");
    expect(routeSource).toContain("hataDetaylari: [...rowErrors, ...mappedRpcErrors]");
  });

  it("kimlik ve zengin Product CORE alanlarını batch sözleşmesine taşır", () => {
    for (const field of [
      "external_product_id",
      "category_name",
      "stock_status",
      "stock_quantity",
      "brand",
      "barcode",
      "sku",
    ]) {
      expect(routeSource).toContain(`${field}:`);
    }
  });

  it("RPC satır hata indeksini orijinal dosya sırasına geri eşler", () => {
    expect(routeSource).toContain("validRows[rpcIndex - 1]?.originalIndex");
    expect(routeSource).toContain("original + 1");
  });

  it("eklenen/güncellenen/değişmeyen/hatalı sayaçlarını ayrı döndürür", () => {
    expect(routeSource).toContain("guncellenen: result?.updated ?? 0");
    expect(routeSource).toContain("degismeyen: result?.unchanged ?? 0");
    expect(routeSource).toContain("hatali: rowErrors.length + rpcErrorCount");
  });

  it("dosyada olmayan görünürlük ve sıralamayı yapay değerle ezmez", () => {
    expect(routeSource).toContain(
      'isVisible: typeof item.isVisible === "boolean" ? item.isVisible : undefined',
    );
    expect(routeSource).toContain(": undefined");
  });
});

describe("batch Product CORE upsert migration sözleşmesi", () => {
  it("kimliği external id -> barkod -> SKU sırasıyla arar", () => {
    const externalIndex = migrationSource.indexOf("if v_external_product_id is not null then");
    const barcodeIndex = migrationSource.indexOf("elsif v_barcode is not null then");
    const skuIndex = migrationSource.indexOf("elsif v_sku is not null then");
    expect(externalIndex).toBeGreaterThan(-1);
    expect(barcodeIndex).toBeGreaterThan(externalIndex);
    expect(skuIndex).toBeGreaterThan(barcodeIndex);
  });

  it("mevcut ürünü update_store_product_v2 ile günceller ve otomatik clear yapmaz", () => {
    expect(migrationSource).toContain("public.update_store_product_v2(");
    expect(migrationSource).toContain("p_clear_metadata => false");
    expect(migrationSource).toContain("p_clear_variants => false");
    expect(migrationSource).toContain("p_clear_barcode => false");
  });

  it("DB sonucunu dört ayrı sayaçla raporlar", () => {
    expect(migrationSource).toContain("'inserted', v_inserted_count");
    expect(migrationSource).toContain("'updated', v_updated_count");
    expect(migrationSource).toContain("'unchanged', v_unchanged_count");
    expect(migrationSource).toContain("'errors', v_error_count");
  });
});
