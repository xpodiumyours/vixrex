import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";
import {
  normalizeProductMetadata,
  normalizeProductVariants,
  productIsService,
} from "../src/lib/productRichData";

interface AttributeDefinition {
  key: string;
  label: string;
  valueType: string;
  requirement: string;
  storage: string;
  display: string[];
  variantEligible?: boolean;
}

interface TemplateDefinition {
  key: string;
  label: string;
  itemKind: string;
  attributes: AttributeDefinition[];
}

interface SchemaDefinition {
  version: number;
  itemKinds: string[];
  requirements: string[];
  valueTypes: string[];
  commonPhysicalAttributes: AttributeDefinition[];
  commonServiceAttributes: AttributeDefinition[];
  templates: TemplateDefinition[];
}

const schema = JSON.parse(
  readFileSync(resolve(__dirname, "../../shared/product_attribute_schema.json"), "utf-8"),
) as SchemaDefinition;
const ownerManagerSource = readFileSync(
  resolve(__dirname, "../src/components/owner/OwnerProductManager.tsx"),
  "utf-8",
);
const ownerRichSource = readFileSync(
  resolve(__dirname, "../src/components/owner/OwnerRichProductFields.tsx"),
  "utf-8",
);
const productRouteSource = readFileSync(
  resolve(__dirname, "../src/app/api/products/route.ts"),
  "utf-8",
);

describe("zengin ürün şeması — sözleşme", () => {
  it("fiziksel ürün ve hizmet ayrımını taşır", () => {
    expect(new Set(schema.itemKinds)).toEqual(new Set(["physical", "service"]));
    expect(schema.templates.some((template) => template.itemKind === "physical")).toBe(true);
    expect(schema.templates.some((template) => template.itemKind === "service")).toBe(true);
  });

  it("şablon anahtarları benzersizdir", () => {
    const keys = schema.templates.map((template) => template.key);
    expect(new Set(keys).size).toBe(keys.length);
  });

  it("her özellik tanımlı tip, gereklilik ve görünüm yüzeyi kullanır", () => {
    const all = [
      ...schema.commonPhysicalAttributes,
      ...schema.commonServiceAttributes,
      ...schema.templates.flatMap((template) => template.attributes),
    ];
    for (const attribute of all) {
      expect(attribute.key.trim().length).toBeGreaterThan(0);
      expect(attribute.label.trim().length).toBeGreaterThan(0);
      expect(schema.valueTypes).toContain(attribute.valueType);
      expect(schema.requirements).toContain(attribute.requirement);
      expect(attribute.storage.trim().length).toBeGreaterThan(0);
      expect(attribute.display.length).toBeGreaterThan(0);
      for (const surface of attribute.display) {
        expect(["card", "quick", "detail"]).toContain(surface);
      }
    }
  });

  it("belirsiz kategori adlarını otomatik ürün tipine çevirecek mapping içermez", () => {
    expect((schema as unknown as { categoryMappings?: unknown }).categoryMappings).toBeUndefined();
  });
});

describe("zengin ürün verisi — güvenli okuma", () => {
  it("eski ürünlerde boş metadata ve varyantlar sorunsuz kalır", () => {
    expect(normalizeProductMetadata(null)).toEqual({});
    expect(normalizeProductVariants(null)).toEqual([]);
    expect(productIsService(null)).toBe(false);
  });

  it("hizmet metadata'sını normalize eder", () => {
    const value = normalizeProductMetadata({
      schemaVersion: 1,
      itemKind: "service",
      templateKey: "service",
      service: {
        serviceType: "Telefon ekran değişimi",
        priceMode: "starting_from",
        durationMinutes: 60,
        serviceLocation: "business",
        appointmentRequired: true,
        included: ["Parça", "İşçilik"],
      },
    });
    expect(value.itemKind).toBe("service");
    expect(value.service?.durationMinutes).toBe(60);
    expect(value.service?.included).toEqual(["Parça", "İşçilik"]);
  });

  it("geçersiz varyantları atar ve geçerli varyant alanlarını korur", () => {
    const variants = normalizeProductVariants([
      { id: "", options: { color: "Siyah" } },
      { id: "v1", options: {} },
      {
        id: "v2",
        options: { color: "Siyah", size: "M" },
        priceAmount: 499,
        stockQuantity: 3,
        imageUrls: ["https://cdn.example.com/1.webp"],
      },
    ]);
    expect(variants).toHaveLength(1);
    expect(variants[0]).toMatchObject({
      id: "v2",
      options: { color: "Siyah", size: "M" },
      priceAmount: 499,
      stockQuantity: 3,
    });
  });

  it("varyant fotoğrafını ayrı medya kaynağına dönüştürmez", () => {
    expect(ownerManagerSource).toContain("imageUrls={imageUrls}");
    expect(ownerRichSource).toContain("availableImages.has(url)");
    expect(ownerRichSource).toContain("Varyant fotoğrafları");
    expect(productRouteSource).toContain("productImageUrls: string[]");
    expect(productRouteSource).toContain("availableImages.has(url)");
    expect(productRouteSource).toContain("imageValidation.imageUrls");
  });
});
