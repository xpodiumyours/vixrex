import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";
import {
  managedProductStoragePath,
  unreferencedManagedProductStoragePaths,
} from "../src/lib/productImageCleanup";

const SUPABASE_URL = "https://project.supabase.co";
const managed = (store: string, product: string, file: string) =>
  `${SUPABASE_URL}/storage/v1/object/public/shelf-images/${store}/products/${product}/${file}`;

const routeSource = readFileSync(
  resolve(__dirname, "../src/app/api/products/route.ts"),
  "utf-8",
);

describe("ürün görseli güvenli temizlik", () => {
  it("yalnız aynı Supabase projesindeki aynı vitrin ürün dosyasını kabul eder", () => {
    expect(
      managedProductStoragePath(
        managed("magaza", "urun-1", "1.webp"),
        "magaza",
        SUPABASE_URL,
      ),
    ).toBe("magaza/products/urun-1/1.webp");

    expect(
      managedProductStoragePath(
        "https://cdn.example.com/storage/v1/object/public/shelf-images/magaza/products/urun-1/1.webp",
        "magaza",
        SUPABASE_URL,
      ),
    ).toBeNull();
    expect(
      managedProductStoragePath(
        `${SUPABASE_URL}/storage/v1/object/public/shelf-images/magaza/owner/logo.webp`,
        "magaza",
        SUPABASE_URL,
      ),
    ).toBeNull();
    expect(
      managedProductStoragePath(
        managed("baska-magaza", "urun-1", "1.webp"),
        "magaza",
        SUPABASE_URL,
      ),
    ).toBeNull();
  });

  it("başka üründe hâlâ kullanılan dosyayı silme listesine almaz", () => {
    const shared = managed("magaza", "new", "shared.webp");
    const unused = managed("magaza", "urun-1", "unused.webp");
    const result = unreferencedManagedProductStoragePaths({
      candidateUrls: [shared, unused, "https://cdn.example.com/external.webp"],
      referencedUrls: [shared],
      storeSlug: "magaza",
      supabaseUrl: SUPABASE_URL,
    });

    expect(result).toEqual(["magaza/products/urun-1/unused.webp"]);
  });

  it("ürün güncelleme ve silme bittikten sonra artık görselleri temizler", () => {
    expect(routeSource).toContain("const removedImageUrls = currentImageUrls.filter");
    expect(routeSource).toContain("deletedImageUrls = normalizeProductImageUrls");
    expect(routeSource.match(/cleanupUnreferencedProductImages\(\{/g)).toHaveLength(2);
    expect(routeSource.indexOf("await updateRichCoreProduct({")).toBeLessThan(
      routeSource.indexOf("const removedImageUrls = currentImageUrls.filter"),
    );
    expect(routeSource.indexOf('owned.admin.rpc("delete_store_product"')).toBeLessThan(
      routeSource.lastIndexOf("await cleanupUnreferencedProductImages({"),
    );
  });
});
