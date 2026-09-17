"use client";

import { eskiFiyatYazisi } from "@/lib/productCardPresentation";
import Image from "next/image";
import Link from "next/link";
import { useMemo, useState } from "react";
import { TrackedWhatsAppLink } from "@/components/TrackedWhatsAppLink";
import type { RichProductItem } from "@/lib/richProductItem";
import { MapPinIcon } from "@/lib/vitrinBrandIcons";
import { MAX_PRODUCT_IMAGES } from "@/lib/productImagePolicy";
import {
  buildVariantOptionGroups,
  findMatchingVariant,
  productVariantsForTemplate,
  variantOptionIsAvailable,
  type ProductQuickFact,
} from "@/lib/productCardPresentation";
import { normalizeProductMetadata } from "@/lib/productRichData";

interface ProductDetailExperienceProps {
  product: RichProductItem;
  images: string[];
  storeName: string;
  storeSlug: string;
  storeUrl: string;
  productSlug: string;
  detailFacts: ProductQuickFact[];
  whatsappUrl?: string | null;
  instagramUrl?: string | null;
  sourceUrl?: string | null;
  storeAddress?: string | null;
}

function formatVariantPrice(amount: number, currency?: string) {
  return new Intl.NumberFormat("tr-TR", {
    style: "currency",
    currency: currency || "TRY",
    maximumFractionDigits: 2,
  }).format(amount);
}

function mapsSearchUrl(value: string | null | undefined) {
  const clean = String(value || "").trim();
  if (!clean) return null;
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(clean)}`;
}

function stockTone(status?: string | null) {
  const value = String(status || "").toLocaleLowerCase("tr-TR");
  if (value.includes("tükendi")) return "text-red-300";
  if (value.includes("son") || value.includes("az") || value.includes("sınırl")) {
    return "text-amber-300";
  }
  return "text-emerald-300";
}

function whatsappWithVariantSelection(
  url: string | null,
  selectedVariantText: string,
): string | null {
  if (!url || !selectedVariantText) return url;
  try {
    const parsed = new URL(url);
    const current = parsed.searchParams.get("text") || "";
    parsed.searchParams.set(
      "text",
      `${current}${current ? "\n" : ""}Seçenek: ${selectedVariantText}`,
    );
    return parsed.toString();
  } catch {
    return url;
  }
}

export default function ProductDetailExperience({
  product,
  images,
  storeName,
  storeSlug,
  storeUrl,
  productSlug,
  detailFacts,
  whatsappUrl = null,
  instagramUrl = null,
  sourceUrl = null,
  storeAddress = null,
}: ProductDetailExperienceProps) {
  const metadata = useMemo(() => normalizeProductMetadata(product.metadata), [product.metadata]);
  const isService = metadata.itemKind === "service";
  const variants = useMemo(
    () => productVariantsForTemplate(product.variants, metadata.templateKey),
    [product.variants, metadata.templateKey],
  );
  const groups = useMemo(
    () => buildVariantOptionGroups(product.variants, metadata.templateKey),
    [product.variants, metadata.templateKey],
  );
  const variantKeys = useMemo(
    () => new Set(groups.map((group) => group.key)),
    [groups],
  );
  const [selectedOptions, setSelectedOptions] = useState<Record<string, string>>(
    variants[0] ? { ...variants[0].options } : {},
  );
  const selectedVariant = useMemo(
    () => findMatchingVariant(product.variants, selectedOptions, metadata.templateKey),
    [product.variants, selectedOptions, metadata.templateKey],
  );
  const gallery = useMemo(
    () => Array.from(new Set([...(selectedVariant?.imageUrls || []), ...images])).slice(0, MAX_PRODUCT_IMAGES),
    [images, selectedVariant],
  );
  const [imageIndex, setImageIndex] = useState(0);

  const selectOption = (key: string, value: string) => {
    if (
      !variantOptionIsAvailable(
        product.variants,
        selectedOptions,
        key,
        value,
        metadata.templateKey,
      )
    ) {
      return;
    }
    const preferred = variants.find(
      (variant) =>
        variant.options[key] === value &&
        Object.entries(selectedOptions).every(([otherKey, otherValue]) =>
          otherKey === key ? true : !otherValue || variant.options[otherKey] === otherValue,
        ),
    );
    const fallback = variants.find((variant) => variant.options[key] === value);
    const next = preferred || fallback;
    if (next) {
      setSelectedOptions({ ...next.options });
      setImageIndex(0);
    }
  };

  const currentImage = gallery[imageIndex] || null;
  const displayedPrice =
    selectedVariant?.priceAmount != null
      ? formatVariantPrice(selectedVariant.priceAmount, product.currency)
      : product.price || "Fiyat sorun";
  const stockQuantity = selectedVariant?.stockQuantity ?? product.stockQuantity ?? null;
  const stockStatus =
    stockQuantity === 0
      ? "Tükendi"
      : selectedVariant?.stockStatus || product.stockStatus || undefined;
  const fulfillmentRegion = String(product.fulfillmentRegion || "").trim();
  const productMapUrl = mapsSearchUrl(fulfillmentRegion);
  const storeMapUrl = mapsSearchUrl(storeAddress);
  const visibleDetailFacts = detailFacts.filter((fact) => !variantKeys.has(fact.key));
  const selectedVariantText = groups
    .map((group) => {
      const value = selectedOptions[group.key];
      return value ? `${group.label}: ${value}` : null;
    })
    .filter((value): value is string => Boolean(value))
    .join(", ");
  const selectedWhatsappUrl = whatsappWithVariantSelection(
    whatsappUrl,
    selectedVariantText,
  );

  return (
    <main className="min-h-screen bg-[#0c0d10] px-4 py-6 text-[#f4f1ea] sm:px-6 sm:py-10">
      <section className="mx-auto w-full max-w-[1120px]">
        <Link
          href={storeUrl}
          className="mb-5 inline-flex rounded-full border border-white/10 bg-white/[0.03] px-4 py-2 text-xs font-extrabold text-white/70 transition hover:border-blue-500/30 hover:text-white"
        >
          ← {storeName} vitrinine dön
        </Link>

        <div className="grid gap-5 lg:grid-cols-[minmax(0,0.92fr)_minmax(360px,0.78fr)]">
          <div className="rounded-[26px] border border-white/8 bg-[#15171c] p-2.5">
            <div className="relative aspect-[4/5] overflow-hidden rounded-[21px] bg-[#1c1f27]">
              {currentImage ? (
                <Image
                  src={currentImage}
                  alt={product.name}
                  fill
                  sizes="(max-width: 1024px) 100vw, 55vw"
                  className="object-cover"
                  priority
                />
              ) : (
                <div className="flex h-full items-center justify-center text-sm font-bold text-white/40">
                  {isService ? "Hizmet görseli bekleniyor" : "Ürün görseli bekleniyor"}
                </div>
              )}
            </div>
            {gallery.length > 1 ? (
              <div className="mt-2.5 flex gap-2 overflow-x-auto pb-1">
                {gallery.map((imageUrl, index) => (
                  <button
                    key={`${imageUrl}-${index}`}
                    type="button"
                    onClick={() => setImageIndex(index)}
                    className={`relative h-16 w-14 shrink-0 overflow-hidden rounded-xl border transition ${
                      index === imageIndex
                        ? "border-blue-400 ring-2 ring-blue-400/15"
                        : "border-white/10 opacity-70 hover:opacity-100"
                    }`}
                    aria-label={`${index + 1}. görseli göster`}
                  >
                    <Image src={imageUrl} alt="" fill sizes="56px" className="object-cover" />
                  </button>
                ))}
              </div>
            ) : null}
          </div>

          <aside className="rounded-[26px] border border-white/8 bg-[#15171c] p-5 sm:p-7">
            {product.category ? (
              <span className="inline-flex rounded-full border border-blue-500/20 bg-blue-500/10 px-3 py-1 text-[10px] font-extrabold uppercase tracking-wider text-blue-300">
                {product.category}
              </span>
            ) : null}
            <h1 className="font-vitrin-display mt-4 text-[clamp(2rem,5vw,3.1rem)] font-normal leading-[1.02] text-white">
              {product.name}
            </h1>
            {!isService && product.brand ? (
              <p className="mt-2 text-xs font-bold uppercase tracking-[0.13em] text-white/40">
                {product.brand}
              </p>
            ) : null}

            <div className="mt-5 flex flex-wrap items-baseline gap-3">
              <span className="text-2xl font-extrabold text-[#E8A87C]">{displayedPrice}</span>
              {eskiFiyatYazisi(product.oldPriceAmount) ? (
                <span className="text-sm font-medium text-white/30 line-through">
                  {eskiFiyatYazisi(product.oldPriceAmount)}
                </span>
              ) : null}
            </div>

            {!isService && groups.length > 0 ? (
              <div className="mt-6 space-y-5 border-t border-white/10 pt-5">
                {groups.map((group) => (
                  <div key={group.key}>
                    <p className="mb-2 text-[10px] font-extrabold uppercase tracking-wider text-white/35">
                      {group.label}
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {group.values.map((value) => {
                        const selected = selectedOptions[group.key] === value;
                        const available = variantOptionIsAvailable(
                          product.variants,
                          selectedOptions,
                          group.key,
                          value,
                          metadata.templateKey,
                        );
                        return (
                          <button
                            key={value}
                            type="button"
                            onClick={() => selectOption(group.key, value)}
                            disabled={!available}
                            className={`min-h-10 rounded-xl border px-3 text-xs font-extrabold transition ${
                              selected
                                ? "border-blue-400 bg-blue-500/20 text-white ring-2 ring-blue-400/15"
                                : available
                                  ? "border-white/10 bg-white/[0.03] text-white/65 hover:border-blue-500/35"
                                  : "cursor-not-allowed border-white/5 bg-white/[0.02] text-white/20 line-through"
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

            {!isService && (stockStatus || stockQuantity != null) ? (
              <div className="mt-4 flex flex-wrap items-center gap-2">
                {stockStatus ? (
                  <span className={`text-xs font-extrabold ${stockTone(stockStatus)}`}>
                    {stockStatus}
                  </span>
                ) : null}
                {stockQuantity != null ? (
                  <span className="rounded-md border border-white/10 bg-white/[0.04] px-2 py-1 text-[11px] font-bold text-white/40">
                    {stockQuantity} adet
                  </span>
                ) : null}
              </div>
            ) : null}

            {product.description ? (
              <p className="mt-6 whitespace-pre-wrap text-sm font-medium leading-6 text-white/65">
                {product.description}
              </p>
            ) : null}

            {(fulfillmentRegion || storeAddress) ? (
              <div className="mt-6 rounded-2xl border border-blue-500/20 bg-gradient-to-br from-blue-500/10 to-cyan-500/5 p-4">
                <div className="flex items-start gap-3">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-blue-500/15">
                    <MapPinIcon className="h-4 w-4 text-blue-300" aria-hidden="true" />
                  </div>
                  <div className="min-w-0 flex-1">
                    {fulfillmentRegion ? (
                      <div>
                        <p className="text-[10px] font-extrabold uppercase tracking-wider text-blue-300">
                          {isService ? "Hizmet bölgesi" : "Ürün konumu / teslim bölgesi"}
                        </p>
                        <p className="mt-1 text-xs font-semibold leading-5 text-white/75">
                          {fulfillmentRegion}
                        </p>
                        {productMapUrl ? (
                          <a
                            href={productMapUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="mt-1.5 inline-flex text-xs font-extrabold text-blue-400"
                          >
                            Haritada ara →
                          </a>
                        ) : null}
                      </div>
                    ) : null}
                    {storeAddress ? (
                      <div className={fulfillmentRegion ? "mt-3 border-t border-white/10 pt-3" : ""}>
                        <p className="text-[10px] font-extrabold uppercase tracking-wider text-white/35">
                          İşletme konumu
                        </p>
                        <p className="mt-1 text-xs font-semibold leading-5 text-white/75">
                          {storeAddress}
                        </p>
                        {storeMapUrl ? (
                          <a
                            href={storeMapUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="mt-1.5 inline-flex text-xs font-extrabold text-blue-400"
                          >
                            Yol tarifi →
                          </a>
                        ) : null}
                      </div>
                    ) : null}
                  </div>
                </div>
              </div>
            ) : null}

            <div className="mt-6 grid gap-2 sm:grid-cols-2">
              {selectedWhatsappUrl ? (
                <TrackedWhatsAppLink
                  href={selectedWhatsappUrl}
                  storeSlug={storeSlug}
                  productSlug={productSlug}
                  clickLocation="product_detail"
                  className="flex min-h-12 items-center justify-center rounded-xl bg-[#25D366] px-5 text-center text-sm font-extrabold text-[#04140a]"
                >
                  {isService ? "WhatsApp’tan hizmeti sor" : "WhatsApp’tan ürünü sor"}
                </TrackedWhatsAppLink>
              ) : null}
              {instagramUrl ? (
                <Link
                  href={instagramUrl}
                  className="flex min-h-12 items-center justify-center rounded-xl border border-white/15 bg-white/5 px-5 text-center text-sm font-extrabold text-white"
                >
                  Instagram
                </Link>
              ) : null}
            </div>
            {sourceUrl ? (
              <Link
                href={sourceUrl}
                className="mt-2 flex min-h-11 items-center justify-center rounded-xl border border-white/10 px-5 text-center text-xs font-extrabold text-white/60"
              >
                Kaynak paylaşımı
              </Link>
            ) : null}
          </aside>
        </div>

        {visibleDetailFacts.length > 0 ? (
          <section className="mt-6 overflow-hidden rounded-[24px] border border-white/8 bg-[#15171c]">
            <div className="border-b border-white/8 px-5 py-4 sm:px-6">
              <h2 className="text-lg font-extrabold text-white">
                {isService ? "Hizmet detayları" : "Ürün özellikleri"}
              </h2>
              <p className="mt-1 text-xs font-medium text-white/35">
                Yalnız işletmenin bu {isService ? "hizmet" : "ürün"} için girdiği gerçek bilgiler gösterilir.
              </p>
            </div>
            <dl>
              {visibleDetailFacts.map((fact) => (
                <div
                  key={fact.key}
                  className="grid border-b border-white/8 last:border-b-0 sm:grid-cols-[220px_minmax(0,1fr)]"
                >
                  <dt className="bg-white/[0.025] px-5 py-3 text-xs font-extrabold text-white/40 sm:px-6">
                    {fact.label}
                  </dt>
                  <dd className="px-5 py-3 text-sm font-semibold text-white/75 sm:px-6">
                    {fact.value}
                  </dd>
                </div>
              ))}
            </dl>
          </section>
        ) : null}
      </section>
    </main>
  );
}
