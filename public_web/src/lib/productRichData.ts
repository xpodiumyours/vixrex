export type ProductItemKind = "physical" | "service";
export type ProductPriceMode = "fixed" | "starting_from" | "ask";
export type ProductServiceLocation = "business" | "customer" | "remote";

export interface ProductIdentifierMetadata {
  sku?: string;
  mpn?: string;
}

export interface ProductAttributeValue {
  key: string;
  label?: string;
  value: string | number | boolean | string[];
  unit?: string;
  section?: string;
}

export interface ProductServiceMetadata {
  serviceType?: string;
  priceMode?: ProductPriceMode;
  durationMinutes?: number;
  serviceLocation?: ProductServiceLocation;
  appointmentRequired?: boolean;
  included?: string[];
}

export interface ProductMetadata {
  schemaVersion?: number;
  itemKind?: ProductItemKind;
  templateKey?: string;
  identifiers?: ProductIdentifierMetadata;
  attributes?: ProductAttributeValue[];
  service?: ProductServiceMetadata;
}

export interface ProductVariant {
  id: string;
  options: Record<string, string>;
  sku?: string;
  barcode?: string;
  priceAmount?: number;
  stockQuantity?: number;
  stockStatus?: string;
  imageUrls?: string[];
}

function asObject(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) return null;
  return value as Record<string, unknown>;
}

function cleanString(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed || undefined;
}

function cleanStringArray(value: unknown, limit = 50): string[] | undefined {
  if (!Array.isArray(value)) return undefined;
  const cleaned = value
    .map(cleanString)
    .filter((item): item is string => Boolean(item))
    .slice(0, limit);
  return cleaned.length ? cleaned : undefined;
}

export function normalizeProductMetadata(value: unknown): ProductMetadata {
  const root = asObject(value);
  if (!root) return {};

  const result: ProductMetadata = {};
  if (typeof root.schemaVersion === "number" && Number.isFinite(root.schemaVersion)) {
    result.schemaVersion = root.schemaVersion;
  }
  if (root.itemKind === "physical" || root.itemKind === "service") {
    result.itemKind = root.itemKind;
  }
  result.templateKey = cleanString(root.templateKey);

  const identifiers = asObject(root.identifiers);
  if (identifiers) {
    const sku = cleanString(identifiers.sku);
    const mpn = cleanString(identifiers.mpn);
    if (sku || mpn) result.identifiers = { sku, mpn };
  }

  if (Array.isArray(root.attributes)) {
    const attributes: ProductAttributeValue[] = [];
    for (const raw of root.attributes.slice(0, 100)) {
      const attribute = asObject(raw);
      if (!attribute) continue;
      const key = cleanString(attribute.key);
      if (!key) continue;
      const rawValue = attribute.value;
      let normalizedValue: ProductAttributeValue["value"] | undefined;
      if (typeof rawValue === "string") normalizedValue = rawValue.trim();
      else if (typeof rawValue === "number" && Number.isFinite(rawValue)) normalizedValue = rawValue;
      else if (typeof rawValue === "boolean") normalizedValue = rawValue;
      else normalizedValue = cleanStringArray(rawValue);
      if (normalizedValue === undefined || normalizedValue === "") continue;
      attributes.push({
        key,
        label: cleanString(attribute.label),
        value: normalizedValue,
        unit: cleanString(attribute.unit),
        section: cleanString(attribute.section),
      });
    }
    if (attributes.length) result.attributes = attributes;
  }

  const service = asObject(root.service);
  if (service) {
    const normalized: ProductServiceMetadata = {};
    normalized.serviceType = cleanString(service.serviceType);
    if (service.priceMode === "fixed" || service.priceMode === "starting_from" || service.priceMode === "ask") {
      normalized.priceMode = service.priceMode;
    }
    if (typeof service.durationMinutes === "number" && Number.isFinite(service.durationMinutes) && service.durationMinutes >= 0) {
      normalized.durationMinutes = service.durationMinutes;
    }
    if (service.serviceLocation === "business" || service.serviceLocation === "customer" || service.serviceLocation === "remote") {
      normalized.serviceLocation = service.serviceLocation;
    }
    if (typeof service.appointmentRequired === "boolean") {
      normalized.appointmentRequired = service.appointmentRequired;
    }
    normalized.included = cleanStringArray(service.included);
    if (Object.values(normalized).some((entry) => entry !== undefined)) result.service = normalized;
  }

  return result;
}

export function normalizeProductVariants(value: unknown): ProductVariant[] {
  if (!Array.isArray(value)) return [];
  const variants: ProductVariant[] = [];
  for (const raw of value.slice(0, 100)) {
    const variant = asObject(raw);
    if (!variant) continue;
    const id = cleanString(variant.id);
    const optionsObject = asObject(variant.options);
    if (!id || !optionsObject) continue;

    const options: Record<string, string> = {};
    for (const [key, optionValue] of Object.entries(optionsObject)) {
      const cleanKey = cleanString(key);
      const cleanValue = cleanString(optionValue);
      if (cleanKey && cleanValue) options[cleanKey] = cleanValue;
    }
    if (!Object.keys(options).length) continue;

    const normalized: ProductVariant = { id, options };
    normalized.sku = cleanString(variant.sku);
    normalized.barcode = cleanString(variant.barcode);
    if (typeof variant.priceAmount === "number" && Number.isFinite(variant.priceAmount) && variant.priceAmount >= 0) {
      normalized.priceAmount = variant.priceAmount;
    }
    if (typeof variant.stockQuantity === "number" && Number.isInteger(variant.stockQuantity) && variant.stockQuantity >= 0) {
      normalized.stockQuantity = variant.stockQuantity;
    }
    normalized.stockStatus = cleanString(variant.stockStatus);
    normalized.imageUrls = cleanStringArray(variant.imageUrls, 10);
    variants.push(normalized);
  }
  return variants;
}

export function productIsService(metadata: unknown): boolean {
  return normalizeProductMetadata(metadata).itemKind === "service";
}
