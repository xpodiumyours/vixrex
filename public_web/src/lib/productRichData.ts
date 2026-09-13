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

function optionalText(value: unknown, maxLength?: number): string | undefined {
  if (typeof value !== "string") return undefined;
  const text = value.trim();
  if (!text || (maxLength != null && text.length > maxLength)) return undefined;
  return text;
}

function optionalFiniteNumber(value: unknown): number | null | undefined {
  if (value === null) return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  return undefined;
}

function normalizeFieldValue(
  definition: ProductAttributeDefinition,
  value: unknown,
): RichAttributeValue | undefined {
  if (definition.type === "boolean") {
    return typeof value === "boolean" ? value : undefined;
  }
  if (definition.type === "number") {
    if (typeof value !== "number" || !Number.isFinite(value)) return undefined;
    if (definition.min != null && value < definition.min) return undefined;
    if (definition.max != null && value > definition.max) return undefined;
    return value;
  }
  if (definition.type === "select") {
    const text = optionalText(value, definition.maxLength);
    if (!text || !(definition.options ?? []).includes(text)) return undefined;
    return text;
  }
  return optionalText(value, definition.maxLength);
}

export function normalizeProductMetadata(value: unknown): ProductRichMetadata {
  const raw = objectOrEmpty(value);
  const metadata: ProductRichMetadata = { schemaVersion: 1 };

  if (!isProductProfileKey(raw.profileKey)) return metadata;
  metadata.profileKey = raw.profileKey;

  const profile = getProductProfileDefinition(metadata.profileKey);
  const allowedFields = new Set(profile?.fields ?? []);

  const identifiersRaw = objectOrEmpty(raw.identifiers);
  const sku = allowedFields.has("sku") ? optionalText(identifiersRaw.sku, 80) : undefined;
  const mpn = allowedFields.has("mpn") ? optionalText(identifiersRaw.mpn, 80) : undefined;
  if (sku || mpn) metadata.identifiers = { sku, mpn };

  const attributesRaw = objectOrEmpty(raw.attributes);
  const attributes: Record<string, RichAttributeValue> = {};
  for (const [key, item] of Object.entries(attributesRaw)) {
    if (!allowedFields.has(key)) continue;
    const definition = PRODUCT_ATTRIBUTE_SCHEMA.fields[key];
    if (!definition?.storage.startsWith("metadata.attributes.")) continue;
    const normalized = normalizeFieldValue(definition, item);
    if (normalized !== undefined && normalized !== null && normalized !== "") {
      attributes[key] = normalized;
    }
  }
  if (Object.keys(attributes).length) metadata.attributes = attributes;

  if (profile?.itemKind === "service") {
    const serviceRaw = objectOrEmpty(raw.service);
    const service: ProductServiceData = {};
    for (const fieldKey of profile.fields) {
      const definition = PRODUCT_ATTRIBUTE_SCHEMA.fields[fieldKey];
      if (!definition?.storage.startsWith("metadata.service.")) continue;
      const serviceKey = definition.storage.split(".").at(-1);
      if (!serviceKey) continue;
      const normalized = normalizeFieldValue(definition, serviceRaw[serviceKey]);
      if (normalized === undefined || normalized === null || normalized === "") continue;
      if (serviceKey === "type" && typeof normalized === "string") service.type = normalized;
      if (serviceKey === "priceType" && typeof normalized === "string") {
        service.priceType = normalized as ProductServiceData["priceType"];
      }
      if (serviceKey === "durationMinutes" && typeof normalized === "number") {
        service.durationMinutes = normalized;
      }
      if (serviceKey === "location" && typeof normalized === "string") {
        service.location = normalized as ProductServiceData["location"];
      }
      if (serviceKey === "appointmentRequired" && typeof normalized === "boolean") {
        service.appointmentRequired = normalized;
      }
      if (serviceKey === "includes" && typeof normalized === "string") {
        service.includes = normalized;
      }
    }
    if (Object.keys(service).length) metadata.service = service;
  }

  return metadata;
}

export function normalizeProductVariants(
  value: unknown,
  profileKey?: ProductProfileKey,
): ProductVariantData[] {
  if (!Array.isArray(value)) return [];

  const profile = getProductProfileDefinition(profileKey);
  const allowedVariantKeys = new Set(
    (profile?.fields ?? Object.keys(PRODUCT_ATTRIBUTE_SCHEMA.fields)).filter(
      (key) => PRODUCT_ATTRIBUTE_SCHEMA.fields[key]?.variantEligible === true,
    ),
  );

  return value
    .slice(0, 20)
    .map((rawVariant, index): ProductVariantData | null => {
      const raw = objectOrEmpty(rawVariant);
      const optionsRaw = objectOrEmpty(raw.options);
      const options = Object.fromEntries(
        Object.entries(optionsRaw)
          .filter(([key]) => allowedVariantKeys.has(key))
          .map(([key, item]) => {
            const maxLength = PRODUCT_ATTRIBUTE_SCHEMA.fields[key]?.maxLength;
            return [key, optionalText(item, maxLength) ?? ""] as const;
          })
          .filter(([, item]) => Boolean(item)),
      );
      if (!Object.keys(options).length) return null;

      const id = optionalText(raw.id, 100) || `variant-${index + 1}`;
      const imageUrls = Array.isArray(raw.imageUrls)
        ? raw.imageUrls
            .filter((item): item is string => typeof item === "string")
            .map((item) => item.trim())
            .filter((item) => /^https?:\/\//i.test(item))
            .slice(0, 4)
        : undefined;
      const priceAmount = optionalFiniteNumber(raw.priceAmount);
      const stockQuantity = optionalFiniteNumber(raw.stockQuantity);

      return {
        id,
        options,
        sku: optionalText(raw.sku, 80),
        gtin: optionalText(raw.gtin, 32),
        priceAmount:
          typeof priceAmount === "number" && priceAmount >= 0 ? priceAmount : null,
        stockQuantity:
          typeof stockQuantity === "number" &&
          Number.isInteger(stockQuantity) &&
          stockQuantity >= 0
            ? stockQuantity
            : null,
        stockStatus: optionalText(raw.stockStatus, 40) ?? null,
        imageUrls,
      };
    })
    .filter((item): item is ProductVariantData => item !== null);
}
