import {
  productAttributesForSurface,
  productAttributesForTemplate,
  productTemplateByKey,
} from "./productAttributeSchema";
import {
  normalizeProductMetadata,
  normalizeProductVariants,
  type ProductAttributeValue,
  type ProductVariant,
} from "./productRichData";

export interface ProductQuickFact {
  key: string;
  label: string;
  value: string;
}

export interface ProductVariantOptionGroup {
  key: string;
  label: string;
  values: string[];
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
  surface: "card" | "quick" | "detail";
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

  if (metadata.itemKind === "service") {
    facts.push(...serviceFacts(metadata, true));
    facts.push(
      ...metadataAttributeFacts({
        metadata,
        surface: "detail",
        existingKeys: new Set(facts.map((fact) => fact.key)),
      }),
    );
    return facts;
  }

  const brand = String(args.brand || "").trim();
  const barcode = String(args.barcode || "").trim();
  if (brand) {
    facts.push({ key: "brand", label: "Marka", value: brand });
  }
  if (barcode) {
    facts.push({ key: "barcode", label: "Barkod / GTIN", value: barcode });
  }
  if (metadata.identifiers?.sku) {
    facts.push({ key: "sku", label: "Stok kodu / SKU", value: metadata.identifiers.sku });
  }
  if (metadata.identifiers?.mpn) {
    facts.push({ key: "mpn", label: "Üretici parça kodu / MPN", value: metadata.identifiers.mpn });
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

export function productVariantsForTemplate(
  value: unknown,
  templateKey?: string | null,
): ProductVariant[] {
  const variants = normalizeProductVariants(value);
  const template = productTemplateByKey(templateKey);
  if (template?.itemKind === "service") return [];

  const variantDefinitions = productAttributesForTemplate(templateKey).filter(
    (definition) => definition.variantEligible,
  );
  if (variantDefinitions.length === 0) return variants;

  const allowedKeys = new Set(variantDefinitions.map((definition) => definition.key));
  return variants
    .map((variant) => ({
      ...variant,
      options: Object.fromEntries(
        Object.entries(variant.options).filter(
          ([key, optionValue]) => allowedKeys.has(key) && optionValue.trim().length > 0,
        ),
      ),
    }))
    .filter((variant) => Object.keys(variant.options).length > 0);
}

export function buildVariantOptionFacts(value: unknown, templateKey?: string | null): ProductQuickFact[] {
  return buildVariantOptionGroups(value, templateKey).map((group) => ({
    key: `variant:${group.key}`,
    label: group.label,
    value: group.values.join(", "),
  }));
}

export function buildVariantOptionGroups(
  value: unknown,
  templateKey?: string | null,
): ProductVariantOptionGroup[] {
  const variants = productVariantsForTemplate(value, templateKey);
  const valuesByKey = new Map<string, Set<string>>();
  const definitions = productAttributesForTemplate(templateKey).filter(
    (definition) => definition.variantEligible,
  );
  const definitionByKey = new Map(definitions.map((definition) => [definition.key, definition]));

  for (const variant of variants) {
    for (const [key, optionValue] of Object.entries(variant.options)) {
      const values = valuesByKey.get(key) ?? new Set<string>();
      values.add(optionValue);
      valuesByKey.set(key, values);
    }
  }

  return Array.from(valuesByKey.entries()).map(([key, values]) => ({
    key,
    label: definitionByKey.get(key)?.label || key,
    values: Array.from(values),
  }));
}

export function findMatchingVariant(
  value: unknown,
  selectedOptions: Record<string, string>,
  templateKey?: string | null,
): ProductVariant | null {
  const variants = productVariantsForTemplate(value, templateKey);
  const selectedEntries = Object.entries(selectedOptions).filter(([, optionValue]) => optionValue);
  if (!selectedEntries.length) return variants[0] ?? null;
  return (
    variants.find((variant) =>
      selectedEntries.every(([key, optionValue]) => variant.options[key] === optionValue),
    ) ?? null
  );
}

export function variantOptionIsAvailable(
  value: unknown,
  selectedOptions: Record<string, string>,
  optionKey: string,
  optionValue: string,
  templateKey?: string | null,
): boolean {
  const variants = productVariantsForTemplate(value, templateKey);
  return variants.some((variant) => {
    if (variant.options[optionKey] !== optionValue) return false;
    return Object.entries(selectedOptions).every(([key, selectedValue]) => {
      if (!selectedValue || key === optionKey) return true;
      return variant.options[key] === selectedValue;
    });
  });
}

export function productVariantCount(value: unknown, templateKey?: string | null): number {
  return productVariantsForTemplate(value, templateKey).length;
}

export function productVariantLabel(value: unknown, templateKey?: string | null): string | null {
  const count = productVariantCount(value, templateKey);
  return count > 1 ? `${count} seçenek` : null;
}

export interface ProductCardFacts {
  /** Kartın en üstünde, ürün adının üzerinde gösterilir. */
  marka: string | null;
  /** Adın altında küçük etiketler halinde gösterilir. */
  ozellikler: ProductQuickFact[];
}

export function buildProductCardFacts(args: {
  brand?: string | null;
  metadata?: unknown;
  limit?: number;
}): ProductCardFacts {
  const metadata = normalizeProductMetadata(args.metadata);
  const limit = Math.max(0, args.limit ?? 3);
  const kartAlanlari = new Set(
    productAttributesForSurface(metadata.templateKey, "card").map((definition) => definition.key),
  );

  const marka =
    metadata.itemKind !== "service" && kartAlanlari.has("brand")
      ? String(args.brand || "").trim() || null
      : null;

  const ozellikler: ProductQuickFact[] = [];

  if (metadata.itemKind === "service") {
    const service = metadata.service;
    if (service?.durationMinutes && kartAlanlari.has("durationMinutes")) {
      ozellikler.push({
        key: "durationMinutes",
        label: "Süre",
        value: `${service.durationMinutes} dk`,
      });
    }
    if (service?.priceMode && kartAlanlari.has("priceMode")) {
      ozellikler.push({
        key: "priceMode",
        label: "Fiyat biçimi",
        value: PRICE_MODE_LABELS[service.priceMode],
      });
    }
    if (service?.serviceLocation && kartAlanlari.has("serviceLocation")) {
      ozellikler.push({
        key: "serviceLocation",
        label: "Hizmet yeri",
        value: SERVICE_LOCATION_LABELS[service.serviceLocation],
      });
    }
  } else {
    ozellikler.push(
      ...metadataAttributeFacts({
        metadata,
        surface: "card",
        existingKeys: new Set(["brand"]),
      }),
    );
  }

  return { marka, ozellikler: ozellikler.slice(0, limit) };
}
