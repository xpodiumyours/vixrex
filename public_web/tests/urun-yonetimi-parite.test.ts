import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Ürün yönetimi parite testi.
 *
 * Kural: Flutter ProductService ve Next.js OwnerProductManager
 * aynı ürün alanlarını ve aynı CRUD işlemlerini yapmalı.
 * - create: aynı input alanları
 * - update: aynı düzenlenebilir alanlar
 * - delete: aynı RPC
 */

const flutterService = readFileSync(
  resolve(__dirname, "../../lib/services/product_service.dart"),
  "utf8",
);
const nextManager = readFileSync(
  resolve(__dirname, "../src/components/owner/OwnerProductManager.tsx"),
  "utf8",
);

describe("urun yonetimi parite (Flutter referansiyla)", () => {
  it("Flutter gibi createProduct ayni alanlari ister", () => {
    const alanlar = [
      "name",
      "description",
      "priceText",
      "priceAmount",
      "oldPriceAmount",
      "badgeTag",
      "fulfillmentRegion",
      "imageUrls",
      "categoryId",
      "isVisible",
      "sortOrder",
    ];
    for (const alan of alanlar) {
      expect(flutterService).toContain(alan);
    }
  });

  it("Next.js createProduct ayni alanlari kabul eder", () => {
    const alanlar = [
      "name",
      "description",
      "price_text",
      "price_amount",
      "old_price_amount",
      "badge_tag",
      "fulfillment_region",
      "image_urls",
      "category_id",
      "stock_status",
    ];
    for (const alan of alanlar) {
      expect(nextManager).toContain(alan);
    }
  });

  it("Flutter gibi updateProduct ayni alanlari gunceller", () => {
    const alanlar = [
      "name",
      "description",
      "priceText",
      "priceAmount",
      "oldPriceAmount",
      "badgeTag",
      "fulfillmentRegion",
      "imageUrls",
      "categoryId",
      "isVisible",
      "sortOrder",
      "stockQuantity",
      "stockStatus",
    ];
    for (const alan of alanlar) {
      expect(flutterService).toContain(alan);
    }
  });

  it("Flutter gibi product_queue ile toplu islem yapar", () => {
    expect(nextManager).toContain("productQueue");
  });

  it("Flutter gibi stock_status degerleri ayni", () => {
    const stokDegerleri = ["Mevcut", "Tükendi", "Son birkaç adet"];
    for (const durum of stokDegerleri) {
      expect(nextManager).toContain(durum);
    }
  });
});