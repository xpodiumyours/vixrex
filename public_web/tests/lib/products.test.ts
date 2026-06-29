import { describe, expect, it } from "vitest";
import { retainManualProducts, type ProductItem } from "@/lib/products";

describe("retainManualProducts", () => {
  it("removes products imported from Instagram", () => {
    const products: ProductItem[] = [
      { slug: "ig-1", name: "Instagram ürün", source: "instagram" },
      { slug: "manual-1", name: "Manuel ürün", source: "manual" },
    ];

    expect(retainManualProducts(products)).toEqual([
      { slug: "manual-1", name: "Manuel ürün", source: "manual" },
    ]);
  });

  it("removes products whose slugs match imported records", () => {
    const products: ProductItem[] = [
      { slug: "manual-1", name: "Manuel ürün", source: "manual" },
      { slug: "manual-2", name: "Kalan ürün", source: "manual" },
    ];

    expect(retainManualProducts(products, ["manual-1"])).toEqual([
      { slug: "manual-2", name: "Kalan ürün", source: "manual" },
    ]);
  });

  it("keeps products without slugs when imported slugs are filtered", () => {
    const products: ProductItem[] = [
      { name: "Slug yok", source: "manual" },
      { slug: "manual-1", name: "Silinecek ürün", source: "manual" },
    ];

    expect(retainManualProducts(products, ["manual-1"])).toEqual([
      { name: "Slug yok", source: "manual" },
    ]);
  });
});
