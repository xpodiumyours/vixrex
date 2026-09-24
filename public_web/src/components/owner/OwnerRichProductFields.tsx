"use client";

import Image from "next/image";
import { useEffect, useMemo } from "react";
import {
  PRODUCT_ATTRIBUTE_SCHEMA,
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
  imageUrls?: string[];
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

function variantId() {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID();
  }
  return `variant-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

export function alignVariantsToDefinitions(
  variants: ProductVariant[],
  variantDefinitions: ProductAttributeDefinition[],
  isService: boolean,
  imageUrls: string[] | null,
): ProductVariant[] {
  if (isService && variantDefinitions.length === 0) return [];
  const withValidImages = imageUrls == null
    ? variants
    : variants.map((variant) => {
        const availableImages = new Set(imageUrls);
        return {
          ...variant,
          imageUrls: variant.imageUrls?.filter((url) => availableImages.has(url)),
        };
      });
  if (variantDefinitions.length === 0) return withValidImages;
  const allowed = new Set(variantDefinitions.map((definition) => definition.key));
  return withValidImages.map((variant) => ({
    ...variant,
    options: Object.fromEntries(
      Object.entries(variant.options).filter(
        ([key, optionValue]) => allowed.has(key) && optionValue.trim().length > 0,
      ),
    ),
  }));
}

export function OwnerRichProductFields({
  templateKey,
  value,
  onChange,
  imageUrls,
  disabled = false,
}: Props) {
  const template = productTemplateByKey(templateKey);
  const definitions = useMemo(() => productAttributesForTemplate(templateKey), [templateKey]);
  const allowedKeys = useMemo(() => new Set(definitions.map((item) => item.key)), [definitions]);
  const variantDefinitions = useMemo(
    () => definitions.filter((definition) => definition.variantEligible),
    [definitions],
  );
  const cleanImageUrls = useMemo(
    () => imageUrls == null
      ? null
      : Array.from(new Set(imageUrls.map((url) => url.trim()).filter(Boolean))),
    [imageUrls],
  );

  useEffect(() => {
    if (!template) return;
    const isService = template.itemKind === "service";
    const metadata = normalizeProductMetadata(value.metadata);
    const filteredAttributes = isService
      ? []
      : (metadata.attributes || []).filter((item) => allowedKeys.has(item.key));
    const next: ProductMetadata = {
      ...metadata,
      schemaVersion: PRODUCT_ATTRIBUTE_SCHEMA.version,
      itemKind: template.itemKind,
      templateKey: template.key,
      identifiers: isService ? undefined : metadata.identifiers,
      attributes: filteredAttributes,
      service: isService ? metadata.service : undefined,
    };
    const nextVariants = alignVariantsToDefinitions(
      value.variants,
      variantDefinitions,
      isService,
      cleanImageUrls,
    );
    const variantsChanged = JSON.stringify(nextVariants) !== JSON.stringify(value.variants);
    const draftFieldsChanged =
      isService && Boolean(value.brand || value.barcode || value.stockQuantity);
    const metadataChanged =
      metadata.schemaVersion !== next.schemaVersion ||
      metadata.templateKey !== next.templateKey ||
      metadata.itemKind !== next.itemKind ||
      JSON.stringify(metadata.identifiers || null) !== JSON.stringify(next.identifiers || null) ||
      filteredAttributes.length !== (metadata.attributes || []).length ||
      Boolean(metadata.service) !== Boolean(next.service);

    if (metadataChanged || variantsChanged || draftFieldsChanged) {
      onChange({
        ...value,
        brand: isService ? "" : value.brand,
        barcode: isService ? "" : value.barcode,
        stockQuantity: isService ? "" : value.stockQuantity,
        metadata: next,
        variants: nextVariants,
      });
    }
  }, [allowedKeys, cleanImageUrls, onChange, template, value, variantDefinitions]);

  if (!template) {
    return (
      <div
        role="alert"
        className="mt-5 rounded-2xl border border-red-500/30 bg-red-500/5 p-4 text-sm text-red-300"
      >
        Ürün kategori şablonu doğrulanamadı. Kategori ayarını kontrol edin; Vixrex farklı bir kategori tahmin etmez.
      </div>
    );
  }

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

  function addVariant() {
    if (isService || variantDefinitions.length === 0) return;
    const options: Record<string, string> = {};
    for (const definition of variantDefinitions) {
      const base = attributeValue(value.metadata, definition.key);
      if (typeof base === "string" && base.trim()) options[definition.key] = base.trim();
    }
    onChange({
      ...value,
      variants: [...value.variants, { id: variantId(), options }],
    });
  }

  function updateVariant(index: number, patch: Partial<ProductVariant>) {
    const variants = value.variants.map((variant, variantIndex) =>
      variantIndex === index ? { ...variant, ...patch } : variant,
    );
    onChange({ ...value, variants });
  }

  function updateVariantOption(index: number, key: string, raw: string) {
    const variant = value.variants[index];
    if (!variant) return;
    const options = { ...variant.options };
    const clean = raw.trim();
    if (clean) options[key] = clean;
    else delete options[key];
    updateVariant(index, { options });
  }

  function toggleVariantImage(index: number, imageUrl: string) {
    const variant = value.variants[index];
    if (!variant) return;
    const selected = new Set(variant.imageUrls || []);
    if (selected.has(imageUrl)) selected.delete(imageUrl);
    else selected.add(imageUrl);
    updateVariant(index, { imageUrls: Array.from(selected) });
  }

  function removeVariant(index: number) {
    onChange({
      ...value,
      variants: value.variants.filter((_, variantIndex) => variantIndex !== index),
    });
  }

  const temelAlanlar = definitions.filter((definition) => !definition.advanced);
  const gelismisAlanlar = definitions.filter((definition) => definition.advanced);

  const alanKutusu = (definition: ProductAttributeDefinition) => {
          const current = definition.storage === "core.brand"
            ? value.brand
            : definition.storage === "core.barcode"
              ? value.barcode
              : displayInputValue(attributeValue(value.metadata, definition.key));
          const label = `${definition.label}${
            definition.requirement === "required"
              ? " *"
              : definition.requirement === "recommended"
                ? " · önerilen"
                : ""
          }`;

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
                    <option key={option} value={option}>{definition.optionLabels?.[option] || OPTION_LABELS[option] || option}</option>
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
              {definition.autoFill === "storeName" && !current.trim() ? (
                <span className="block text-[10px] text-[var(--owner-muted)]">Boş bırakırsan mağazanın adı yazılır.</span>
              ) : null}
              {definition.variantEligible ? (
                <span className="block text-[10px] text-[var(--owner-muted)]">Bu özellik varyant oluşturmak için kullanılabilir.</span>
              ) : null}
            </label>
          );
          };

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
        {temelAlanlar.map((definition) => alanKutusu(definition))}
      </div>

      {gelismisAlanlar.length > 0 ? (
        <details className="mt-4 rounded-xl border border-[var(--owner-border)] bg-[var(--owner-bg-soft)] p-3">
          <summary className="cursor-pointer text-xs font-bold text-[var(--owner-text-alt)]">
            Gelişmiş bilgiler (isteğe bağlı)
          </summary>
          <div className="mt-3 grid gap-4 sm:grid-cols-2">
            {gelismisAlanlar.map((definition) => alanKutusu(definition))}
          </div>
        </details>
      ) : null}

      {variantDefinitions.length > 0 ? (
        <section className="mt-5 border-t border-[var(--owner-border)] pt-5">
          <div className="flex items-start justify-between gap-3">
            <div>
              <h3 className="text-sm font-black text-[var(--owner-text)]">Varyantlar</h3>
              <p className="mt-1 text-xs leading-5 text-[var(--owner-muted)]">
                Renk, beden, RAM veya depolama gibi seçenekleri gerçek stok ve fiyatla bağla.
              </p>
            </div>
            <button
              type="button"
              onClick={addVariant}
              className="owner-button-secondary shrink-0"
              disabled={disabled}
            >
              + Varyant ekle
            </button>
          </div>

          {value.variants.length === 0 ? (
            <p className="mt-4 rounded-xl border border-dashed border-[var(--owner-border)] px-3 py-3 text-xs text-[var(--owner-muted)]">
              Varyant yok. Tek seçenekli ürünlerde eklemen gerekmez.
            </p>
          ) : (
            <div className="mt-4 space-y-3">
              {value.variants.map((variant, index) => (
                <div key={variant.id} className="rounded-xl border border-[var(--owner-border)] bg-[var(--owner-bg)] p-3">
                  <div className="flex items-center justify-between gap-3">
                    <p className="text-xs font-black text-[var(--owner-text)]">Varyant {index + 1}</p>
                    <button
                      type="button"
                      onClick={() => removeVariant(index)}
                      className="text-xs font-bold text-red-400 hover:text-red-300"
                    >
                      Sil
                    </button>
                  </div>

                  <div className="mt-3 grid gap-3 sm:grid-cols-2">
                    {variantDefinitions.map((definition) => (
                      <label key={definition.key} className="space-y-1.5">
                        <span className="owner-label">{definition.label}</span>
                        <input
                          className="owner-input"
                          value={variant.options[definition.key] || ""}
                          onChange={(e) => updateVariantOption(index, definition.key, e.target.value)}
                          placeholder={`Örn. ${definition.key === "size" ? "M" : definition.key === "color" ? "Siyah" : "değer"}`}
                        />
                      </label>
                    ))}
                    <label className="space-y-1.5">
                      <span className="owner-label">Varyant SKU</span>
                      <input
                        className="owner-input"
                        value={variant.sku || ""}
                        onChange={(e) => updateVariant(index, { sku: e.target.value.trim() || undefined })}
                      />
                    </label>
                    <label className="space-y-1.5">
                      <span className="owner-label">Varyant barkodu</span>
                      <input
                        className="owner-input"
                        value={variant.barcode || ""}
                        onChange={(e) => updateVariant(index, { barcode: e.target.value.trim() || undefined })}
                      />
                    </label>
                    <label className="space-y-1.5">
                      <span className="owner-label">Varyant fiyatı</span>
                      <input
                        type="number"
                        min={0}
                        step="0.01"
                        className="owner-input"
                        value={variant.priceAmount ?? ""}
                        onChange={(e) => {
                          const raw = e.target.value.trim();
                          const parsed = Number(raw);
                          updateVariant(index, {
                            priceAmount: raw && Number.isFinite(parsed) && parsed >= 0 ? parsed : undefined,
                          });
                        }}
                        placeholder="Boşsa ana fiyat"
                      />
                    </label>
                    <label className="space-y-1.5">
                      <span className="owner-label">Varyant stok adedi</span>
                      <input
                        type="number"
                        min={0}
                        step={1}
                        className="owner-input"
                        value={variant.stockQuantity ?? ""}
                        onChange={(e) => {
                          const raw = e.target.value.replace(/[^0-9]/g, "");
                          updateVariant(index, {
                            stockQuantity: raw ? Number(raw) : undefined,
                          });
                        }}
                      />
                    </label>
                  </div>

                  {cleanImageUrls && cleanImageUrls.length > 0 ? (
                    <div className="mt-3">
                      <p className="owner-label">Varyant fotoğrafları</p>
                      <p className="mt-1 text-[10px] text-[var(--owner-muted)]">
                        Bu varyant seçilince önce bu fotoğraflar gösterilir.
                      </p>
                      <div className="mt-2 flex gap-2 overflow-x-auto pb-1">
                        {cleanImageUrls.map((imageUrl, imageIndex) => {
                          const selected = variant.imageUrls?.includes(imageUrl) ?? false;
                          return (
                            <button
                              key={imageUrl}
                              type="button"
                              onClick={() => toggleVariantImage(index, imageUrl)}
                              disabled={disabled}
                              className={`relative h-14 w-14 shrink-0 overflow-hidden rounded-lg border-2 transition ${
                                selected
                                  ? "border-blue-500 ring-2 ring-blue-500/15"
                                  : "border-[var(--owner-border)] opacity-65 hover:opacity-100"
                              }`}
                              aria-pressed={selected}
                              aria-label={`${imageIndex + 1}. ürün fotoğrafını bu varyanta ${selected ? "kaldır" : "bağla"}`}
                            >
                              <Image src={imageUrl} alt="" fill unoptimized sizes="56px" className="object-cover" />
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  ) : null}
                </div>
              ))}
            </div>
          )}
        </section>
      ) : null}
    </fieldset>
  );
}