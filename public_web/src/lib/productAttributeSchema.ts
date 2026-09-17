import schemaJson from "../../../shared/product_attribute_schema.json";

export type ProductItemKind = "physical" | "service";
export type ProductAttributeRequirement = "optional" | "recommended" | "required";
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
  /** Formda "Gelismis" bolumunde gizlenir. */
  advanced?: boolean;
  /** Bos birakilirsa otomatik doldurulacak kaynak. */
  autoFill?: "storeName";
  display: ProductAttributeSurface[];
}

export interface ProductAttributeTemplate {
  key: string;
  label: string;
  itemKind: ProductItemKind;
  /** Bu sablonda sorulmayacak ortak alanlar. Kafe tabaginin markasi olmaz. */
  excludeCommon?: string[];
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
  const dislanan = new Set(template.excludeCommon ?? []);
  const common = (
    template.itemKind === "service"
      ? PRODUCT_ATTRIBUTE_SCHEMA.commonServiceAttributes
      : PRODUCT_ATTRIBUTE_SCHEMA.commonPhysicalAttributes
  ).filter((attribute) => !dislanan.has(attribute.key));
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

/** Bu şablonda doldurulması zorunlu olan alanlar. */
export function requiredProductAttributes(templateKey: string | null | undefined) {
  return productAttributesForTemplate(templateKey).filter(
    (attribute) => attribute.requirement === "required",
  );
}
