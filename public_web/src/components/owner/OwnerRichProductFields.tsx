"use client";

import { useEffect, useMemo } from "react";
import {
  productAttributesForTemplate,
  productTemplateByKey,
  type ProductAttributeDefinition,
} from "@/lib/productAttributeSchema";
import {
  normalizeProductMetadata,
  normalizeProductVariants,
  type ProductMetadata,
  type ProductVariant,
} from "@/lib/productRichData";

export interface RichProductDraft {
  brand: string;
  barcode: string;
  stockQuantity: string;
  metadata: ProductMetadata;
  variants: ProductVariant[];
}

export function createRichProductDraft(input?: {
  brand?: string | null;
  barcode?: string | null;
  stock_quantity?: number | null;
  metadata?: unknown;
  variants?: unknown;
} | null): RichProductDraft {
  return {
    brand: input?.brand?.trim() || "",
    barcode: input?.barcode?.trim() || "",
    stockQuantity:
      typeof input?.stock_quantity === "number" && input.stock_quantity >= 0
        ? String(input.stock_quantity)
        : "",
    metadata: normalizeProductMetadata(input?.metadata),
    variants: normalizeProductVariants(input?.variants),
  };
}

interface Props {
  templateKey: string;
  value: RichProductDraft;
  onChange: (value: RichProductDraft) => void;
  disabled?: boolean;
}

const OPTION_LABELS: Record<string, string> = {
  new: "Yeni",
  used: "Kullanılmış",
  refurbished: "Yenilenmiş",
  fixed: "Sabit fiyat",
  starting_from: "Başlangıç fiyatı",
  ask: "Fiyat sor",
  business: "İşletmede",
  customer: "Müşterinin adresinde",
  remote: "Uzaktan",
};

function attributeValue(metadata: ProductMetadata, key: string): string | number | boolean | string[] | undefined {
  if (key === "sku") return metadata.identifiers?.sku;
  if (key === "mpn") return metadata.identifiers?.mpn;
  if (key === "serviceType") return metadata.service?.serviceType;
  if (key === "priceMode") return metadata.service?.priceMode;
  if (key === "durationMinutes") return metadata.service?.durationMinutes;
  if (key === "serviceLocation") return metadata.service?.serviceLocation;
  if (key === "appointmentRequired") return metadata.service?.appointmentRequired;
  if (key === "included") return metadata.service?.included;
  return metadata.attributes?.find((item) => item.key === key)?.value;
}

function withAttributeValue(
  metadata: ProductMetadata,
  definition: ProductAttributeDefinition,
  rawValue: string | number | boolean | string[] | undefined,
): ProductMetadata {
  if (definition.storage === "metadata.identifiers.sku") {
    return {
      ...metadata,
      identifiers: { ...metadata.identifiers, sku: typeof rawValue === "string" && rawValue.trim() ? rawValue.trim() : undefined },
    };
  }
  if (definition.storage === "metadata.identifiers.mpn") {
    return {
      ...metadata,
      identifiers: { ...metadata.identifiers, mpn: typeof rawValue === "string" && rawValue.trim() ? rawValue.trim() : undefined },
    };
  }
  if (definition.storage.startsWith("metadata.service.")) {
    const service = { ...metadata.service };
    const key = definition.storage.slice("metadata.service.".length);
    if (key === "serviceType") service.serviceType = typeof rawValue === "string" && rawValue.trim() ? rawValue.trim() : undefined;
    if (key === "priceMode") service.priceMode = rawValue === "fixed" || rawValue === "starting_from" || rawValue === "ask" ? rawValue : undefined;
    if (key === "durationMinutes") service.durationMinutes = typeof rawValue === "number" && Number.isFinite(rawValue) && rawValue >= 0 ? rawValue : undefined;
    if (key === "serviceLocation") service.serviceLocation = rawValue === "business" || rawValue === "customer" || rawValue === "remote" ? rawValue : undefined;
    if (key === "appointmentRequired") service.appointmentRequired = typeof rawValue === "boolean" ? rawValue : undefined;
    if (key === "included") service.included = Array.isArray(rawValue) ? rawValue : undefined;
    return { ...metadata, service };
  }

  const existing = metadata.attributes || [];
  const next = existing.filter((item) => item.key !== definition.key);
  const hasValue = Array.isArray(rawValue)
    ? rawValue.length > 0
    : typeof rawValue === "string"
      ? rawValue.trim().length > 0
      : rawValue !== undefined;
  if (hasValue) {
    next.push({
      key: definition.key,
      label: definition.label,
      value: rawValue as string | number | boolean | string[],
    });
  }
  return { ...metadata, attributes: next };
}

function parseInputValue(definition: ProductAttributeDefinition, raw: string) {
  if (definition.valueType === "number") {
    const value = Number(raw);
    return raw.trim() && Number.isFinite(value) && value >= 0 ? value : undefined;
  }
  if (definition.valueType === "boolean") {
    if (raw === "true") return true;
    if (raw === "false") return false;
    return undefined;
  }
  if (definition.valueType === "multi") {
    return raw.split(",").map((item) => item.trim()).filter(Boolean);
  }
  return raw.trim() || undefined;
}

function displayInputValue(value: ReturnType<typeof attributeValue>) {
  if (Array.isArray(value)) return value.join(", ");
  if (typeof value === "boolean") return value ? "true" : "false";
  if (value == null) return "";
  return String(value);
}

export function OwnerRichProductFields({ templateKey, value, onChange, disabled = false }: Props) {
  const template = productTemplateByKey(templateKey) || productTemplateByKey("generic");
  const definitions = useMemo(() => productAttributesForTemplate(templateKey), [templateKey]);
  const allowedKeys = useMemo(() => new Set(definitions.map((item) => item.key)), [definitions]);

  useEffect(() => {
    if (!template) return;
    const metadata = normalizeProductMetadata(value.metadata);
    const filteredAttributes = (metadata.attributes || []).filter((item) => allowedKeys.has(item.key));
    const next: ProductMetadata = {
      ...metadata,
      schemaVersion: 1,
      itemKind: template.itemKind,
      templateKey: template.key,
      attributes: filteredAttributes,
      ...(template.itemKind === "service" ? {} : { service: undefined }),
    };
    if (
      metadata.templateKey !== next.templateKey ||
      metadata.itemKind !== next.itemKind ||
      filteredAttributes.length !== (metadata.attributes || []).length
    ) {
      onChange({ ...value, metadata: next });
    }
  }, [allowedKeys, onChange, template, value]);

  if (!template) return null;

  const isService = template.itemKind === "service";

  function setDefinition(definition: ProductAttributeDefinition, raw: string) {
    if (definition.storage === "core.brand") {
      onChange({ ...value, brand: raw });
      return;
    }
    if (definition.storage === "core.barcode") {
      onChange({ ...value, barcode: raw });
      return;
    }
    onChange({
      ...value,
      metadata: withAttributeValue(value.metadata, definition, parseInputValue(definition, raw)),
    });
  }

  return (
    <fieldset className="mt-5 rounded-2xl border border-[var(--owner-border)] bg-[var(--owner-bg-soft)] p-4 sm:p-5" disabled={disabled}>
      <legend className="px-2 text-sm font-black text-[var(--owner-text)]">Ürün detayları</legend>
      <p className="mb-4 text-xs leading-5 text-[var(--owner-muted)]">
        {template.label} için ilgili bilgiler gösteriliyor. Bilmediğin alanı boş bırakabilirsin; Vixrex değer uydurmaz.
      </p>

      {!isService ? (
        <label className="mb-4 block space-y-2">
          <span className="owner-label">Stok adedi</span>
          <input
            type="number"
            min={0}
            step={1}
            className="owner-input"
            value={value.stockQuantity}
            onChange={(e) => onChange({ ...value, stockQuantity: e.target.value.replace(/[^0-9]/g, "") })}
            placeholder="Örn. 12"
          />
        </label>
      ) : null}

      <div className="grid gap-4 sm:grid-cols-2">
        {definitions.map((definition) => {
          const current = definition.storage === "core.brand"
            ? value.brand
            : definition.storage === "core.barcode"
              ? value.barcode
              : displayInputValue(attributeValue(value.metadata, definition.key));
          const label = `${definition.label}${definition.requirement === "recommended" ? " · önerilen" : ""}`;

          if (definition.valueType === "boolean") {
            return (
              <label key={definition.key} className="space-y-2">
                <span className="owner-label">{label}</span>
                <select className="owner-input" value={current} onChange={(e) => setDefinition(definition, e.target.value)}>
                  <option value="">Belirtilmedi</option>
                  <option value="true">Evet</option>
                  <option value="false">Hayır</option>
                </select>
              </label>
            );
          }

          if (definition.options?.length) {
            return (
              <label key={definition.key} className="space-y-2">
                <span className="owner-label">{label}</span>
                <select className="owner-input" value={current} onChange={(e) => setDefinition(definition, e.target.value)}>
                  <option value="">Belirtilmedi</option>
                  {definition.options.map((option) => (
                    <option key={option} value={option}>{OPTION_LABELS[option] || option}</option>
                  ))}
                </select>
              </label>
            );
          }

          return (
            <label key={definition.key} className={`space-y-2 ${definition.valueType === "multi" ? "sm:col-span-2" : ""}`}>
              <span className="owner-label">{label}</span>
              <input
                type={definition.valueType === "number" ? "number" : "text"}
                min={definition.valueType === "number" ? 0 : undefined}
                className="owner-input"
                value={current}
                onChange={(e) => setDefinition(definition, e.target.value)}
                placeholder={definition.valueType === "multi" ? "Virgülle ayır: örn. montaj, kontrol" : undefined}
              />
              {definition.variantEligible ? (
                <span className="block text-[10px] text-[var(--owner-muted)]">Bu özellik varyant oluşturmak için kullanılabilir.</span>
              ) : null}
            </label>
          );
        })}
      </div>

      {value.variants.length > 0 ? (
        <p className="mt-4 rounded-xl border border-[var(--owner-border)] px-3 py-2 text-xs text-[var(--owner-muted)]">
          Bu üründe {value.variants.length} kayıtlı varyant var. Bu form mevcut varyantları korur; varyant editörü ayrı adımda açılacak.
        </p>
      ) : null}
    </fieldset>
  );
}
