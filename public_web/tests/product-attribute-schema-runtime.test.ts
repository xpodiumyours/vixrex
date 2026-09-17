import { describe, expect, it } from "vitest";
import {
  PRODUCT_ATTRIBUTE_SCHEMA,
  productAttributesForSurface,
  productAttributesForTemplate,
  productTemplateByKey,
} from "../src/lib/productAttributeSchema";

const CATEGORY_FIELD_CASES: Array<[string, string[]]> = [
  ["fashion", ["color", "size", "material"]],
  ["electronics", ["model", "ram", "storageCapacity"]],
  ["beauty", ["shade", "netQuantity", "ingredients"]],
  ["food", ["netQuantity", "ingredients", "allergens"]],
  ["home", ["material", "width", "height", "depth"]],
  ["automotive", ["partNumber", "compatibleMake", "compatibleModel"]],
];

describe("ürün özellik şeması — runtime adapter", () => {
  it("shared şemayı tek kaynak olarak sürüm 3 ile okur", () => {
    expect(PRODUCT_ATTRIBUTE_SCHEMA.version).toBe(3);
    expect(PRODUCT_ATTRIBUTE_SCHEMA.templates.map((item) => item.key)).toEqual([
      "generic",
      "fashion",
      "electronics",
      "beauty",
      "food",
      "home",
      "automotive",
      "service",
    ]);
  });

  it("fiziksel şablonlarda ortak alanları ve KDV'yi korur", () => {
    const keys = productAttributesForTemplate("fashion").map((field) => field.key);
    expect(keys).toContain("brand");
    expect(keys).toContain("barcode");
    expect(keys).toContain("sku");
    expect(keys).toContain("vatRate");
    expect(keys).toContain("size");
    expect(keys).toContain("color");
  });

  it.each(CATEGORY_FIELD_CASES)(
    "%s kategorisinin ayırt edici ürün alanlarını korur",
    (templateKey, requiredKeys) => {
      const keys = productAttributesForTemplate(templateKey).map((field) => field.key);
      for (const key of requiredKeys) expect(keys).toContain(key);
    },
  );

  it("hizmet şablonuna fiziksel barkod/marka/KDV alanlarını karıştırmaz", () => {
    const keys = productAttributesForTemplate("service").map((field) => field.key);
    expect(keys).toContain("serviceType");
    expect(keys).toContain("priceMode");
    expect(keys).toContain("serviceLocation");
    expect(keys).not.toContain("barcode");
    expect(keys).not.toContain("brand");
    expect(keys).not.toContain("vatRate");
  });

  it("yüzeye göre bilgi yoğunluğunu şemadan filtreler", () => {
    const quick = productAttributesForSurface("electronics", "quick").map((field) => field.key);
    const detail = productAttributesForSurface("electronics", "detail").map((field) => field.key);
    expect(quick).toContain("brand");
    expect(quick).not.toContain("barcode");
    expect(detail).toContain("barcode");
    expect(detail).toContain("compatibility");
    expect(detail).toContain("vatRate");
  });

  it("boş şablonu generic kabul eder ama bilinmeyen şablonu tahmin etmez", () => {
    expect(productTemplateByKey(null)?.key).toBe("generic");
    expect(productTemplateByKey("")?.key).toBe("generic");
    expect(productTemplateByKey("aksesuar-ne-demek-belli-degil")).toBeNull();
  });
});
