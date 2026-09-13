import { describe, expect, it } from "vitest";
import {
  PRODUCT_ATTRIBUTE_SCHEMA,
  productAttributesForSurface,
  productAttributesForTemplate,
  productTemplateByKey,
} from "../src/lib/productAttributeSchema";

describe("ürün özellik şeması — runtime adapter", () => {
  it("shared şemayı tek kaynak olarak okur", () => {
    expect(PRODUCT_ATTRIBUTE_SCHEMA.version).toBe(1);
    expect(PRODUCT_ATTRIBUTE_SCHEMA.templates.length).toBeGreaterThan(1);
  });

  it("fiziksel şablona ortak fiziksel alanları ekler", () => {
    const keys = productAttributesForTemplate("fashion").map((field) => field.key);
    expect(keys).toContain("brand");
    expect(keys).toContain("barcode");
    expect(keys).toContain("size");
    expect(keys).toContain("color");
  });

  it("hizmet şablonuna fiziksel barkod/marka alanlarını karıştırmaz", () => {
    const keys = productAttributesForTemplate("service").map((field) => field.key);
    expect(keys).toContain("serviceType");
    expect(keys).toContain("serviceLocation");
    expect(keys).not.toContain("barcode");
    expect(keys).not.toContain("brand");
  });

  it("yüzeye göre bilgi yoğunluğunu şemadan filtreler", () => {
    const quick = productAttributesForSurface("electronics", "quick").map((field) => field.key);
    const detail = productAttributesForSurface("electronics", "detail").map((field) => field.key);
    expect(quick).toContain("brand");
    expect(quick).not.toContain("barcode");
    expect(detail).toContain("barcode");
    expect(detail).toContain("compatibility");
  });

  it("bilinmeyen şablonu sessizce başka kategoriye tahmin etmez", () => {
    expect(productTemplateByKey("aksesuar-ne-demek-belli-degil")).toBeNull();
  });
});
