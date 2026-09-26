"use client";

import { eskiFiyatYazisi, kartRozeti } from "@/lib/productCardPresentation";
import Image from "next/image";
import { useEffect, useMemo, useState } from "react";
import type { RichProductItem } from "@/lib/richProductItem";
import { MapPinIcon } from "@/lib/vitrinBrandIcons";
import { MAX_PRODUCT_IMAGES } from "@/lib/productImagePolicy";
import {
  buildProductDetailFacts,
  buildVariantOptionGroups,
  findMatchingVariant,
  productVariantsForTemplate,
  variantOptionIsAvailable,
} from "@/lib/productCardPresentation";
import {
  normalizeProductMetadata,
  productIsService,
} from "@/lib/productRichData";
import ProductCommercePanel from "@/components/ProductCommercePanel";

interface ProductQuickViewProps {
  product: RichProductItem;
  images: string[];
  productUrl: string;
  storeName: string;
  storeSlug: string;
  productSlug: string;
  commerceEnabled?: boolean;
  whatsappBaseUrl?: string | null;
  storeLocationText?: string | null;
  storeMapsUrl?: string | null;
  onClose: () => void;
}

function productLocationMapUrl(location: string): string | null {
  const normalized = location.trim();
  if (!normalized) return null;
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(normalized)}`;
}

export function productWhatsappUrl(
  baseUrl: string | null | undefined,
  storeName: string,
  productName: string,
  isService: boolean,
  selectedVariantText: string,
): string | null {
  if (!baseUrl) return null;
  const noun = isService ? "hizmeti" : "ürünü";
  const optionLine = selectedVariantText ? `\nSeçenek: ${selectedVariantText}` : "";
  const message = `Merhaba, ${storeName} vitrininizdeki "${productName}" ${noun} hakkında bilgi almak istiyorum.${optionLine}`;
  const separator = baseUrl.includes("?") ? "&" : "?";
  return `${baseUrl}${separator}text=${encodeURIComponent(message)}`;
}

export function stockTone(stockStatus: string | undefined) {
  const value = String(stockStatus || "").toLocaleLowerCase("tr-TR");
  if (value.includes("tükendi")) return "text-red-300";
  if (value.includes("son") || value.includes("az") || value.includes("sınırl")) {
    return "text-amber-300";
  }
  return "text-emerald-300";
}

export function formatVariantPrice(amount: number, currency?: string) {
  return new Intl.NumberFormat("tr-TR", {
    style: "currency",
    currency: currency || "TRY",
    maximumFractionDigits: 2,
  }).format(amount);
}

export default function ProductQuickView({
  product,
  images,
  productUrl,
  storeName,
  storeSlug,
  productSlug,
  commerceEnabled = true,
  whatsappBaseUrl = null,
  storeLocationText = null,
  storeMapsUrl = null,
  onClose,
}: ProductQuickViewProps) {
  const metadata = useMemo(
    () => normalizeProductMetadata(product.metadata),
    [product.metadata],
  );
  const isService = productIsService(product.metadata);
  const variants = useMemo(
    () => productVariantsForTemplate(product.variants, metadata.templateKey),
    [product.variants, metadata.templateKey],
  );
  const variantGroups = useMemo(
    () => buildVariantOptionGroups(product.variants, metadata.templateKey),
    [product.variants, metadata.templateKey],
  );
  const variantKeys = useMemo(
    () => new Set(variantGroups.map((group) => group.key)),
    [variantGroups],
  );
  const [selectedOptions, setSelectedOptions] = useState<Record<string, string>>(
    variants[0] ? { ...variants[0].options } : {},
  );
  const [imageIndex, setImageIndex] = useState(0);

  const selectedVariant = useMemo(
    () => findMatchingVariant(product.variants, selectedOptions, metadata.templateKey),
    [product.variants, selectedOptions, metadata.templateKey],
  );

  const displayImages = useMemo(() => {
    const variantImages = selectedVariant?.imageUrls || [];
    return Array.from(new Set([...variantImages, ...images])).slice(0, MAX_PRODUCT_IMAGES);
  }, [images, selectedVariant]);

  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
      if (event.key === "ArrowLeft") {
        setImageIndex((current) => Math.max(0, current - 1));
      }
      if (event.key === "ArrowRight") {
        setImageIndex((current) =>
          Math.min(Math.max(0, displayImages.length - 1), current + 1),
        );
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [displayImages.length, onClose]);

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

  // Ayri bir urun detay sayfasi yok: esnafin girdigi kategori alanlarinin
  // tamami bu kartta gorunur. buildProductQuickFacts yalniz "hizli" yuzeyine
  // isaretli alanlari aliyordu; giyimde desen/beden sistemi, gidada
  // icindekiler/saklama/mensei hicbir yerde gorunmuyordu.
  const quickFacts = buildProductDetailFacts({
    brand: product.brand,
    barcode: product.barcode,
    metadata: product.metadata,
  }).filter((fact) => fact.key !== "brand" && !variantKeys.has(fact.key));

  const selectedStockQuantity =
    selectedVariant?.stockQuantity ?? product.stockQuantity ?? null;
  const selectedStockStatus =
    selectedStockQuantity === 0
      ? "Tükendi"
      : selectedVariant?.stockStatus || product.stockStatus || undefined;
  const displayedPrice =
    selectedVariant?.priceAmount != null
      ? formatVariantPrice(selectedVariant.priceAmount, product.currency)
      : product.price || "Fiyat sorun";
  const brand = String(product.brand || "").trim();
  const rozet = kartRozeti({
    badgeTag: product.badgeTag,
    priceAmount: product.priceAmount,
    oldPriceAmount: product.oldPriceAmount,
  });
  const fulfillmentRegion = String(product.fulfillmentRegion || "").trim();
  const fulfillmentMapUrl = productLocationMapUrl(fulfillmentRegion);
  const selectedVariantText = variantGroups
    .map((group) => {
      const value = selectedOptions[group.key];
      return value ? `${group.label}: ${value}` : null;
    })
    .filter((value): value is string => Boolean(value))
    .join(", ");
  const whatsappUrl = productWhatsappUrl(
    whatsappBaseUrl,
    storeName,
    product.name,
    isService,
    selectedVariantText,
  );
  const currentImage = displayImages[imageIndex] || null;

  return (
    <div
      className="fixed inset-0 z-[90] flex items-end justify-center bg-slate-950/80 p-0 backdrop-blur-md sm:items-center sm:p-5"
      role="presentation"
      onMouseDown={(event) => {
        if (event.currentTarget === event.target) onClose();
      }}
    >
      <div
        className="grid max-h-[94vh] w-full max-w-5xl overflow-y-auto rounded-t-[28px] border border-blue-500/20 bg-[#081321] shadow-[0_30px_100px_rgba(0,0,0,0.6)] sm:max-h-[90vh] sm:grid-cols-[1.02fr_0.98fr] sm:overflow-hidden sm:rounded-[28px]"
        role="dialog"
        aria-modal="true"
        aria-labelledby="product-quick-view-title"
      >
        <div className="relative bg-slate-950 p-2.5 sm:min-h-[610px]">
          <div className="relative aspect-[4/5] overflow-hidden rounded-[22px] bg-slate-900 sm:h-full sm:min-h-[590px] sm:aspect-auto">
            {currentImage ? (
              <Image
                src={currentImage}
                alt={product.name}
                fill
                sizes="(max-width: 640px) 100vw, 50vw"
                className="object-cover object-center"
                priority
              />
            ) : (
              <div className="flex h-full items-center justify-center text-sm font-bold text-slate-500">
                {isService ? "Hizmet görseli yok" : "Ürün görseli yok"}
              </div>
            )}
          </div>

          {displayImages.length > 1 ? (
            <>
              <button
                type="button"
                onClick={() => setImageIndex((current) => Math.max(0, current - 1))}
                disabled={imageIndex === 0}
                className="absolute left-5 top-1/2 z-20 flex h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full border border-white/15 bg-slate-950/80 text-xl font-bold text-white backdrop-blur disabled:opacity-30"
                aria-label="Önceki ürün fotoğrafı"
              >
                ‹
              </button>
              <button
                type="button"
                onClick={() =>
                  setImageIndex((current) =>
                    Math.min(displayImages.length - 1, current + 1),
                  )
                }
                disabled={imageIndex === displayImages.length - 1}
                className="absolute right-5 top-1/2 z-20 flex h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full border border-white/15 bg-slate-950/80 text-xl font-bold text-white backdrop-blur disabled:opacity-30"
                aria-label="Sonraki ürün fotoğrafı"
              >
                ›
              </button>
              <div className="absolute bottom-5 left-5 right-5 z-20 flex gap-2 overflow-x-auto pb-1">
                {displayImages.map((imageUrl, index) => (
                  <button
                    key={`${imageUrl}-${index}`}
                    type="button"
                    onClick={() => setImageIndex(index)}
                    className={`relative h-14 w-14 shrink-0 overflow-hidden rounded-lg border bg-slate-950/90 transition ${
                      index === imageIndex
                        ? "border-blue-400 ring-2 ring-blue-400/20"
                        : "border-white/15 opacity-75 hover:opacity-100"
                    }`}
                    aria-label={`${index + 1}. ürün fotoğrafını göster`}
                  >
                    <Image src={imageUrl} alt="" fill sizes="56px" className="object-cover" />
                  </button>
                ))}
              </div>
            </>
          ) : null}

          <button
            type="button"
            onClick={onClose}
            className="absolute right-5 top-5 z-30 flex h-10 w-10 items-center justify-center rounded-full border border-white/15 bg-slate-950/80 text-xl text-white backdrop-blur hover:bg-slate-900"
            aria-label="Hızlı incelemeyi kapat"
          >
            ×
          </button>
        </div>

        <div className="min-h-0 overflow-y-auto p-5 sm:p-8">
          {product.category ? (
            <p className="text-[10px] font-extrabold uppercase tracking-[0.14em] text-cyan-300">
              {product.category}
            </p>
          ) : null}
          <h2
            id="product-quick-view-title"
            className="mt-2 text-2xl font-black leading-tight tracking-tight text-white sm:text-3xl"
          >
            {product.name}
          </h2>
          {!isService && brand ? (
            <p className="mt-2 text-[10px] font-extrabold uppercase tracking-[0.13em] text-slate-500">
              {brand}
            </p>
          ) : null}

          <div className="mt-4 flex flex-wrap items-center gap-3">
            <p className="text-2xl font-black text-blue-400">{displayedPrice}</p>
            {eskiFiyatYazisi(product.oldPriceAmount) ? (
              <span className="text-sm font-medium text-slate-500 line-through">
                {eskiFiyatYazisi(product.oldPriceAmount)}
              </span>
            ) : null}
            {rozet ? (
              <span className="rounded-lg bg-gradient-to-r from-blue-600 to-cyan-600 px-2.5 py-1 text-[10px] font-extrabold text-white shadow-md">
                {rozet}
              </span>
            ) : null}
          </div>

          {!isService && variantGroups.length > 0 ? (
            <div className="mt-5 space-y-4 border-t border-white/10 pt-5">
              {variantGroups.map((group) => (
                <div key={group.key}>
                  <p className="mb-2 text-[10px] font-extrabold uppercase tracking-wider text-slate-500">
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

          {!isService && (selectedStockStatus || selectedStockQuantity != null) ? (
            <div className="mt-4 flex flex-wrap items-center gap-2">
              {selectedStockStatus ? (
                <span className={`text-xs font-extrabold ${stockTone(selectedStockStatus)}`}>
                  {selectedStockStatus}
                </span>
              ) : null}
              {selectedStockQuantity != null ? (
                <span className="rounded-md border border-white/10 bg-white/[0.04] px-2 py-1 text-[11px] font-bold text-slate-400">
                  {selectedStockQuantity} adet
                </span>
              ) : null}
            </div>
          ) : null}

          {quickFacts.length > 0 ? (
            // Ozellikler ince satir listesi olarak cizilir: etiket solda, deger
            // sagda. Onceki iki sutunlu kutu duzeni tek sayida bilgide yaninda
            // bos hucre birakiyordu.
            <dl className="mt-5 flex flex-col">
              {quickFacts.map((fact) => (
                <div
                  key={fact.key}
                  className="flex items-baseline justify-between gap-4 border-b border-white/8 py-2 last:border-b-0"
                >
                  <dt className="shrink-0 text-[11px] font-semibold text-slate-500">
                    {fact.label}
                  </dt>
                  <dd className="min-w-0 break-words text-right text-xs font-bold leading-5 text-slate-200">
                    {fact.value}
                  </dd>
                </div>
              ))}
            </dl>
          ) : null}

          <div className="mt-5 rounded-2xl border border-blue-500/20 bg-gradient-to-br from-blue-500/10 to-cyan-500/5 p-4">
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
                      <p className="mt-1 text-xs font-semibold leading-5 text-slate-200">
                        {fulfillmentRegion}
                      </p>
                      {fulfillmentMapUrl ? (
                        <a
                          href={fulfillmentMapUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="mt-1.5 inline-flex text-xs font-extrabold text-blue-400 hover:text-blue-300"
                        >
                          Haritada ara →
                        </a>
                      ) : null}
                    </div>
                  ) : null}
                  {storeLocationText ? (
                    <div className={fulfillmentRegion ? "mt-3 border-t border-white/10 pt-3" : ""}>
                      <p className="text-[10px] font-extrabold uppercase tracking-wider text-slate-500">
                        İşletme konumu
                      </p>
                      <p className="mt-1 text-xs font-semibold leading-5 text-slate-200">
                        {storeLocationText}
                      </p>
                      {storeMapsUrl ? (
                        <a
                          href={storeMapsUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="mt-1.5 inline-flex text-xs font-extrabold text-blue-400 hover:text-blue-300"
                        >
                          Yol tarifi →
                        </a>
                      ) : null}
                    </div>
                  ) : null}
                  {!fulfillmentRegion && !storeLocationText ? (
                    <p className="text-xs font-semibold leading-5 text-slate-300">
                      Bu {isService ? "hizmet" : "ürün"} için konum bilgisi eklenmemiş.
                    </p>
                  ) : null}
                </div>
              </div>
            </div>

          {product.description ? (
            <p className="mt-5 line-clamp-3 text-sm leading-6 text-slate-300">
              {product.description}
            </p>
          ) : null}

          <div className="mt-6 grid gap-2 sm:grid-cols-2">
            {whatsappUrl ? (
              <a
                href={whatsappUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="flex min-h-12 items-center justify-center rounded-xl bg-emerald-600 px-5 text-center text-sm font-extrabold text-white shadow-lg shadow-emerald-900/20 transition hover:bg-emerald-500"
              >
                {isService ? "WhatsApp'tan hizmeti sor" : "WhatsApp'tan ürünü sor"}
              </a>
            ) : null}
            <a
              href={productUrl}
              className={`flex min-h-12 items-center justify-center rounded-xl px-5 text-center text-sm font-extrabold transition ${
                whatsappUrl
                  ? "border border-white/10 bg-slate-900 text-slate-200 hover:border-blue-500/30 hover:text-white"
                  : "bg-gradient-to-r from-blue-600 to-cyan-500 text-white"
              }`}
            >
              {isService ? "Tüm hizmet detayları" : "Tüm ürün detayları"}
            </a>
          </div>

          <ProductCommercePanel
            storeSlug={storeSlug}
            productSlug={productSlug}
            productName={product.name}
            imageUrl={currentImage}
            priceText={displayedPrice}
            selectedVariantText={selectedVariantText}
            selectedVariantId={selectedVariant?.id ?? null}
            stockQuantity={selectedStockQuantity}
            cartEnabled={!isService && selectedStockQuantity !== 0}
            enabled={commerceEnabled}
            cartDisabledReason={isService ? "Hizmetler sipariş sepetine eklenmez; WhatsApp üzerinden bilgi alabilirsin." : ""}
          />
        </div>
      </div>
    </div>
  );
}
