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

  it("zengin Product CORE alanlarını batch sözleşmesine taşır", () => {
    for (const field of [
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
});
