import schemaJson from "../../../shared/product_attribute_schema.json";

export type ProductProfileKey =
  | "general_product"
  | "apparel"
  | "electronics"
  | "beauty"
  | "food"
  | "home"
  | "auto_part"
  | "service";

export type RichAttributeValue = string | number | boolean | string[] | null;

export interface ProductIdentifiers {
  sku?: string;
  mpn?: string;
}

export interface ProductServiceData {
  type?: string;
  priceType?: "fixed" | "starting_from" | "ask";
  durationMinutes?: number;
  location?: "business" | "on_site" | "remote";
  appointmentRequired?: boolean;
  includes?: string;
}

export interface ProductRichMetadata {
  schemaVersion?: 1;
  profileKey?: ProductProfileKey;
  attributes?: Record<string, RichAttributeValue>;
  identifiers?: ProductIdentifiers;
  service?: ProductServiceData;
}

export interface ProductVariantData {
  id: string;
  options: Record<string, string>;
  sku?: string;
  gtin?: string;
  priceAmount?: number | null;
  stockQuantity?: number | null;
  stockStatus?: string | null;
  imageUrls?: string[];
}

export interface ProductAttributeDefinition {
  label: string;
  type: string;
  storage: string;
  maxLength?: number;
  min?: number;
  max?: number;
  options?: string[];
  variantEligible?: boolean;
}

export interface ProductProfileDefinition {
  key: ProductProfileKey;
  label: string;
  itemKind: "product" | "service";
  fields: string[];
}

export const PRODUCT_ATTRIBUTE_SCHEMA = schemaJson as {
  version: 1;
  description: string;
  profiles: ProductProfileDefinition[];
  fields: Record<string, ProductAttributeDefinition>;
};

const PROFILE_KEYS = new Set(
  PRODUCT_ATTRIBUTE_SCHEMA.profiles.map((profile) => profile.key),
);
const METADATA_ATTRIBUTE_KEYS = new Set(
  Object.entries(PRODUCT_ATTRIBUTE_SCHEMA.fields)
    .filter(([, definition]) => definition.storage.startsWith("metadata.attributes."))
    .map(([key]) => key),
);

export function isProductProfileKey(value: unknown): value is ProductProfileKey {
  return typeof value === "string" && PROFILE_KEYS.has(value as ProductProfileKey);
}

export function getProductProfileDefinition(
  key: ProductProfileKey | undefined,
): ProductProfileDefinition | undefined {
  return PRODUCT_ATTRIBUTE_SCHEMA.profiles.find((profile) => profile.key === key);
}

function objectOrEmpty(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function optionalText(value: unknown): string | undefined {
  const text = String(value ?? "").trim();
  return text || undefined;
}

function optionalFiniteNumber(value: unknown): number | null | undefined {
  if (value === null) return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  return undefined;
}

export function normalizeProductMetadata(value: unknown): ProductRichMetadata {
  const raw = objectOrEmpty(value);
  const metadata: ProductRichMetadata = { schemaVersion: 1 };

  if (isProductProfileKey(raw.profileKey)) {
    metadata.profileKey = raw.profileKey;
  }

  const identifiersRaw = objectOrEmpty(raw.identifiers);
  const sku = optionalText(identifiersRaw.sku);
  const mpn = optionalText(identifiersRaw.mpn);
  if (sku || mpn) metadata.identifiers = { sku, mpn };

  const attributesRaw = objectOrEmpty(raw.attributes);
  const attributes: Record<string, RichAttributeValue> = {};
  for (const [key, item] of Object.entries(attributesRaw)) {
    if (!METADATA_ATTRIBUTE_KEYS.has(key)) continue;
    if (typeof item === "string") {
      const text = item.trim();
      if (text) attributes[key] = text;
    } else if (typeof item === "number" && Number.isFinite(item)) {
      attributes[key] = item;
    } else if (typeof item === "boolean" || item === null) {
      attributes[key] = item;
    } else if (Array.isArray(item)) {
      const values = item.map((v) => String(v).trim()).filter(Boolean);
      if (values.length) attributes[key] = values;
    }
  }
  if (Object.keys(attributes).length) metadata.attributes = attributes;

  const serviceRaw = objectOrEmpty(raw.service);
  const service: ProductServiceData = {};
  const type = optionalText(serviceRaw.type);
  const includes = optionalText(serviceRaw.includes);
  const durationMinutes = optionalFiniteNumber(serviceRaw.durationMinutes);
  const priceType = optionalText(serviceRaw.priceType);
  const location = optionalText(serviceRaw.location);
  if (type) service.type = type;
  if (includes) service.includes = includes;
  if (typeof durationMinutes === "number" && durationMinutes > 0) {
    service.durationMinutes = durationMinutes;
  }
  if (["fixed", "starting_from", "ask"].includes(priceType || "")) {
    service.priceType = priceType as ProductServiceData["priceType"];
  }
  if (["business", "on_site", "remote"].includes(location || "")) {
    service.location = location as ProductServiceData["location"];
  }
  if (typeof serviceRaw.appointmentRequired === "boolean") {
    service.appointmentRequired = serviceRaw.appointmentRequired;
  }
  if (Object.keys(service).length) metadata.service = service;

  return metadata;
}

export function normalizeProductVariants(value: unknown): ProductVariantData[] {
  if (!Array.isArray(value)) return [];

  return value
    .map((rawVariant, index): ProductVariantData | null => {
      const raw = objectOrEmpty(rawVariant);
      const optionsRaw = objectOrEmpty(raw.options);
      const options = Object.fromEntries(
        Object.entries(optionsRaw)
          .filter(([key]) => {
            const definition = PRODUCT_ATTRIBUTE_SCHEMA.fields[key];
            return definition?.variantEligible === true;
          })
          .map(([key, item]) => [key, String(item ?? "").trim()] as const)
          .filter(([, item]) => Boolean(item)),
      );
      if (!Object.keys(options).length) return null;

      const id = optionalText(raw.id) || `variant-${index + 1}`;
      const imageUrls = Array.isArray(raw.imageUrls)
        ? raw.imageUrls.map((item) => String(item).trim()).filter(Boolean).slice(0, 4)
        : undefined;

      return {
        id,
        options,
        sku: optionalText(raw.sku),
        gtin: optionalText(raw.gtin),
        priceAmount: optionalFiniteNumber(raw.priceAmount),
        stockQuantity: optionalFiniteNumber(raw.stockQuantity),
        stockStatus: optionalText(raw.stockStatus) ?? null,
        imageUrls,
      };
    })
    .filter((item): item is ProductVariantData => item !== null);
}
