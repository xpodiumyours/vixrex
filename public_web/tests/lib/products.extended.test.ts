import { describe, it, expect } from "vitest";
import {
  safeParseJson,
  slugifyTR,
  getProductUrlSlug,
  findProductBySlug,
  deriveCollections,
  normalizeWhatsappDigits,
  normalizeExternalUrl,
  cleanInstagramCaption,
  buildInstagramProductName,
  buildInstagramProductDescription,
  type ProductItem,
} from "@/lib/products";

describe("safeParseJson", () => {
  it("returns empty array for falsy input", () => {
    expect(safeParseJson(null)).toEqual([]);
    expect(safeParseJson(undefined)).toEqual([]);
    expect(safeParseJson("")).toEqual([]);
  });

  it("passes through an array as-is", () => {
    const arr = [{ name: "Product" }];
    expect(safeParseJson(arr)).toBe(arr);
  });

  it("parses a JSON string array", () => {
    expect(safeParseJson('[{"name":"Product"}]')).toEqual([{ name: "Product" }]);
  });

  it("returns empty array for non-array JSON string", () => {
    expect(safeParseJson('{"name":"Product"}')).toEqual([]);
  });

  it("returns empty array for invalid JSON string", () => {
    expect(safeParseJson("not-json")).toEqual([]);
  });
});

describe("slugifyTR", () => {
  it("converts Turkish characters", () => {
    expect(slugifyTR("Çiğ köfte")).toBe("cig-kofte");
    expect(slugifyTR("Şişe")).toBe("sise");
    expect(slugifyTR("Üzüm")).toBe("uzum");
    expect(slugifyTR("Öğretmen")).toBe("ogretmen");
    expect(slugifyTR("Işık")).toBe("isik");
    expect(slugifyTR("Ğ")).toBe("g");
  });

  it("replaces spaces with hyphens", () => {
    expect(slugifyTR("mavi kazak")).toBe("mavi-kazak");
  });

  it("collapses multiple spaces and hyphens", () => {
    expect(slugifyTR("mavi  kazak")).toBe("mavi-kazak");
    expect(slugifyTR("mavi--kazak")).toBe("mavi-kazak");
  });

  it("strips leading and trailing hyphens", () => {
    expect(slugifyTR("- test -")).toBe("test");
  });

  it("removes non-alphanumeric characters", () => {
    expect(slugifyTR("hello!@#world")).toBe("helloworld");
  });

  it("returns empty string for blank input", () => {
    expect(slugifyTR("   ")).toBe("");
  });
});

describe("getProductUrlSlug", () => {
  it("uses explicit slug when set", () => {
    const product: ProductItem = { name: "Test Product", slug: "my-custom-slug" };
    expect(getProductUrlSlug(product, 0)).toBe("my-custom-slug");
  });

  it("derives slug from name + id when no explicit slug", () => {
    const product: ProductItem = { name: "Mavi Kazak", id: "abc" };
    expect(getProductUrlSlug(product, 0)).toBe("mavi-kazak-abc");
  });

  it("uses name + index+1 when no id or explicit slug", () => {
    const product: ProductItem = { name: "Kırmızı Gömlek" };
    expect(getProductUrlSlug(product, 2)).toBe("kirmizi-gomlek-3");
  });

  it("falls back to urun-N for empty name", () => {
    const product: ProductItem = { name: "" };
    expect(getProductUrlSlug(product, 0)).toBe("urun-1");
  });
});

describe("findProductBySlug", () => {
  const products: ProductItem[] = [
    { name: "Mavi Kazak", slug: "mavi-kazak" },
    { name: "Kırmızı Kazak", slug: "kirmizi-kazak" },
    { name: "No Slug Item" },
  ];

  it("finds a product by its exact slug", () => {
    const found = findProductBySlug(products, "mavi-kazak");
    expect(found?.name).toBe("Mavi Kazak");
  });

  it("normalizes Turkish chars in the search slug", () => {
    const found = findProductBySlug(products, "kırmızı-kazak");
    expect(found?.name).toBe("Kırmızı Kazak");
  });

  it("returns undefined when not found", () => {
    expect(findProductBySlug(products, "non-existent")).toBeUndefined();
  });
});

describe("deriveCollections", () => {
  const products: ProductItem[] = [
    { name: "A", category: "Elektronik" },
    { name: "B", category: "Elektronik" },
    { name: "C", category: "Giyim" },
    { name: "D", category: "Tümü" },
    { name: "E", category: "" },
    { name: "F", category: "Kitap" },
  ];

  it("counts categories correctly", () => {
    const collections = deriveCollections(products);
    const elektronik = collections.find((c) => c.name === "Elektronik");
    expect(elektronik?.count).toBe(2);
  });

  it("excludes Tümü and empty categories", () => {
    const collections = deriveCollections(products);
    const names = collections.map((c) => c.name);
    expect(names).not.toContain("Tümü");
    expect(names).not.toContain("");
  });

  it("sorts by count descending", () => {
    const collections = deriveCollections(products);
    expect(collections[0].name).toBe("Elektronik");
  });

  it("respects limit parameter", () => {
    expect(deriveCollections(products, 1)).toHaveLength(1);
  });
});

describe("normalizeWhatsappDigits", () => {
  it("converts 10-digit number starting with 5 to 90 prefix", () => {
    expect(normalizeWhatsappDigits("5321234567")).toBe("905321234567");
  });

  it("converts 11-digit number starting with 0 to 90 prefix", () => {
    expect(normalizeWhatsappDigits("05321234567")).toBe("905321234567");
  });

  it("passes through a number already starting with 90", () => {
    expect(normalizeWhatsappDigits("905321234567")).toBe("905321234567");
  });

  it("strips formatting characters", () => {
    expect(normalizeWhatsappDigits("+90 (532) 123-45-67")).toBe("905321234567");
  });

  it("returns empty string for empty input", () => {
    expect(normalizeWhatsappDigits("")).toBe("");
  });
});

describe("normalizeExternalUrl", () => {
  it("returns null for empty input", () => {
    expect(normalizeExternalUrl("")).toBeNull();
    expect(normalizeExternalUrl(null)).toBeNull();
  });

  it("passes through URLs starting with http", () => {
    expect(normalizeExternalUrl("https://example.com")).toBe("https://example.com");
  });

  it("prepends https:// for bare domains", () => {
    expect(normalizeExternalUrl("example.com")).toBe("https://example.com");
  });
});

describe("cleanInstagramCaption", () => {
  it("removes hashtags", () => {
    expect(cleanInstagramCaption("New arrival #fashion #trend")).toBe("New arrival");
  });

  it("collapses extra whitespace", () => {
    expect(cleanInstagramCaption("hello   world")).toBe("hello world");
  });

  it("handles empty captions", () => {
    expect(cleanInstagramCaption("")).toBe("");
  });
});

describe("buildInstagramProductName", () => {
  it("extracts the first non-empty line", () => {
    expect(buildInstagramProductName("Mavi kazak\nFabulous product #tag")).toBe("Mavi kazak");
  });

  it("truncates long first lines to 72 chars", () => {
    const longLine = "A".repeat(80);
    const result = buildInstagramProductName(longLine);
    expect(result.endsWith("...")).toBe(true);
    expect(result.length).toBeLessThanOrEqual(72);
  });

  it("returns fallback for empty captions", () => {
    expect(buildInstagramProductName("   ")).toBe("Instagram ürünü");
    expect(buildInstagramProductName("", "Özel ürün")).toBe("Özel ürün");
  });

  it("skips lines that become empty after cleaning hashtags", () => {
    expect(buildInstagramProductName("#skipped\nActual product")).toBe("Actual product");
  });
});

describe("buildInstagramProductDescription", () => {
  it("uses cleaned caption when it is long enough (>=40 chars)", () => {
    const caption = "Bu ürün çok kaliteli ve dayanıklı bir kazak. #fashion";
    const result = buildInstagramProductDescription({
      caption,
      storeName: "Mağaza",
      productName: "Kazak",
    });
    expect(result).not.toContain("WhatsApp");
    expect(result).not.toContain("#fashion");
  });

  it("falls back to generated description for short captions", () => {
    const result = buildInstagramProductDescription({
      caption: "Çok güzel",
      storeName: "My Store",
      productName: "Kazak",
    });
    expect(result).toContain("My Store");
    expect(result).toContain("WhatsApp");
  });
});
