"use client";

import Image from "next/image";
import { useSearchParams } from "next/navigation";
import { useCallback, useMemo, useState } from "react";
import ProductQuickView from "@/components/ProductQuickView";
import { TrackedDirectionsLink } from "@/components/TrackedContactLink";
import { MapPinIcon } from "@/lib/vitrinBrandIcons";
import { MAX_PRODUCT_IMAGES } from "@/lib/productImagePolicy";
import {
  getProductImages,
  getProductUrlSlug,
  isLikelyUiScreenshotUrl,
  isPublicCatalogProduct,
  resolveCatalogImage,
} from "@/lib/products";
import type { RichProductItem } from "@/lib/richProductItem";
import {
  buildProductCardFacts,
  eskiFiyatYazisi,
  indirimOrani,
  kartRozeti,
  productPhotoCountBadge,
  productVariantLabel,
} from "@/lib/productCardPresentation";
import { normalizeProductMetadata } from "@/lib/productRichData";

type CatalogProduct = RichProductItem;

interface CategoryItem {
  id: string;
  name: string;
}

interface ProductCatalogProps {
  storeSlug: string;
  storeName: string;
  products: CatalogProduct[];
  categoryMap: CategoryItem[];
  whatsappBaseUrl?: string | null;
  storeLocationText?: string | null;
  storeMapsUrl?: string | null;
  trackingEnabled?: boolean;
  /** Mevcut çağrı sözleşmesini kırmamak için korunur. Yeni kart ürün görseli yoksa mağaza görselini ürünmüş gibi kullanmaz. */
  fallbackImage?: string | null;
  /** Mevcut çağrı sözleşmesini kırmamak için korunur. */
  storeInitial?: string;
}

interface QuickViewSelection {
  product: CatalogProduct;
  images: string[];
  productUrl: string;
  productSlug: string;
}

const PAGE_SIZE = 24;

function productImageOnly(product: CatalogProduct): string | null {
  const resolved = resolveCatalogImage(product, null);
  return resolved === "/vixrex_v_crystal_mascot.png" ? null : resolved;
}

function productImagesOnly(product: CatalogProduct): string[] {
  const primary = productImageOnly(product);
  if (!primary) return [];

  return Array.from(
    new Set([
      primary,
      ...getProductImages(product).filter((url) => !isLikelyUiScreenshotUrl(url)),
    ]),
  ).slice(0, MAX_PRODUCT_IMAGES);
}

function productLocationMapUrl(location: string): string | null {
  const normalized = location.trim();
  if (!normalized) return null;
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(normalized)}`;
}

function stockTone(stockStatus: string | undefined) {
  const value = String(stockStatus || "").toLocaleLowerCase("tr-TR");
  if (value.includes("tükendi")) {
    return {
      dot: "bg-red-500 shadow-[0_0_0_4px_rgba(239,68,68,0.10)]",
      text: "text-red-300",
    };
  }
  if (value.includes("son") || value.includes("az") || value.includes("sınırl")) {
    return {
      dot: "bg-amber-500 shadow-[0_0_0_4px_rgba(245,158,11,0.10)]",
      text: "text-amber-300",
    };
  }
  return {
    dot: "bg-emerald-500 shadow-[0_0_0_4px_rgba(34,197,94,0.10)]",
    text: "text-emerald-300",
  };
}

function PhotoPlaceholderIcon({ className }: { className?: string }) {
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
      className={className}
    >
      <rect x="3" y="4.5" width="18" height="15" rx="2.5" />
      <circle cx="9" cy="10" r="1.75" />
      <path d="M3 16.5l5.25-5.25a1.5 1.5 0 012.12 0L15 16.5" />
      <path d="M14 15l1.88-1.88a1.5 1.5 0 012.12 0L21 15.5" />
    </svg>
  );
}

function CatalogProductImage({
  src,
  alt,
  emptyLabel = "Ürün görseli yok",
}: {
  src: string | null;
  alt: string;
  emptyLabel?: string;
}) {
  const [prevSrc, setPrevSrc] = useState(src);
  const [imgSrc, setImgSrc] = useState<string | null>(src);
  const [hasError, setHasError] = useState(false);

  if (src !== prevSrc) {
    setPrevSrc(src);
    setImgSrc(src);
    setHasError(false);
  }

  if (!imgSrc || hasError) {
    return (
      <div className="flex h-full flex-col items-center justify-center gap-2 bg-slate-900/60 px-4 text-center">
        <PhotoPlaceholderIcon className="h-7 w-7 text-slate-600" />
        <span className="text-[10px] font-bold text-slate-500">{emptyLabel}</span>
      </div>
    );
  }

  return (
    <Image
      src={imgSrc}
      alt={alt}
      fill
      sizes="(max-width: 768px) 50vw, (max-width: 1200px) 33vw, 25vw"
      onError={() => setHasError(true)}
      className="object-cover object-center transition duration-500 group-hover:scale-[1.035]"
    />
  );
}

/**
 * Public vitrin ürün kataloğu.
 * Kart hızlı tarama için kısa kalır; normal tıklama kategori-duyarlı hızlı
 * incelemeyi açar. Gerçek ürün URL'si href olarak korunur.
 */
export default function ProductCatalog({
  storeSlug,
  storeName,
  products,
  categoryMap,
  whatsappBaseUrl = null,
  storeLocationText = null,
  storeMapsUrl = null,
  trackingEnabled = true,
}: ProductCatalogProps) {
  const searchParams = useSearchParams();
  const [quickView, setQuickView] = useState<QuickViewSelection | null>(null);
  const [locationProductId, setLocationProductId] = useState<string | null>(null);

  const currentPage = Math.max(1, parseInt(searchParams.get("page") || "1", 10) || 1);
  const currentCategory = searchParams.get("category") || "";
  const currentQuery = searchParams.get("q") || "";

  const filteredProducts = useMemo(() => {
    return products.filter((product) => {
      if (!isPublicCatalogProduct(product)) return false;
      if (currentCategory && product.categoryId !== currentCategory) return false;
      if (currentQuery) {
        const q = currentQuery.toLowerCase();
        const matchName = product.name.toLowerCase().includes(q);
        const matchDesc = product.description?.toLowerCase().includes(q) || false;
        const matchCat = product.category?.toLowerCase().includes(q) || false;
        const matchBrand = product.brand?.toLowerCase().includes(q) || false;
        if (!matchName && !matchDesc && !matchCat && !matchBrand) return false;
      }
      return true;
    });
  }, [products, currentCategory, currentQuery]);

  const totalCount = filteredProducts.length;
  const totalPages = Math.ceil(totalCount / PAGE_SIZE);
  const safePage = Math.min(currentPage, Math.max(1, totalPages));
  const from = (safePage - 1) * PAGE_SIZE;
  const paginatedProducts = filteredProducts.slice(from, from + PAGE_SIZE);
  const hasNext = safePage < totalPages;

  const buildPageUrl = useCallback(
    (pageNum: number) => {
      const params = new URLSearchParams();
      if (pageNum > 1) params.set("page", String(pageNum));
      if (currentCategory) params.set("category", currentCategory);
      if (currentQuery) params.set("q", currentQuery);
      const qs = params.toString();
      return `/v/${storeSlug}${qs ? `?${qs}` : ""}`;
    },
    [storeSlug, currentCategory, currentQuery],
  );

  const buildCategoryUrl = useCallback(
    (catId: string) => {
      const params = new URLSearchParams();
      if (catId) params.set("category", catId);
      if (currentQuery) params.set("q", currentQuery);
      const qs = params.toString();
      return `/v/${storeSlug}${qs ? `?${qs}` : ""}`;
    },
    [storeSlug, currentQuery],
  );

  return (
    <section>
      {categoryMap.length > 1 && (
        <div className="mb-8 flex items-center gap-2.5 overflow-x-auto pb-2 pr-6 scrollbar-none">
          <a
            href={buildCategoryUrl("")}
            className={`inline-flex shrink-0 items-center justify-center rounded-xl px-5 py-2.5 text-xs transition duration-200 sm:text-sm ${
              currentCategory === ""
                ? "border border-blue-400/40 bg-gradient-to-r from-blue-600 via-blue-500 to-cyan-500 font-extrabold text-white shadow-lg shadow-blue-500/25"
                : "border border-blue-500/15 bg-slate-900/60 font-semibold text-slate-300 backdrop-blur-xl hover:border-blue-500/30 hover:text-white"
            }`}
          >
            Tümü
          </a>
          {categoryMap.map((cat) => (
            <a
              key={cat.id}
              href={buildCategoryUrl(cat.id)}
              className={`inline-flex shrink-0 items-center justify-center rounded-xl px-5 py-2.5 text-xs transition duration-200 sm:text-sm ${
                currentCategory === cat.id
                  ? "border border-blue-400/40 bg-gradient-to-r from-blue-600 via-blue-500 to-cyan-500 font-extrabold text-white shadow-lg shadow-blue-500/25"
                  : "border border-blue-500/15 bg-slate-900/60 font-semibold text-slate-300 backdrop-blur-xl hover:border-blue-500/30 hover:text-white"
              }`}
            >
              {cat.name}
            </a>
          ))}
        </div>
      )}

      <div
        className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4"
        style={{ gap: "var(--v-card-gap, 0.75rem)" }}
      >
        {paginatedProducts.map((product, index) => {
          const globalIndex = from + index;
          const productSlug = getProductUrlSlug(product, globalIndex);
          const productUrl = `/v/${storeSlug}/urun/${productSlug}`;
          const image = productImageOnly(product);
          const quickImages = productImagesOnly(product);
          const photoCountBadge = productPhotoCountBadge(quickImages.length);
          const category = String(product.category || "").trim();
          const metadata = normalizeProductMetadata(product.metadata);
          const isService = metadata.itemKind === "service";
          const brand = isService ? "" : String(product.brand || "").trim();
          const stockStatus = isService
            ? ""
            : product.stockQuantity === 0
              ? "Tükendi"
              : String(product.stockStatus || "").trim();
          const tone = stockTone(stockStatus);
          const variantLabel = isService
            ? null
            : productVariantLabel(product.variants, metadata.templateKey);
          const kartOzellikleri = buildProductCardFacts({
            brand: product.brand,
            metadata: product.metadata,
            variants: isService ? undefined : product.variants,
          }).ozellikler;
          const ozellikDegerleri = kartOzellikleri.flatMap((ozellik) =>
            ozellik.value
              .split(",")
              .map((parca) => parca.trim())
              .filter(Boolean),
          );
          const ozellikChipLimiti = 4;
          const ozellikChipleri = ozellikDegerleri.slice(0, ozellikChipLimiti);
          const ozellikFazlasi = Math.max(0, ozellikDegerleri.length - ozellikChipLimiti);
          const rozet = kartRozeti({
            badgeTag: product.badgeTag,
            priceAmount: product.priceAmount,
            oldPriceAmount: product.oldPriceAmount,
          });
          const eskiFiyat = eskiFiyatYazisi(product.oldPriceAmount);
          const indirimYuzdesi = indirimOrani({
            priceAmount: product.priceAmount,
            oldPriceAmount: product.oldPriceAmount,
          });
          const fulfillmentRegion = String(product.fulfillmentRegion || "").trim();
          const fulfillmentMapUrl = productLocationMapUrl(fulfillmentRegion);
          const productKey = product.id || productUrl;
          const showLocation = locationProductId === productKey;

          return (
            <article
              key={product.id || `${product.name}-${index}`}
              className="group relative min-w-0 overflow-hidden rounded-[22px] border border-blue-500/15 bg-slate-900/75 shadow-[0_14px_32px_rgba(0,0,0,0.24)] backdrop-blur-xl transition duration-300 hover:-translate-y-1 hover:border-blue-500/35 hover:shadow-[0_18px_44px_rgba(0,0,0,0.34)]"
            >
              <a
                href={productUrl}
                onClick={(event) => {
                  if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
                  event.preventDefault();
                  setLocationProductId(null);
                  setQuickView({ product, images: quickImages, productUrl, productSlug });
                }}
                className="flex h-full min-w-0 flex-col focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
                aria-label={`${product.name} ${isService ? "hizmetini" : "ürününü"} hızlı incele`}
              >
                <div className="relative aspect-[4/5] w-full shrink-0 overflow-hidden bg-slate-950 v-product-media">
                  <CatalogProductImage
                    src={image}
                    alt={product.name}
                    emptyLabel={isService ? "Hizmet görseli yok" : "Ürün görseli yok"}
                  />
                  <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-[#0B1120]/45 via-transparent to-transparent" />
                  <div className="absolute left-2.5 top-2.5 z-10 flex max-w-[70%] flex-col items-start gap-1">
                    {rozet ? (
                      <span className="max-w-full truncate rounded-lg bg-gradient-to-r from-blue-600 to-cyan-600 px-2.5 py-1 text-[10px] font-extrabold text-white shadow-md">
                        {rozet}
                      </span>
                    ) : category && category.toLocaleLowerCase("tr-TR") !== "tümü" ? (
                      <span className="max-w-full truncate rounded-lg border border-blue-500/25 bg-slate-950/80 px-2.5 py-1 text-[9px] font-extrabold uppercase tracking-wider text-blue-300 shadow-sm backdrop-blur-md">
                        {category}
                      </span>
                    ) : null}
                    {photoCountBadge ? (
                      <span className="rounded-full bg-black/60 px-2 py-0.5 text-[10px] font-bold text-white backdrop-blur-sm">
                        {photoCountBadge}
                      </span>
                    ) : null}
                  </div>
                </div>

                <div className="flex flex-1 flex-col px-3.5 py-3.5">
                  {brand ? (
                    <p className="mb-1 truncate text-[9px] font-extrabold uppercase tracking-[0.12em] text-slate-500 sm:text-[10px]">
                      {brand}
                    </p>
                  ) : null}
                  <h3 className="line-clamp-2 min-h-[2.5em] text-[13px] font-extrabold leading-snug text-white sm:text-[15px]">
                    {product.name}
                  </h3>
                  {ozellikChipleri.length > 0 ? (
                    <div className="mt-1.5 flex min-w-0 flex-wrap items-center gap-1">
                      {ozellikChipleri.map((deger, ozellikIndex) => (
                        <span
                          key={`${productKey}-ozellik-${ozellikIndex}`}
                          className="rounded-md border border-white/10 bg-white/[0.04] px-1.5 py-0.5 text-[9px] font-bold text-slate-400 sm:text-[10px]"
                        >
                          {deger}
                        </span>
                      ))}
                      {ozellikFazlasi > 0 ? (
                        <span className="rounded-md border border-blue-500/20 bg-blue-500/10 px-1.5 py-0.5 text-[9px] font-bold text-blue-300 sm:text-[10px]">
                          +{ozellikFazlasi}
                        </span>
                      ) : null}
                    </div>
                  ) : null}
                  <div className="mt-2.5 flex min-w-0 flex-wrap items-baseline gap-x-2 gap-y-1">
                    <p className="truncate text-base font-extrabold text-blue-400 sm:text-lg">
                      {product.price || "Fiyat sorun"}
                    </p>
                    {eskiFiyat ? (
                      <span className="shrink-0 text-[10px] font-medium text-slate-500 line-through sm:text-[11px]">
                        {eskiFiyat}
                      </span>
                    ) : null}
                    {indirimYuzdesi ? (
                      <span className="shrink-0 rounded-md bg-gradient-to-r from-blue-600 to-cyan-600 px-1.5 py-0.5 text-[9px] font-extrabold text-white sm:text-[10px]">
                        %{indirimYuzdesi}
                      </span>
                    ) : null}
                  </div>
                  <div className="mt-auto flex min-w-0 flex-wrap items-center gap-x-2 gap-y-1 pt-2">
                    {stockStatus || fulfillmentRegion ? (
                      <span className="inline-flex min-w-0 max-w-full items-center gap-1.5 text-[10px] font-bold sm:text-[11px]">
                        {stockStatus ? (
                          <>
                            <span className={`h-1.5 w-1.5 shrink-0 rounded-full ${tone.dot}`} />
                            <span className={`truncate ${tone.text}`}>{stockStatus}</span>
                          </>
                        ) : null}
                        {stockStatus && fulfillmentRegion ? (
                          <span className="text-slate-600">·</span>
                        ) : null}
                        {fulfillmentRegion ? (
                          <span className="truncate font-semibold text-slate-500">{fulfillmentRegion}</span>
                        ) : null}
                      </span>
                    ) : null}
                    {!isService && variantLabel ? (
                      <span className="rounded-md border border-white/10 bg-white/[0.04] px-1.5 py-0.5 text-[9px] font-bold text-slate-400 sm:text-[10px]">
                        {variantLabel}
                      </span>
                    ) : null}
                    {isService ? (
                      <span className="rounded-md border border-cyan-500/20 bg-cyan-500/10 px-1.5 py-0.5 text-[9px] font-bold text-cyan-300 sm:text-[10px]">
                        Hizmet
                      </span>
                    ) : null}
                    <span className="ml-auto shrink-0 text-[9px] font-extrabold text-blue-400 sm:text-[10px]">
                      Hızlı incele →
                    </span>
                  </div>
                </div>
              </a>

              <button
                type="button"
                onClick={() => setLocationProductId(showLocation ? null : productKey)}
                className="absolute right-2.5 top-2.5 z-20 flex h-9 w-9 items-center justify-center rounded-full border border-white/15 bg-slate-950/75 text-white shadow-lg backdrop-blur-md transition hover:border-blue-400/40 hover:bg-slate-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
                aria-label={`${product.name} konum bilgilerini göster`}
                aria-expanded={showLocation}
                title="Konum bilgileri"
              >
                <MapPinIcon className="h-4 w-4" aria-hidden="true" />
              </button>

              {showLocation ? (
                <div className="absolute right-2.5 top-[3.25rem] z-30 w-[min(240px,calc(100%_-_20px))] rounded-xl border border-blue-500/20 bg-slate-950/95 p-3 text-left shadow-2xl backdrop-blur-xl">
                  <div className="flex items-start gap-2">
                    <MapPinIcon className="mt-0.5 h-4 w-4 shrink-0 text-blue-400" aria-hidden="true" />
                    <div className="min-w-0 flex-1">
                      {fulfillmentRegion ? (
                        <div>
                          <p className="text-[10px] font-extrabold uppercase tracking-wider text-blue-300">
                            {isService ? "Hizmet bölgesi" : "Ürün konumu / teslim bölgesi"}
                          </p>
                          <p className="mt-1 break-words text-xs font-semibold leading-5 text-slate-200">
                            {fulfillmentRegion}
                          </p>
                          {fulfillmentMapUrl ? (
                            <TrackedDirectionsLink
                              href={fulfillmentMapUrl}
                              target="_blank"
                              rel="noopener noreferrer"
                              storeSlug={storeSlug}
                              clickLocation="product_card"
                              productSlug={productSlug}
                              trackingEnabled={trackingEnabled}
                              onClick={(event) => event.stopPropagation()}
                              className="mt-1.5 inline-flex text-[11px] font-extrabold text-blue-400 hover:text-blue-300"
                            >
                              Haritada ara →
                            </TrackedDirectionsLink>
                          ) : null}
                        </div>
                      ) : null}

                      {storeLocationText ? (
                        <div className={fulfillmentRegion ? "mt-3 border-t border-white/10 pt-3" : ""}>
                          <p className="text-[10px] font-extrabold uppercase tracking-wider text-slate-400">
                            İşletme konumu
                          </p>
                          <p className="mt-1 break-words text-xs font-semibold leading-5 text-slate-200">
                            {storeLocationText}
                          </p>
                          {storeMapsUrl ? (
                            <TrackedDirectionsLink
                              href={storeMapsUrl}
                              target="_blank"
                              rel="noopener noreferrer"
                              storeSlug={storeSlug}
                              clickLocation="product_card"
                              productSlug={productSlug}
                              trackingEnabled={trackingEnabled}
                              onClick={(event) => event.stopPropagation()}
                              className="mt-1.5 inline-flex text-[11px] font-extrabold text-blue-400 hover:text-blue-300"
                            >
                              Yol tarifi →
                            </TrackedDirectionsLink>
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
              ) : null}
            </article>
          );
        })}
      </div>

      {(safePage > 1 || hasNext) && (
        <div className="mt-4 flex items-center justify-between gap-3">
          {safePage > 1 ? (
            <a
              href={buildPageUrl(safePage - 1)}
              className="min-h-11 rounded-full border border-white/10 bg-[#15171c] px-5 text-sm font-black text-white/70"
            >
              Önceki
            </a>
          ) : (
            <div />
          )}
          <span className="text-xs font-bold text-white/40">
            {safePage} / {Math.max(1, totalPages)}
          </span>
          {hasNext ? (
            <a
              href={buildPageUrl(safePage + 1)}
              className="min-h-11 rounded-full border border-[#E8A87C]/40 bg-[#E8A87C]/10 px-5 text-sm font-black text-[#E8A87C]"
            >
              Sonraki
            </a>
          ) : (
            <div />
          )}
        </div>
      )}

      {quickView ? (
        <ProductQuickView
          product={quickView.product}
          images={quickView.images}
          productUrl={quickView.productUrl}
          productSlug={quickView.productSlug}
          storeSlug={storeSlug}
          storeName={storeName}
          whatsappBaseUrl={whatsappBaseUrl}
          storeLocationText={storeLocationText}
          storeMapsUrl={storeMapsUrl}
          trackingEnabled={trackingEnabled}
          onClose={() => setQuickView(null)}
        />
      ) : null}
    </section>
  );
}
