import schemaJson from "../../../shared/product_attribute_schema.json";

export type ProductItemKind = "physical" | "service";
export type ProductAttributeRequirement = "optional" | "recommended";
export type ProductAttributeValueType = "text" | "number" | "boolean" | "single" | "multi";
export type ProductAttributeSurface = "card" | "quick" | "detail";

export interface ProductAttributeDefinition {
  key: string;
  label: string;
  valueType: ProductAttributeValueType;
  requirement: ProductAttributeRequirement;
  storage: string;
  options?: string[];
  variantEligible?: boolean;
  display: ProductAttributeSurface[];
}

export interface ProductAttributeTemplate {
  key: string;
  label: string;
  itemKind: ProductItemKind;
  attributes: ProductAttributeDefinition[];
}

export interface ProductAttributeSchema {
  version: number;
  itemKinds: ProductItemKind[];
  requirements: ProductAttributeRequirement[];
  valueTypes: ProductAttributeValueType[];
  commonPhysicalAttributes: ProductAttributeDefinition[];
  commonServiceAttributes: ProductAttributeDefinition[];
  templates: ProductAttributeTemplate[];
}

export const PRODUCT_ATTRIBUTE_SCHEMA = schemaJson as ProductAttributeSchema;

export const PRODUCT_TEMPLATE_BY_KEY = new Map(
  PRODUCT_ATTRIBUTE_SCHEMA.templates.map((template) => [template.key, template] as const),
);

export function productTemplateByKey(templateKey: string | null | undefined) {
  const key = String(templateKey || "").trim();
  if (!key) return PRODUCT_TEMPLATE_BY_KEY.get("generic") ?? null;
  return PRODUCT_TEMPLATE_BY_KEY.get(key) ?? null;
}

export function productAttributesForTemplate(templateKey: string | null | undefined) {
  const template = productTemplateByKey(templateKey);
  if (!template) return [];
  const common =
    template.itemKind === "service"
      ? PRODUCT_ATTRIBUTE_SCHEMA.commonServiceAttributes
      : PRODUCT_ATTRIBUTE_SCHEMA.commonPhysicalAttributes;
  return [...common, ...template.attributes];
}

export function productAttributesForSurface(
  templateKey: string | null | undefined,
  surface: ProductAttributeSurface,
) {
  return productAttributesForTemplate(templateKey).filter((attribute) =>
    attribute.display.includes(surface),
  );
}
