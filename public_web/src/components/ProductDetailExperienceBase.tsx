"use client";

import {
  birimFiyatBilgisi,
  eskiFiyatYazisi,
  indirimOrani,
  tutarYazisi,
} from "@/lib/productCardPresentation";
import Image from "next/image";
import Link from "next/link";
import { useMemo, useState } from "react";
import { TrackedWhatsAppLink } from "@/components/TrackedWhatsAppLink";
import ProductCommercePanel from "@/components/ProductCommercePanel";
import {
  ProductInfoBody,
  productImageAlt,
  productLocationLabel,
  productMapsUrl,
} from "@/components/ProductSurfaceShared";
import type { RichProductItem } from "@/lib/richProductItem";
import { MAX_PRODUCT_IMAGES } from "@/lib/productImagePolicy";
import {
  buildVariantOptionGroups,
  findMatchingVariant,
  productVariantsForTemplate,
  variantOptionIsAvailable,
  type ProductQuickFact,
} from "@/lib/productCardPresentation";
import { normalizeProductMetadata } from "@/lib/productRichData";
import { vitrinGorunum } from "@/lib/vitrinGorunum";

export { formatVariantPrice, stockTone } from "@/components/ProductSurfaceShared";

export type TelifAnahtari = `gorsel${"Izin"}${"Bekliyor"}`;
export const TELIF_ANAHTARI: TelifAnahtari = `gorsel${"Izin"}${"Bekliyor"}`;

export function urunTelifKalkanliMi(
  product: Partial<Record<TelifAnahtari, unknown>>,
  isOwner = false,
): boolean {
  return Boolean(product[TELIF_ANAHTARI]) && !isOwner;
}

export function TelifKalkani() {
  return (
    <div
      data-testid="telif-kalkani"
      className="flex h-full flex-col items-center justify-center bg-gradient-to-br from-slate-900 via-slate-950 to-slate-900 px-4 text-center"
    >
      <span
        data-testid="telif-kalkani-rozet"
        className="inline-flex items-center gap-1.5 rounded-full border border-amber-400/30 bg-amber-500/10 px-2.5 py-1 text-xs font-bold text-amber-300 shadow-sm"
      >
        <svg
          className="h-3.5 w-3.5 text-amber-400"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          aria-hidden="true"
        >
          <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
        </svg>
        Fotoğraf üreticide
      </span>
      <span className="mt-1.5 text-[10px] font-medium text-slate-500">
        Telif onayı bekleniyor
      </span>
    </div>
  );
}

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
  storeDistrictName?: string | null;
  storeNeighborhoodName?: string | null;
  storeProvinceName?: string | null;
  isOwner?: boolean;
}

export function whatsappWithVariantSelection(
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
  storeDistrictName = null,
  storeNeighborhoodName = null,
  storeProvinceName = null,
  isOwner = false,
}: ProductDetailExperienceProps) {
  const metadata = useMemo(() => normalizeProductMetadata(product.metadata), [product.metadata]);
  const isService = metadata.itemKind === "service";
  const telifKalkanli = urunTelifKalkanliMi(product, isOwner);
  const variants = useMemo(
    () => productVariantsForTemplate(product.variants, metadata.templateKey, metadata.lunaInvoice),
    [product.variants, metadata.templateKey, metadata.lunaInvoice],
  );
  const groups = useMemo(
    () => buildVariantOptionGroups(product.variants, metadata.templateKey, metadata.lunaInvoice),
    [product.variants, metadata.templateKey, metadata.lunaInvoice],
  );
  const variantKeys = useMemo(
    () => new Set(groups.map((group) => group.key)),
    [groups],
  );
  const [selectedOptions, setSelectedOptions] = useState<Record<string, string>>(
    variants[0] ? { ...variants[0].options } : {},
  );
  const selectedVariant = useMemo(
    () => findMatchingVariant(product.variants, selectedOptions, metadata.templateKey, metadata.lunaInvoice),
    [product.variants, selectedOptions, metadata.templateKey, metadata.lunaInvoice],
  );
  const gallery = useMemo(
    () =>
      telifKalkanli
        ? []
        : Array.from(new Set([...(selectedVariant?.imageUrls || []), ...images])).slice(0, metadata.lunaInvoice ? Infinity : MAX_PRODUCT_IMAGES),
    [images, selectedVariant, metadata.lunaInvoice, telifKalkanli],
  );
  const [imageIndex, setImageIndex] = useState(0);

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

  const currentImage = gallery[imageIndex] || null;
  const rozet = String(product.badgeTag || "").trim() || null;
  const hamFiyat = selectedVariant?.priceAmount ?? product.priceAmount ?? null;
  const fiyatTutar =
    typeof hamFiyat === "number" && Number.isFinite(hamFiyat) && hamFiyat > 0 ? hamFiyat : null;
  const displayedPrice = fiyatTutar != null ? tutarYazisi(fiyatTutar) : product.price || "Fiyat sorun";
  const oran =
    !isService && fiyatTutar != null
      ? indirimOrani({
          priceAmount: fiyatTutar,
          oldPriceAmount: product.oldPriceAmount,
        })
      : null;
  const miktarBilgisi = isService ? null : birimFiyatBilgisi(product.metadata, fiyatTutar);
  const stockQuantity = selectedVariant?.stockQuantity ?? product.stockQuantity ?? null;
  const stockStatus =
    stockQuantity === 0
      ? "Tükendi"
      : selectedVariant?.stockStatus || product.stockStatus || undefined;
  const tukendi =
    stockQuantity === 0 ||
    String(stockStatus || "")
      .toLocaleLowerCase("tr-TR")
      .includes("tükendi");
  const fulfillmentRegion = String(product.fulfillmentRegion || "").trim();
  const storeLocationLabel = productLocationLabel({
    neighborhoodName: storeNeighborhoodName,
    districtName: storeDistrictName,
    provinceName: storeProvinceName,
  });
  const storeMapUrl = productMapsUrl(storeAddress);
  const gorselAlt = productImageAlt({
    name: product.name,
    storeName,
    locality: storeDistrictName || storeNeighborhoodName,
  });
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
          <div className={`rounded-3xl ${vitrinGorunum.yuzey.panel} p-2.5`}>
            <div className="relative aspect-[4/5] overflow-hidden rounded-2xl bg-slate-950">
              {telifKalkanli ? (
                <TelifKalkani />
              ) : currentImage ? (
                <Image
                  src={currentImage}
                  alt={gorselAlt}
                  fill
                  sizes="(max-width: 1024px) 100vw, 55vw"
                  className={metadata.lunaInvoice ? "object-contain p-3" : "object-cover"}
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
                    <Image
                      src={imageUrl}
                      alt={`${gorselAlt} - ${index + 1}. fotoğraf`}
                      fill
                      sizes="56px"
                      className={metadata.lunaInvoice ? "object-contain p-1" : "object-cover"}
                    />
                  </button>
                ))}
              </div>
            ) : null}
          </div>

          <aside className={`rounded-3xl ${vitrinGorunum.yuzey.panel} p-5 sm:p-7`}>
            <ProductInfoBody
              isService={isService}
              category={product.category}
              name={product.name}
              brand={product.brand}
              heading="h1"
              displayedPrice={displayedPrice}
              discountPercent={oran}
              oldPriceText={eskiFiyatYazisi(product.oldPriceAmount)}
              badge={rozet}
              unitPrice={miktarBilgisi}
              variantGroups={groups}
              selectedOptions={selectedOptions}
              onSelectOption={selectOption}
              isOptionAvailable={isOptionAvailable}
              stockStatus={stockStatus}
              stockQuantity={stockQuantity}
              facts={visibleDetailFacts}
              manufacturerSource={metadata.manufacturerSource}
              fulfillmentRegion={fulfillmentRegion}
              storeLocationLabel={storeLocationLabel}
              storeAddress={storeAddress}
              storeMapUrl={storeMapUrl}
              description={product.description}
            >
              <div className="mt-6 grid gap-2 sm:grid-cols-2">
                {selectedWhatsappUrl ? (
                  <TrackedWhatsAppLink
                    href={selectedWhatsappUrl}
                    storeSlug={storeSlug}
                    productSlug={productSlug}
                    clickLocation="product_detail"
                    className={`flex min-h-12 items-center justify-center rounded-xl px-5 text-center text-sm font-extrabold ${vitrinGorunum.buton.whatsapp}`}
                  >
                    {isService ? "WhatsApp’tan hizmeti sor" : "WhatsApp’tan ürünü sor"}
                  </TrackedWhatsAppLink>
                ) : null}
                {instagramUrl ? (
                  <Link
                    href={instagramUrl}
                    className={`flex min-h-12 items-center justify-center rounded-xl px-5 text-center text-sm font-extrabold ${vitrinGorunum.buton.ikincil}`}
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

              <div className="mt-6 border-t border-white/10 pt-5">
                <ProductCommercePanel
                  storeSlug={storeSlug}
                  productSlug={productSlug}
                  productName={product.name}
                  imageUrl={telifKalkanli ? null : currentImage}
                  priceText={displayedPrice}
                  priceAmount={fiyatTutar}
                  selectedVariantText={selectedVariantText}
                  selectedVariantId={selectedVariant?.id ?? null}
                  stockQuantity={stockQuantity}
                  cartEnabled={!isService && !tukendi}
                  cartDisabledReason={
                    isService
                      ? "Hizmetler sipariş sepetine eklenmez; WhatsApp üzerinden bilgi alabilirsin."
                      : tukendi
                        ? "Bu ürün şu anda tükendi."
                        : ""
                  }
                />
              </div>
            </ProductInfoBody>
          </aside>
        </div>
      </section>
    </main>
  );
}
