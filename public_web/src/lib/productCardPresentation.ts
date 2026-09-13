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

  if (metadata.itemKind === "service" && metadata.service) {
    const service = metadata.service;
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
  }

  const quickDefinitions = productAttributesForSurface(metadata.templateKey, "quick");
  const definitionByKey = new Map(quickDefinitions.map((definition) => [definition.key, definition]));
  for (const attribute of metadata.attributes || []) {
    if (facts.some((fact) => fact.key === attribute.key)) continue;
    const definition = definitionByKey.get(attribute.key);
    if (!definition) continue;
    facts.push({
      key: attribute.key,
      label: attribute.label || definition.label,
      value: formatAttributeValue(attribute.value, attribute.unit),
    });
  }

  return facts.slice(0, limit);
}

export function productVariantCount(value: unknown): number {
  return normalizeProductVariants(value).length;
}

export function productVariantLabel(value: unknown): string | null {
  const count = productVariantCount(value);
  return count > 1 ? `${count} seçenek` : null;
}
