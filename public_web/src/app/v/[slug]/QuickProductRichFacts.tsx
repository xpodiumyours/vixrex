"use client";

import { useEffect, useMemo, useState } from "react";
import {
  PRODUCT_ATTRIBUTE_SCHEMA,
  getProductProfileDefinition,
  type ProductRichMetadata,
  type ProductVariantData,
  type RichAttributeValue,
} from "@/lib/productRichData";

interface RichPublicProduct {
  brand: string | null;
  barcode: string | null;
  priceAmount: number | null;
  stockQuantity: number | null;
  stockStatus: string | null;
  vatRate: number | null;
  metadata: ProductRichMetadata;
  variants: ProductVariantData[];
}

function displayValue(value: RichAttributeValue | undefined): string {
  if (Array.isArray(value)) return value.join(", ");
  if (typeof value === "boolean") return value ? "Evet" : "Hayır";
  if (value == null) return "";
  return String(value);
}

export default function QuickProductRichFacts({
  storeSlug,
  productSlug,
}: {
  storeSlug: string;
  productSlug: string;
}) {
  const [data, setData] = useState<RichPublicProduct | null>(null);

  useEffect(() => {
    let alive = true;
    const params = new URLSearchParams({ store: storeSlug, product: productSlug });
    fetch(`/api/public-product-rich?${params.toString()}`)
      .then(async (response) => (response.ok ? response.json() : null))
      .then((payload) => {
        if (alive && payload) setData(payload as RichPublicProduct);
      })
      .catch(() => undefined);
    return () => {
      alive = false;
    };
  }, [storeSlug, productSlug]);

  const facts = useMemo(() => {
    if (!data) return [] as Array<{ label: string; value: string }>;
    const metadata = data.metadata ?? {};
    const profile = getProductProfileDefinition(metadata.profileKey);
    const result: Array<{ label: string; value: string }> = [];

    if (data.brand) result.push({ label: "Marka", value: data.brand });
    if (data.stockQuantity != null) {
      result.push({ label: "Stok", value: `${data.stockQuantity} adet` });
    }

    for (const fieldKey of profile?.fields ?? []) {
      if (result.length >= 5) break;
      if (["brand", "barcode", "sku", "mpn"].includes(fieldKey)) continue;
      const definition = PRODUCT_ATTRIBUTE_SCHEMA.fields[fieldKey];
      if (!definition) continue;
      let rawValue: RichAttributeValue | undefined;
      if (definition.storage.startsWith("metadata.attributes.")) {
        rawValue = metadata.attributes?.[fieldKey];
      } else if (definition.storage.startsWith("metadata.service.")) {
        const serviceKey = definition.storage.split(".").at(-1);
        const serviceValue = serviceKey
          ? (metadata.service as Record<string, unknown> | undefined)?.[serviceKey]
          : undefined;
        if (
          typeof serviceValue === "string" ||
          typeof serviceValue === "number" ||
          typeof serviceValue === "boolean"
        ) {
          rawValue = serviceValue;
        }
      }
      const value = displayValue(rawValue);
      if (value) result.push({ label: definition.label, value });
    }

    return result.slice(0, 5);
  }, [data]);

  if (!data || (facts.length === 0 && data.variants.length === 0)) return null;

  return (
    <div className="mt-4 space-y-3">
      {facts.length > 0 ? (
        <div className="grid grid-cols-2 gap-2">
          {facts.map((fact) => (
            <div key={`${fact.label}-${fact.value}`} className="rounded-xl border border-white/10 bg-white/[0.03] p-3">
              <p className="text-[10px] font-extrabold uppercase tracking-wider text-slate-500">{fact.label}</p>
              <p className="mt-1 break-words text-xs font-bold text-slate-200">{fact.value}</p>
            </div>
          ))}
        </div>
      ) : null}

      {data.variants.length > 0 ? (
        <div className="rounded-xl border border-white/10 bg-white/[0.03] p-3">
          <p className="text-[10px] font-extrabold uppercase tracking-wider text-slate-500">Seçenekler</p>
          <div className="mt-2 flex flex-wrap gap-2">
            {data.variants.slice(0, 8).map((variant) => (
              <span
                key={variant.id}
                className="rounded-lg border border-blue-500/20 bg-blue-500/5 px-2.5 py-1.5 text-[11px] font-bold text-slate-200"
              >
                {Object.entries(variant.options)
                  .map(([key, value]) => `${PRODUCT_ATTRIBUTE_SCHEMA.fields[key]?.label ?? key}: ${value}`)
                  .join(" · ")}
              </span>
            ))}
          </div>
        </div>
      ) : null}
    </div>
  );
}
