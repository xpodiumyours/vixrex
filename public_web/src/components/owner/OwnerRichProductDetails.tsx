"use client";

import { useMemo, useState } from "react";
import type { OwnerProduct } from "./OwnerProductManager";
import {
  PRODUCT_ATTRIBUTE_SCHEMA,
  getProductProfileDefinition,
  normalizeProductMetadata,
  normalizeProductVariants,
  type ProductProfileKey,
  type ProductRichMetadata,
  type ProductServiceData,
  type ProductVariantData,
  type RichAttributeValue,
} from "@/lib/productRichData";

export interface RichOwnerProduct extends OwnerProduct {
  price_amount?: number | null;
  stock_quantity?: number | null;
  brand?: string | null;
  barcode?: string | null;
  vat_rate?: number | null;
  metadata?: unknown;
  variants?: unknown;
}

interface Props {
  storeSlug: string;
  products: RichOwnerProduct[];
  onRefresh: () => Promise<void>;
}

function parseOptionalNumber(raw: string): number | null {
  const text = raw.trim().replace(",", ".");
  if (!text) return null;
  const value = Number(text);
  return Number.isFinite(value) ? value : null;
}

function newVariant(optionKeys: string[]): ProductVariantData {
  const randomId =
    typeof crypto !== "undefined" && "randomUUID" in crypto
      ? crypto.randomUUID()
      : `variant-${Date.now()}`;
  return {
    id: randomId,
    options: Object.fromEntries(optionKeys.map((key) => [key, ""])),
    priceAmount: null,
    stockQuantity: null,
    stockStatus: "Mevcut",
    imageUrls: [],
  };
}

export default function OwnerRichProductDetails({
  storeSlug,
  products,
  onRefresh,
}: Props) {
  const [selectedId, setSelectedId] = useState(products[0]?.id ?? "");
  const selected = products.find((item) => item.id === selectedId) ?? products[0] ?? null;

  if (!selected) return null;

  return (
    <section className="owner-card mt-6 p-5 sm:p-6" aria-labelledby="rich-product-title">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h2 id="rich-product-title" className="text-lg font-bold text-[var(--owner-text)]">
            Ürün detayları
          </h2>
          <p className="mt-1 max-w-2xl text-sm leading-6 text-[var(--owner-muted)]">
            Önce ürün tipini seç. Vixrex yalnız o tipe uygun teknik alanları gösterir; kategori adından tahmin yapmaz.
          </p>
        </div>
        <label className="min-w-56 space-y-1">
          <span className="owner-label">Düzenlenecek ürün</span>
          <select
            className="owner-input"
            value={selected.id}
            onChange={(event) => setSelectedId(event.target.value)}
          >
            {products.map((product) => (
              <option key={product.id} value={product.id}>
                {product.name}
              </option>
            ))}
          </select>
        </label>
      </div>

      <RichProductForm
        key={selected.id}
        storeSlug={storeSlug}
        product={selected}
        onRefresh={onRefresh}
      />
    </section>
  );
}

function RichProductForm({
  storeSlug,
  product,
  onRefresh,
}: {
  storeSlug: string;
  product: RichOwnerProduct;
  onRefresh: () => Promise<void>;
}) {
  const initialMetadata = normalizeProductMetadata(product.metadata);
  const [profileKey, setProfileKey] = useState<ProductProfileKey | "">(
    initialMetadata.profileKey ?? "",
  );
  const [brand, setBrand] = useState(product.brand ?? "");
  const [barcode, setBarcode] = useState(product.barcode ?? "");
  const [priceAmount, setPriceAmount] = useState(
    product.price_amount == null ? "" : String(product.price_amount),
  );
  const [stockQuantity, setStockQuantity] = useState(
    product.stock_quantity == null ? "" : String(product.stock_quantity),
  );
  const [vatRate, setVatRate] = useState(
    product.vat_rate == null ? "" : String(product.vat_rate),
  );
  const [attributes, setAttributes] = useState<Record<string, RichAttributeValue>>(
    initialMetadata.attributes ?? {},
  );
  const [identifiers, setIdentifiers] = useState({
    sku: initialMetadata.identifiers?.sku ?? "",
    mpn: initialMetadata.identifiers?.mpn ?? "",
  });
  const [service, setService] = useState<ProductServiceData>(
    initialMetadata.service ?? {},
  );
  const [variants, setVariants] = useState<ProductVariantData[]>(() =>
    normalizeProductVariants(product.variants),
  );
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const profile = profileKey ? getProductProfileDefinition(profileKey) : undefined;
  const fields = profile?.fields ?? [];
  const variantFields = useMemo(
    () =>
      fields.filter(
        (key) => PRODUCT_ATTRIBUTE_SCHEMA.fields[key]?.variantEligible === true,
      ),
    [fields],
  );

  function readDynamicValue(fieldKey: string): RichAttributeValue | string | number | boolean {
    const definition = PRODUCT_ATTRIBUTE_SCHEMA.fields[fieldKey];
    if (!definition) return "";
    if (definition.storage === "metadata.identifiers.sku") return identifiers.sku;
    if (definition.storage === "metadata.identifiers.mpn") return identifiers.mpn;
    if (definition.storage.startsWith("metadata.attributes.")) {
      return attributes[fieldKey] ?? "";
    }
    if (definition.storage.startsWith("metadata.service.")) {
      const key = definition.storage.split(".").at(-1) as keyof ProductServiceData;
      return service[key] ?? "";
    }
    return "";
  }

  function writeDynamicValue(fieldKey: string, value: RichAttributeValue) {
    const definition = PRODUCT_ATTRIBUTE_SCHEMA.fields[fieldKey];
    if (!definition) return;
    if (definition.storage === "metadata.identifiers.sku") {
      setIdentifiers((prev) => ({ ...prev, sku: String(value ?? "") }));
      return;
    }
    if (definition.storage === "metadata.identifiers.mpn") {
      setIdentifiers((prev) => ({ ...prev, mpn: String(value ?? "") }));
      return;
    }
    if (definition.storage.startsWith("metadata.attributes.")) {
      setAttributes((prev) => ({ ...prev, [fieldKey]: value }));
      return;
    }
    if (definition.storage.startsWith("metadata.service.")) {
      const key = definition.storage.split(".").at(-1) as keyof ProductServiceData;
      setService((prev) => ({ ...prev, [key]: value }));
    }
  }

  function changeProfile(next: ProductProfileKey | "") {
    setProfileKey(next);
    setVariants([]);
    setError("");
    setMessage("");
  }

  function updateVariant(index: number, patch: Partial<ProductVariantData>) {
    setVariants((prev) =>
      prev.map((item, itemIndex) =>
        itemIndex === index ? { ...item, ...patch } : item,
      ),
    );
  }

  async function save() {
    if (!profileKey || !profile) {
      setError("Önce ürün tipini seç.");
      return;
    }

    const parsedPrice = parseOptionalNumber(priceAmount);
    const parsedStock = parseOptionalNumber(stockQuantity);
    const parsedVat = parseOptionalNumber(vatRate);
    if (priceAmount.trim() && parsedPrice == null) {
      setError("Sayısal fiyat geçerli bir sayı olmalı.");
      return;
    }
    if (stockQuantity.trim() && (parsedStock == null || !Number.isInteger(parsedStock) || parsedStock < 0)) {
      setError("Stok adedi 0 veya daha büyük tam sayı olmalı.");
      return;
    }
    if (vatRate.trim() && (parsedVat == null || !Number.isInteger(parsedVat) || parsedVat < 0 || parsedVat > 100)) {
      setError("KDV oranı 0 ile 100 arasında tam sayı olmalı.");
      return;
    }
    if (variants.length > 20) {
      setError("Bir üründe en fazla 20 varyant düzenlenebilir.");
      return;
    }
    if (
      variants.some(
        (variant) =>
          !Object.values(variant.options).some((value) => value.trim().length > 0),
      )
    ) {
      setError("Her varyantta en az bir seçenek değeri olmalı.");
      return;
    }

    const metadata: ProductRichMetadata = {
      schemaVersion: 1,
      profileKey,
      attributes,
      identifiers: {
        sku: identifiers.sku.trim() || undefined,
        mpn: identifiers.mpn.trim() || undefined,
      },
      service: profile.itemKind === "service" ? service : undefined,
    };

    setBusy(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch("/api/products", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug: storeSlug,
          productId: product.id,
          name: product.name,
          description: product.description ?? "",
          priceText: product.price_text ?? "",
          priceAmount: parsedPrice,
          imageUrls: product.image_urls ?? [],
          categoryId: product.category_id ?? "",
          stockStatus: product.stock_status ?? "Mevcut",
          stockQuantity: parsedStock,
          oldPriceAmount: product.old_price_amount ?? null,
          badgeTag: product.badge_tag ?? null,
          fulfillmentRegion: product.fulfillment_region ?? null,
          brand: brand.trim() || null,
          barcode: barcode.trim() || null,
          vatRate: parsedVat,
          metadata,
          variants,
        }),
      });
      const payload = await response.json().catch(() => null);
      if (!response.ok) {
        throw new Error(
          payload && typeof payload.hata === "string"
            ? payload.hata
            : "Ürün detayları kaydedilemedi.",
        );
      }
      await onRefresh();
      setMessage("Ürün detayları kaydedildi.");
    } catch (saveError) {
      setError(
        saveError instanceof Error
          ? saveError.message
          : "Ürün detayları kaydedilemedi.",
      );
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mt-5 border-t border-[var(--owner-border)] pt-5">
      <label className="block max-w-md space-y-2">
        <span className="owner-label">Ürün tipi *</span>
        <select
          className="owner-input"
          value={profileKey}
          disabled={busy}
          onChange={(event) => changeProfile(event.target.value as ProductProfileKey | "")}
        >
          <option value="">Ürün tipi seç</option>
          {PRODUCT_ATTRIBUTE_SCHEMA.profiles.map((item) => (
            <option key={item.key} value={item.key}>
              {item.label}
            </option>
          ))}
        </select>
      </label>

      {!profile ? (
        <p className="mt-4 text-sm text-[var(--owner-muted)]">
          Ürün tipi seçildiğinde yalnız ilgili teknik alanlar açılır.
        </p>
      ) : (
        <>
          {profile.itemKind === "product" ? (
            <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {fields.includes("brand") ? (
                <TextField label="Marka" value={brand} maxLength={120} disabled={busy} onChange={setBrand} />
              ) : null}
              {fields.includes("barcode") ? (
                <TextField label="Barkod / GTIN" value={barcode} maxLength={32} disabled={busy} onChange={setBarcode} />
              ) : null}
              <TextField label="Sayısal fiyat" value={priceAmount} inputMode="decimal" disabled={busy} onChange={setPriceAmount} placeholder="Örn. 499.90" />
              <TextField label="Stok adedi" value={stockQuantity} inputMode="numeric" disabled={busy} onChange={setStockQuantity} placeholder="Örn. 12" />
              <TextField label="KDV oranı (%)" value={vatRate} inputMode="numeric" disabled={busy} onChange={setVatRate} placeholder="Örn. 20" />
            </div>
          ) : null}

          <div className="mt-5 grid gap-4 sm:grid-cols-2">
            {fields
              .filter((key) => !["brand", "barcode"].includes(key))
              .map((fieldKey) => (
                <DynamicField
                  key={fieldKey}
                  fieldKey={fieldKey}
                  value={readDynamicValue(fieldKey)}
                  disabled={busy}
                  onChange={(value) => writeDynamicValue(fieldKey, value)}
                />
              ))}
          </div>

          {profile.itemKind === "product" && variantFields.length > 0 ? (
            <div className="mt-6 border-t border-[var(--owner-border)] pt-5">
              <div className="flex items-center justify-between gap-3">
                <div>
                  <h3 className="font-bold text-[var(--owner-text)]">Varyantlar</h3>
                  <p className="mt-1 text-xs text-[var(--owner-muted)]">
                    Renk, beden veya kapasite gibi seçenekleri aynı ürün altında tutar.
                  </p>
                </div>
                <button
                  type="button"
                  className="owner-button-secondary text-sm"
                  disabled={busy || variants.length >= 20}
                  onClick={() => setVariants((prev) => [...prev, newVariant(variantFields)])}
                >
                  + Varyant
                </button>
              </div>

              <div className="mt-4 space-y-4">
                {variants.map((variant, index) => (
                  <div key={variant.id} className="rounded-2xl border border-[var(--owner-border)] p-4">
                    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                      {variantFields.map((optionKey) => (
                        <TextField
                          key={optionKey}
                          label={PRODUCT_ATTRIBUTE_SCHEMA.fields[optionKey]?.label ?? optionKey}
                          value={variant.options[optionKey] ?? ""}
                          disabled={busy}
                          onChange={(value) =>
                            updateVariant(index, {
                              options: { ...variant.options, [optionKey]: value },
                            })
                          }
                        />
                      ))}
                      <TextField label="SKU" value={variant.sku ?? ""} disabled={busy} onChange={(value) => updateVariant(index, { sku: value })} />
                      <TextField label="GTIN" value={variant.gtin ?? ""} disabled={busy} onChange={(value) => updateVariant(index, { gtin: value })} />
                      <TextField label="Varyant fiyatı" value={variant.priceAmount == null ? "" : String(variant.priceAmount)} inputMode="decimal" disabled={busy} onChange={(value) => updateVariant(index, { priceAmount: parseOptionalNumber(value) })} />
                      <TextField label="Varyant stok adedi" value={variant.stockQuantity == null ? "" : String(variant.stockQuantity)} inputMode="numeric" disabled={busy} onChange={(value) => updateVariant(index, { stockQuantity: parseOptionalNumber(value) })} />
                    </div>
                    <button
                      type="button"
                      className="owner-button-danger mt-3 text-xs"
                      disabled={busy}
                      onClick={() => setVariants((prev) => prev.filter((_, itemIndex) => itemIndex !== index))}
                    >
                      Varyantı kaldır
                    </button>
                  </div>
                ))}
              </div>
            </div>
          ) : null}
        </>
      )}

      {error ? <p className="owner-error mt-4 text-sm" role="alert">{error}</p> : null}
      {message ? <p className="mt-4 text-sm font-bold text-[var(--owner-success)]" role="status">{message}</p> : null}
      <div className="mt-5 flex justify-end">
        <button
          type="button"
          className="owner-button-primary"
          disabled={busy || !profileKey}
          onClick={() => void save()}
        >
          {busy ? "Kaydediliyor…" : "Detayları Kaydet"}
        </button>
      </div>
    </div>
  );
}

function TextField({
  label,
  value,
  onChange,
  disabled,
  maxLength,
  placeholder,
  inputMode,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  disabled: boolean;
  maxLength?: number;
  placeholder?: string;
  inputMode?: "text" | "numeric" | "decimal";
}) {
  return (
    <label className="space-y-2">
      <span className="owner-label">{label}</span>
      <input
        className="owner-input"
        value={value}
        disabled={disabled}
        maxLength={maxLength}
        placeholder={placeholder}
        inputMode={inputMode}
        onChange={(event) => onChange(event.target.value)}
      />
    </label>
  );
}

function DynamicField({
  fieldKey,
  value,
  disabled,
  onChange,
}: {
  fieldKey: string;
  value: RichAttributeValue | string | number | boolean;
  disabled: boolean;
  onChange: (value: RichAttributeValue) => void;
}) {
  const definition = PRODUCT_ATTRIBUTE_SCHEMA.fields[fieldKey];
  if (!definition) return null;

  if (definition.type === "boolean") {
    return (
      <label className="flex items-center gap-3 rounded-xl border border-[var(--owner-border)] px-3 py-3">
        <input
          type="checkbox"
          checked={value === true}
          disabled={disabled}
          onChange={(event) => onChange(event.target.checked)}
        />
        <span className="owner-label">{definition.label}</span>
      </label>
    );
  }

  if (definition.type === "select") {
    return (
      <label className="space-y-2">
        <span className="owner-label">{definition.label}</span>
        <select
          className="owner-input"
          value={String(value ?? "")}
          disabled={disabled}
          onChange={(event) => onChange(event.target.value)}
        >
          <option value="">Seç</option>
          {(definition.options ?? []).map((option) => (
            <option key={option} value={option}>{option}</option>
          ))}
        </select>
      </label>
    );
  }

  const common = {
    className: "owner-input",
    value: String(value ?? ""),
    disabled,
    maxLength: definition.maxLength,
    onChange: (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
      if (definition.type === "number") {
        const parsed = parseOptionalNumber(event.target.value);
        onChange(parsed);
      } else {
        onChange(event.target.value);
      }
    },
  };

  return (
    <label className="space-y-2">
      <span className="owner-label">{definition.label}</span>
      {definition.type === "textarea" ? (
        <textarea {...common} className="owner-input min-h-24 resize-y" />
      ) : (
        <input {...common} inputMode={definition.type === "number" ? "numeric" : "text"} />
      )}
    </label>
  );
}
