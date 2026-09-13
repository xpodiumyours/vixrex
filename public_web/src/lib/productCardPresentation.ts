import { productAttributesForSurface } from "./productAttributeSchema";
import {
  normalizeProductMetadata,
  normalizeProductVariants,
  type ProductAttributeValue,
} from "./productRichData";

export interface ProductQuickFact {
  key: string;
  label: string;
  value: string;
}

function formatAttributeValue(value: ProductAttributeValue["value"], unit?: string) {
  const formatted = Array.isArray(value)
    ? value.join(", ")
    : typeof value === "boolean"
      ? value
        ? "Evet"
        : "Hayır"
      : String(value);
  return unit ? `${formatted} ${unit}` : formatted;
}

const PRICE_MODE_LABELS = {
  fixed: "Sabit fiyat",
  starting_from: "Başlangıç fiyatı",
  ask: "Fiyat sor",
} as const;

const SERVICE_LOCATION_LABELS = {
  business: "İşletmede",
  customer: "Müşteri adresinde",
  remote: "Uzaktan",
} as const;

const CONDITION_LABELS: Record<string, string> = {
  new: "Yeni",
  used: "Kullanılmış",
  refurbished: "Yenilenmiş",
};

function serviceFacts(metadata: ReturnType<typeof normalizeProductMetadata>, detail = false) {
  const facts: ProductQuickFact[] = [];
  const service = metadata.service;
  if (!service) return facts;

  if (service.serviceType) {
    facts.push({ key: "serviceType", label: "Hizmet türü", value: service.serviceType });
  }
  if (service.priceMode) {
    facts.push({ key: "priceMode", label: "Fiyat biçimi", value: PRICE_MODE_LABELS[service.priceMode] });
  }
  if (service.durationMinutes != null) {
    facts.push({ key: "durationMinutes", label: "Tahmini süre", value: `${service.durationMinutes} dk` });
  }
  if (service.serviceLocation) {
    facts.push({
      key: "serviceLocation",
      label: "Hizmet yeri",
      value: SERVICE_LOCATION_LABELS[service.serviceLocation],
    });
  }
  if (detail && service.appointmentRequired != null) {
    facts.push({
      key: "appointmentRequired",
      label: "Randevu gerekli",
      value: service.appointmentRequired ? "Evet" : "Hayır",
    });
  }
  if (detail && service.included?.length) {
    facts.push({
      key: "included",
      label: "Hizmete dahil olanlar",
      value: service.included.join(", "),
    });
  }
  return facts;
}

function metadataAttributeFacts(args: {
  metadata: ReturnType<typeof normalizeProductMetadata>;
  surface: "quick" | "detail";
  existingKeys: Set<string>;
}) {
  const definitions = productAttributesForSurface(args.metadata.templateKey, args.surface);
  const definitionByKey = new Map(definitions.map((definition) => [definition.key, definition]));
  const facts: ProductQuickFact[] = [];

  for (const attribute of args.metadata.attributes || []) {
    if (args.existingKeys.has(attribute.key)) continue;
    const definition = definitionByKey.get(attribute.key);
    if (!definition) continue;
    const rawValue = formatAttributeValue(attribute.value, attribute.unit);
    facts.push({
      key: attribute.key,
      label: attribute.label || definition.label,
      value: attribute.key === "condition" ? CONDITION_LABELS[rawValue] || rawValue : rawValue,
    });
  }
  return facts;
}

export function buildProductQuickFacts(args: {
  brand?: string | null;
  metadata?: unknown;
  limit?: number;
}): ProductQuickFact[] {
  const metadata = normalizeProductMetadata(args.metadata);
  const limit = Math.max(0, args.limit ?? 4);
  const facts: ProductQuickFact[] = [];

  const brand = String(args.brand || "").trim();
  if (brand && metadata.itemKind !== "service") {
    facts.push({ key: "brand", label: "Marka", value: brand });
  }

  if (metadata.itemKind === "service") {
    facts.push(...serviceFacts(metadata));
  }

  facts.push(
    ...metadataAttributeFacts({
      metadata,
      surface: "quick",
      existingKeys: new Set(facts.map((fact) => fact.key)),
    }),
  );

  return facts.slice(0, limit);
}

export function buildProductDetailFacts(args: {
  brand?: string | null;
  barcode?: string | null;
  metadata?: unknown;
}): ProductQuickFact[] {
  const metadata = normalizeProductMetadata(args.metadata);
  const facts: ProductQuickFact[] = [];

  const brand = String(args.brand || "").trim();
  const barcode = String(args.barcode || "").trim();
  if (brand && metadata.itemKind !== "service") {
    facts.push({ key: "brand", label: "Marka", value: brand });
  }
  if (barcode && metadata.itemKind !== "service") {
    facts.push({ key: "barcode", label: "Barkod / GTIN", value: barcode });
  }
  if (metadata.identifiers?.sku) {
    facts.push({ key: "sku", label: "Stok kodu / SKU", value: metadata.identifiers.sku });
  }
  if (metadata.identifiers?.mpn) {
    facts.push({ key: "mpn", label: "Üretici parça kodu / MPN", value: metadata.identifiers.mpn });
  }
  if (metadata.itemKind === "service") {
    facts.push(...serviceFacts(metadata, true));
  }

  facts.push(
    ...metadataAttributeFacts({
      metadata,
      surface: "detail",
      existingKeys: new Set(facts.map((fact) => fact.key)),
    }),
  );

  return facts;
}

export function buildVariantOptionFacts(value: unknown): ProductQuickFact[] {
  const variants = normalizeProductVariants(value);
  const valuesByKey = new Map<string, Set<string>>();

  for (const variant of variants) {
    for (const [key, optionValue] of Object.entries(variant.options)) {
      const values = valuesByKey.get(key) ?? new Set<string>();
      values.add(optionValue);
      valuesByKey.set(key, values);
    }
  }

  return Array.from(valuesByKey.entries()).map(([key, values]) => ({
    key: `variant:${key}`,
    label: key,
    value: Array.from(values).join(", "),
  }));
}

export function productVariantCount(value: unknown): number {
  return normalizeProductVariants(value).length;
}

export function productVariantLabel(value: unknown): string | null {
  const count = productVariantCount(value);
  return count > 1 ? `${count} seçenek` : null;
}
