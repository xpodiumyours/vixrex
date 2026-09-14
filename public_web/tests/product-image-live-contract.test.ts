import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";
import { MAX_PRODUCT_IMAGES, MIN_PRODUCT_IMAGES } from "../src/lib/productImagePolicy";

const migrationSource = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260914175500_product_image_limit_11.sql",
  ),
  "utf-8",
);
const bulkUploadSource = readFileSync(
  resolve(__dirname, "../src/components/owner/BulkProductUpload.tsx"),
  "utf-8",
);
const productRichDataSource = readFileSync(
  resolve(__dirname, "../src/lib/productRichData.ts"),
  "utf-8",
);
const flutterPolicySource = readFileSync(
  resolve(__dirname, "../../lib/services/product_image_policy.dart"),
  "utf-8",
);

describe("ürün fotoğrafı canlı sözleşmesi", () => {
  it("Web, Flutter ve veritabanı 3-11 sınırında eşittir", () => {
    expect(MIN_PRODUCT_IMAGES).toBe(3);
    expect(MAX_PRODUCT_IMAGES).toBe(11);
    expect(flutterPolicySource).toContain("static const int minImages = 3;");
    expect(flutterPolicySource).toContain("static const int maxImages = 11;");
    expect(migrationSource).toContain("if image_count < 3 then");
    expect(migrationSource).toContain("if image_count > 11 then");
    expect(migrationSource).toContain("PRODUCT_IMAGES_MAX_11");
    expect(migrationSource).not.toContain("PRODUCT_IMAGES_MAX_10");
  });

  it("toplu yükleme ortak fotoğraf sınırını kullanır", () => {
    expect(bulkUploadSource).toContain("MAX_PRODUCT_IMAGES");
    expect(bulkUploadSource).toContain("MIN_PRODUCT_IMAGES");
    expect(bulkUploadSource).not.toContain("slice(0, 10)");
  });

  it("varyant görselleri ortak fotoğraf sınırını kullanır", () => {
    expect(productRichDataSource).toContain("MAX_PRODUCT_IMAGES");
    expect(productRichDataSource).toContain("cleanStringArray(variant.imageUrls, MAX_PRODUCT_IMAGES)");
  });
});
