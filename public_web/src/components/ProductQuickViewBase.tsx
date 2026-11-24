"use client";

import {
  birimFiyatBilgisi,
  eskiFiyatYazisi,
  indirimOrani,
  tutarYazisi,
} from "@/lib/productCardPresentation";
import { vitrinGorunum } from "@/lib/vitrinGorunum";
import Image from "next/image";
import { useEffect, useMemo, useState } from "react";
import type { RichProductItem } from "@/lib/richProductItem";
import { MAX_PRODUCT_IMAGES } from "@/lib/productImagePolicy";
import {
  buildConsumerDetailFacts,
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
import {
  ProductInfoBody,
  productImageAlt,
  productLocationLabel,
  productMapsUrl,
} from "@/components/ProductSurfaceShared";
import { TelifKalkani, urunTelifKalkanliMi } from "@/components/ProductDetailExperienceBase";

export { formatVariantPrice, stockTone } from "@/components/ProductSurfaceShared";

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
  storeDistrictName?: string | null;
  storeNeighborhoodName?: string | null;
  storeProvinceName?: string | null;
  storeMapsUrl?: string | null;
  isOwner?: boolean;
  onClose: () => void;
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
  storeDistrictName = null,
  storeNeighborhoodName = null,
  storeProvinceName = null,
  storeMapsUrl = null,
  isOwner = false,
  onClose,
}: ProductQuickViewProps) {
  const metadata = useMemo(
    () => normalizeProductMetadata(product.metadata),
    [product.metadata],
  );
  const isService = productIsService(product.metadata);
  const telifKalkanli = urunTelifKalkanliMi(product, isOwner);
  const variants = useMemo(
    () => productVariantsForTemplate(product.variants, metadata.templateKey, metadata.lunaInvoice),
    [product.variants, metadata.templateKey, metadata.lunaInvoice],
  );
  const variantGroups = useMemo(
    () => buildVariantOptionGroups(product.variants, metadata.templateKey, metadata.lunaInvoice),
    [product.variants, metadata.templateKey, metadata.lunaInvoice],
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
    () => findMatchingVariant(product.variants, selectedOptions, metadata.templateKey, metadata.lunaInvoice),
    [product.variants, selectedOptions, metadata.templateKey, metadata.lunaInvoice],
  );

  const displayImages = useMemo(() => {
    if (telifKalkanli) return [];
    const variantImages = selectedVariant?.imageUrls || [];
    return Array.from(new Set([...variantImages, ...images])).slice(0, metadata.lunaInvoice ? Infinity : MAX_PRODUCT_IMAGES);
  }, [images, selectedVariant, metadata.lunaInvoice, telifKalkanli]);

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
        metadata.templateKey, metadata.lunaInvoice,
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

  const isOptionAvailable = (key: string, value: string) =>
    variantOptionIsAvailable(
      product.variants,
      selectedOptions,
      key,
      value,
      metadata.templateKey, metadata.lunaInvoice,
    );

  const quickFacts = buildConsumerDetailFacts({
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
  const seciliFiyat = selectedVariant?.priceAmount ?? product.priceAmount ?? null;
  const fiyatTutar =
    typeof seciliFiyat === "number" && Number.isFinite(seciliFiyat) && seciliFiyat > 0
      ? seciliFiyat
      : null;
  const displayedPrice =
    fiyatTutar != null ? tutarYazisi(fiyatTutar) : product.price || "Fiyat sorun";
  const indirim =
    !isService && fiyatTutar != null
      ? indirimOrani({ priceAmount: fiyatTutar, oldPriceAmount: product.oldPriceAmount })
      : null;
  const miktarBilgisi = isService ? null : birimFiyatBilgisi(product.metadata, fiyatTutar);
  const rozet = String(product.badgeTag || "").trim() || null;
  const fulfillmentRegion = String(product.fulfillmentRegion || "").trim();
  const storeLocationLabel =
    productLocationLabel({
      neighborhoodName: storeNeighborhoodName,
      districtName: storeDistrictName,
      provinceName: storeProvinceName,
    }) || String(storeLocationText || "").trim();
  const storeDirectionsUrl =
    storeMapsUrl || productMapsUrl(storeLocationText || storeLocationLabel);
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
  const gorselAlt = productImageAlt({
    name: product.name,
    storeName,
    locality: storeDistrictName || storeNeighborhoodName,
  });

  return (
    <div
      className="fixed inset-0 z-[90] flex items-end justify-center bg-slate-950/80 p-0 backdrop-blur-md sm:items-center sm:p-5"
      role="presentation"
      onMouseDown={(event) => {
        if (event.currentTarget === event.target) onClose();
      }}
    >
      <div
        className="relative grid max-h-[94vh] w-full max-w-5xl overflow-y-auto rounded-t-[28px] border border-blue-500/20 bg-[#081321] shadow-[0_30px_100px_rgba(0,0,0,0.6)] sm:max-h-[90vh] sm:grid-cols-[1.02fr_0.98fr] sm:grid-rows-[minmax(0,90vh)] sm:overflow-hidden sm:rounded-[28px]"
        role="dialog"
        aria-modal="true"
        aria-labelledby="product-quick-view-title"
      >
        <button
          type="button"
          onClick={onClose}
          className="absolute right-4 top-4 z-30 flex h-10 w-10 items-center justify-center rounded-full border border-white/15 bg-slate-950/80 text-xl text-white backdrop-blur hover:bg-slate-900"
          aria-label="Hızlı incelemeyi kapat"
        >
          ×
        </button>

        <div className="relative bg-slate-950 p-2.5 sm:min-h-[610px]">
          <div className={`relative aspect-[4/5] overflow-hidden rounded-[22px] ${!telifKalkanli && currentImage ? "bg-white" : "bg-slate-900"} sm:h-full sm:min-h-[590px] sm:aspect-auto`}>
            {telifKalkanli ? (
              <TelifKalkani />
            ) : currentImage ? (
              <Image
                src={currentImage}
                alt={gorselAlt}
                fill
                sizes="(max-width: 640px) 100vw, 50vw"
                className="object-contain object-center p-3"
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
                    className={`relative h-14 w-14 shrink-0 overflow-hidden rounded-lg border bg-white transition ${
                      index === imageIndex
                        ? "border-blue-400 ring-2 ring-blue-400/20"
                        : "border-white/15 opacity-75 hover:opacity-100"
                    }`}
                    aria-label={`${index + 1}. ürün fotoğrafını göster`}
                  >
                    <Image
                      src={imageUrl}
                      alt=""
                      fill
                      sizes="56px"
                      className="object-contain p-1"
                    />
                  </button>
                ))}
              </div>
            </>
          ) : null}

        </div>

        <div className="min-h-0 overflow-y-auto p-5 sm:p-8">
          <ProductInfoBody
            isService={isService}
            category={product.category}
            name={product.name}
            brand={product.brand}
            heading="h2"
            headingId="product-quick-view-title"
            displayedPrice={displayedPrice}
            discountPercent={indirim}
            oldPriceText={eskiFiyatYazisi(product.oldPriceAmount)}
            badge={rozet}
            unitPrice={miktarBilgisi}
            variantGroups={variantGroups}
            selectedOptions={selectedOptions}
            onSelectOption={selectOption}
            isOptionAvailable={isOptionAvailable}
            stockStatus={selectedStockStatus}
            stockQuantity={selectedStockQuantity}
            facts={quickFacts}
            manufacturerSource={metadata.manufacturerSource}
            fulfillmentRegion={fulfillmentRegion}
            storeLocationLabel={storeLocationLabel}
            storeAddress={storeLocationText}
            storeMapUrl={storeDirectionsUrl}
            description={product.description}
            clampDescription
          >
            <div className="mt-6 grid gap-2 sm:grid-cols-2">
              {whatsappUrl ? (
                <a
                  href={whatsappUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={`flex min-h-12 items-center justify-center rounded-xl px-5 text-center text-sm font-extrabold ${vitrinGorunum.buton.whatsapp}`}
                >
                  {isService ? "WhatsApp'tan hizmeti sor" : "WhatsApp'tan ürünü sor"}
                </a>
              ) : null}
              <a
                href={productUrl}
                className={`flex min-h-12 items-center justify-center rounded-xl px-5 text-center text-sm font-extrabold ${vitrinGorunum.buton.ikincil}`}
              >
                {isService ? "Tüm hizmet detayları" : "Tüm ürün detayları"}
              </a>
            </div>

            <ProductCommercePanel
              storeSlug={storeSlug}
              productSlug={productSlug}
              productName={product.name}
              imageUrl={telifKalkanli ? null : currentImage}
              priceText={displayedPrice}
              priceAmount={fiyatTutar}
              selectedVariantText={selectedVariantText}
              selectedVariantId={selectedVariant?.id ?? null}
              stockQuantity={selectedStockQuantity}
              cartEnabled={
                !isService &&
                selectedStockQuantity !== 0 &&
                !String(selectedStockStatus || "").toLocaleLowerCase("tr-TR").includes("tükendi")
              }
              enabled={commerceEnabled}
              cartDisabledReason={
                isService
                  ? "Hizmetler sipariş sepetine eklenmez; WhatsApp üzerinden bilgi alabilirsin."
                  : String(selectedStockStatus || "").toLocaleLowerCase("tr-TR").includes("tükendi")
                    ? "Bu seçenek şu anda stokta görünmüyor."
                    : ""
              }
            />
          </ProductInfoBody>
        </div>
      </div>
    </div>
  );
}
