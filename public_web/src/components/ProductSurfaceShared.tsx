"use client";

import type { ReactNode } from "react";
import ManufacturerProductSource from "@/components/ManufacturerProductSource";
import type {
  ProductQuickFact,
  ProductVariantOptionGroup,
} from "@/lib/productCardPresentation";
import type { ProductManufacturerSource } from "@/lib/productRichData";
import { MapPinIcon } from "@/lib/vitrinBrandIcons";
import { vitrinGorunum } from "@/lib/vitrinGorunum";

export function productMapsUrl(value: string | null | undefined): string | null {
  const clean = String(value || "").trim();
  if (!clean) return null;
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(clean)}`;
}

export function productImageAlt(parts: {
  name?: string | null;
  storeName?: string | null;
  locality?: string | null;
}): string {
  return [parts.name, parts.storeName, parts.locality]
    .map((parca) => String(parca || "").trim())
    .filter(Boolean)
    .join(" - ");
}

export function productLocationLabel(parts: {
  neighborhoodName?: string | null;
  districtName?: string | null;
  provinceName?: string | null;
}): string {
  return [
    String(parts.neighborhoodName || "").trim(),
    String(parts.districtName || "").trim(),
    String(parts.provinceName || "").trim(),
  ]
    .filter((parca, index, dizi) => Boolean(parca) && dizi.indexOf(parca) === index)
    .join(", ");
}

export function stockTone(status?: string | null): string {
  const value = String(status || "").toLocaleLowerCase("tr-TR");
  if (value.includes("tükendi")) return "text-red-300";
  if (value.includes("son") || value.includes("az") || value.includes("sınırl")) {
    return "text-amber-300";
  }
  return "text-emerald-300";
}

export function formatVariantPrice(amount: number, currency?: string): string {
  return new Intl.NumberFormat("tr-TR", {
    style: "currency",
    currency: currency || "TRY",
    maximumFractionDigits: 2,
  }).format(amount);
}

interface ProductLocationPanelProps {
  isService: boolean;
  fulfillmentRegion?: string | null;
  storeLocationLabel?: string | null;
  storeAddress?: string | null;
  storeMapUrl?: string | null;
}

export function ProductLocationPanel({
  isService,
  fulfillmentRegion,
  storeLocationLabel,
  storeAddress,
  storeMapUrl,
}: ProductLocationPanelProps) {
  const region = String(fulfillmentRegion || "").trim();
  const label = String(storeLocationLabel || "").trim();
  const address = String(storeAddress || "").trim();
  const addressFarkli = Boolean(address) && address !== label;
  const regionMapUrl = productMapsUrl(region);

  return (
    <div className="mt-5 rounded-2xl border border-blue-500/20 bg-gradient-to-br from-blue-500/10 to-cyan-500/5 p-4">
      <div className="flex items-start gap-3">
        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-blue-500/15">
          <MapPinIcon className="h-4 w-4 text-blue-300" aria-hidden="true" />
        </div>
        <div className="min-w-0 flex-1">
          {region ? (
            <div>
              <p className="text-[10px] font-extrabold uppercase tracking-wider text-blue-300">
                {isService ? "Hizmet bölgesi" : "Ürün konumu / teslim bölgesi"}
              </p>
              <p className="mt-1 text-xs font-semibold leading-5 text-slate-200">{region}</p>
              {regionMapUrl ? (
                <a
                  href={regionMapUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-1.5 inline-flex text-xs font-extrabold text-blue-400 hover:text-blue-300"
                >
                  Haritada ara →
                </a>
              ) : null}
            </div>
          ) : null}
          {label || address ? (
            <div className={region ? "mt-3 border-t border-white/10 pt-3" : ""}>
              <p className="text-[10px] font-extrabold uppercase tracking-wider text-slate-400">
                İşletme konumu
              </p>
              {label ? (
                <p className="mt-1 text-xs font-semibold leading-5 text-slate-200">{label}</p>
              ) : null}
              {addressFarkli ? (
                <p className="mt-1 text-xs font-semibold leading-5 text-slate-300">{address}</p>
              ) : null}
              {storeMapUrl ? (
                <a
                  href={storeMapUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-1.5 inline-flex text-xs font-extrabold text-blue-400 hover:text-blue-300"
                >
                  Yol tarifi →
                </a>
              ) : null}
            </div>
          ) : null}
          {!region && !label && !address ? (
            <p className="text-xs font-semibold leading-5 text-slate-300">
              Bu {isService ? "hizmet" : "ürün"} için konum bilgisi eklenmemiş.
            </p>
          ) : null}
        </div>
      </div>
    </div>
  );
}

export interface ProductInfoBodyProps {
  isService: boolean;
  category?: string | null;
  name: string;
  brand?: string | null;
  heading: "h1" | "h2";
  headingId?: string;
  displayedPrice: string;
  discountPercent?: number | null;
  oldPriceText?: string | null;
  badge?: string | null;
  unitPrice?: { miktar: string; birimFiyat: string } | null;
  variantGroups: ProductVariantOptionGroup[];
  selectedOptions: Record<string, string>;
  onSelectOption: (key: string, value: string) => void;
  isOptionAvailable: (key: string, value: string) => boolean;
  stockStatus?: string | null;
  stockQuantity?: number | null;
  facts: ProductQuickFact[];
  manufacturerSource?: ProductManufacturerSource;
  fulfillmentRegion?: string | null;
  storeLocationLabel?: string | null;
  storeAddress?: string | null;
  storeMapUrl?: string | null;
  description?: string | null;
  clampDescription?: boolean;
  children?: ReactNode;
}

export function ProductInfoBody({
  isService,
  category,
  name,
  brand,
  heading,
  headingId,
  displayedPrice,
  discountPercent,
  oldPriceText,
  badge,
  unitPrice,
  variantGroups,
  selectedOptions,
  onSelectOption,
  isOptionAvailable,
  stockStatus,
  stockQuantity,
  facts,
  manufacturerSource,
  fulfillmentRegion,
  storeLocationLabel,
  storeAddress,
  storeMapUrl,
  description,
  clampDescription = false,
  children,
}: ProductInfoBodyProps) {
  const Heading = heading;
  const marka = String(brand || "").trim();
  const stokDurumu = String(stockStatus || "").trim();

  return (
    <>
      {category ? (
        <p className="text-[10px] font-extrabold uppercase tracking-[0.14em] text-cyan-300">
          {category}
        </p>
      ) : null}
      <Heading
        id={headingId}
        className="mt-2 text-2xl font-black leading-tight tracking-tight text-white sm:text-3xl"
      >
        {name}
      </Heading>
      {!isService && marka ? (
        <p className="mt-2 text-[10px] font-extrabold uppercase tracking-[0.13em] text-slate-400">
          {marka}
        </p>
      ) : null}

      <div className="mt-4 flex flex-wrap items-baseline gap-x-2.5 gap-y-1">
        <p className={`text-2xl font-black ${vitrinGorunum.fiyat.ana}`}>{displayedPrice}</p>
        {discountPercent != null ? (
          <span className={`${vitrinGorunum.rozet.indirim} px-1.5 py-0.5 text-[10px] font-black`}>
            %{discountPercent}
          </span>
        ) : null}
        {oldPriceText ? (
          <span className={`text-sm font-medium ${vitrinGorunum.fiyat.eski}`}>{oldPriceText}</span>
        ) : null}
        {badge ? (
          <span
            className={`${vitrinGorunum.rozet.gorsel} px-2.5 py-1 text-[10px] font-extrabold shadow-md`}
          >
            {badge}
          </span>
        ) : null}
      </div>
      {unitPrice ? (
        <p
          className={`mt-1.5 flex flex-wrap items-center gap-x-1.5 text-xs font-semibold ${vitrinGorunum.fiyat.birim}`}
        >
          <span>{unitPrice.miktar}</span>
          <span aria-hidden="true">·</span>
          <span className={vitrinGorunum.fiyat.birimDeger}>{unitPrice.birimFiyat}</span>
        </p>
      ) : null}

      {!isService && variantGroups.length > 0 ? (
        <div className="mt-5 space-y-4 border-t border-white/10 pt-5">
          {variantGroups.map((group) => (
            <div key={group.key}>
              <p className="mb-2 text-[10px] font-extrabold uppercase tracking-wider text-slate-400">
                {group.label}
              </p>
              <div className="flex flex-wrap gap-2">
                {group.values.map((value) => {
                  const selected = selectedOptions[group.key] === value;
                  const available = isOptionAvailable(group.key, value);
                  return (
                    <button
                      key={value}
                      type="button"
                      onClick={() => onSelectOption(group.key, value)}
                      disabled={!available}
                      className={`min-h-10 rounded-xl border px-3 text-xs font-extrabold transition ${
                        selected
                          ? "border-blue-400 bg-blue-500/20 text-white ring-2 ring-blue-400/15"
                          : available
                            ? "border-white/10 bg-white/[0.03] text-slate-300 hover:border-blue-500/35"
                            : "cursor-not-allowed border-white/5 bg-white/[0.02] text-slate-600 line-through"
                      }`}
                      aria-pressed={selected}
                      aria-disabled={!available}
                    >
                      {value}
                    </button>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      ) : null}

      {!isService && (stokDurumu || stockQuantity != null) ? (
        <div className="mt-4 flex flex-wrap items-center gap-2">
          {stokDurumu ? (
            <span className={`text-xs font-extrabold ${stockTone(stokDurumu)}`}>{stokDurumu}</span>
          ) : null}
          {stockQuantity != null ? (
            <span className="rounded-md border border-white/10 bg-white/[0.04] px-2 py-1 text-[11px] font-bold text-slate-400">
              {stockQuantity} adet
            </span>
          ) : null}
        </div>
      ) : null}

      {facts.length > 0 ? (
        // Ozellikler ince satir listesi olarak cizilir: etiket solda, deger
        // sagda. Onceki iki sutunlu kutu duzeni tek sayida bilgide yaninda
        // bos hucre birakiyordu.
        <dl className="mt-5 flex flex-col">
          {facts.map((fact) => (
            <div
              key={fact.key}
              className="flex items-baseline justify-between gap-4 border-b border-white/8 py-2 last:border-b-0"
            >
              <dt className="shrink-0 text-[11px] font-semibold text-slate-400">{fact.label}</dt>
              <dd className="min-w-0 break-words text-right text-xs font-bold leading-5 text-slate-200">
                {fact.value}
              </dd>
            </div>
          ))}
        </dl>
      ) : null}

      <ManufacturerProductSource source={manufacturerSource} />

      <ProductLocationPanel
        isService={isService}
        fulfillmentRegion={fulfillmentRegion}
        storeLocationLabel={storeLocationLabel}
        storeAddress={storeAddress}
        storeMapUrl={storeMapUrl}
      />

      {description ? (
        <p
          className={`mt-5 whitespace-pre-wrap text-sm font-medium leading-6 text-slate-300 ${
            clampDescription ? "line-clamp-3" : ""
          }`}
        >
          {description}
        </p>
      ) : null}

      {children}
    </>
  );
}
