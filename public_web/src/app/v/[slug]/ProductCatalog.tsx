"use client";

import Image from "next/image";
import { useSearchParams } from "next/navigation";
import { useCallback, useEffect, useMemo, useState } from "react";
import { MapPinIcon } from "@/lib/vitrinBrandIcons";
import {
  getProductUrlSlug,
  isPublicCatalogProduct,
  resolveCatalogImage,
  type ProductItem,
} from "@/lib/products";

interface CatalogProduct extends ProductItem {
  categoryId?: string;
}

interface CategoryItem {
  id: string;
  name: string;
}

interface ProductCatalogProps {
  storeSlug: string;
  products: CatalogProduct[];
  categoryMap: CategoryItem[];
  /** Mevcut çağrı sözleşmesini kırmamak için korunur. Yeni kart ürün görseli yoksa mağaza görselini ürünmüş gibi kullanmaz. */
  fallbackImage?: string | null;
  /** Mevcut çağrı sözleşmesini kırmamak için korunur. */
  storeInitial?: string;
}

interface QuickViewSelection {
  product: CatalogProduct;
  image: string | null;
  productUrl: string;
}

const PAGE_SIZE = 24;

function productImageOnly(product: CatalogProduct): string | null {
  const resolved = resolveCatalogImage(product, null);
  // resolveCatalogImage görselsiz/OCR ürünlerde eski davranış olarak maskot döndürüyor.
  // Yeni ürün kartında logo/maskot ürün fotoğrafı gibi gösterilmez.
  return resolved === "/vixrex_v_crystal_mascot.png" ? null : resolved;
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

function CatalogProductImage({ src, alt }: { src: string | null; alt: string }) {
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
      <div className="flex h-full flex-col items-center justify-center bg-gradient-to-br from-slate-900 via-slate-950 to-slate-900 px-4 text-center">
        <span className="text-xs font-extrabold text-slate-400">Ürün görseli yok</span>
        <span className="mt-1 text-[10px] font-medium text-slate-600">
          Fotoğraf eklendiğinde burada gösterilir
        </span>
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
 * Vitrin ürün kataloğu.
 * Kart normal tıklamada vitrinden çıkmadan hızlı inceleme açar.
 * Gerçek ürün URL'si href olarak korunur: yeni sekme/ctrl-cmd tıklama ve SEO akışı bozulmaz.
 */
export default function ProductCatalog({
  storeSlug,
  products,
  categoryMap,
}: ProductCatalogProps) {
  const searchParams = useSearchParams();
  const [quickView, setQuickView] = useState<QuickViewSelection | null>(null);
  const [locationProductId, setLocationProductId] = useState<string | null>(null);

  const currentPage = Math.max(1, parseInt(searchParams.get("page") || "1", 10) || 1);
  const currentCategory = searchParams.get("category") || "";
  const currentQuery = searchParams.get("q") || "";

  useEffect(() => {
    if (!quickView) return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setQuickView(null);
    };
    window.addEventListener("keydown", onKeyDown);
    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [quickView]);

  const filteredProducts = useMemo(() => {
    return products.filter((product) => {
      if (!isPublicCatalogProduct(product)) return false;
      if (currentCategory && product.categoryId !== currentCategory) return false;
      if (currentQuery) {
        const q = currentQuery.toLowerCase();
        const matchName = product.name.toLowerCase().includes(q);
        const matchDesc = product.description?.toLowerCase().includes(q) || false;
        const matchCat = product.category?.toLowerCase().includes(q) || false;
        if (!matchName && !matchDesc && !matchCat) return false;
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
          const productUrl = `/v/${storeSlug}/urun/${getProductUrlSlug(product, globalIndex)}`;
          const image = productImageOnly(product);
          const category = String(product.category || "").trim();
          const stockStatus = String(product.stockStatus || "").trim();
          const tone = stockTone(stockStatus);
          const location = String(product.fulfillmentRegion || "").trim();
          const locationMapUrl = productLocationMapUrl(location);
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
                  setQuickView({ product, image, productUrl });
                }}
                className="block min-w-0 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
                aria-label={`${product.name} ürününü hızlı incele`}
              >
                <div className="relative aspect-[4/5] w-full overflow-hidden bg-slate-950 v-product-media">
                  <CatalogProductImage src={image} alt={product.name} />
                  <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-[#0B1120]/45 via-transparent to-transparent" />
                  {product.badgeTag ? (
                    <span className="absolute left-2.5 top-2.5 z-10 max-w-[70%] truncate rounded-lg bg-gradient-to-r from-blue-600 to-cyan-600 px-2.5 py-1 text-[10px] font-extrabold text-white shadow-md">
                      {product.badgeTag}
                    </span>
                  ) : category && category.toLocaleLowerCase("tr-TR") !== "tümü" ? (
                    <span className="absolute left-2.5 top-2.5 z-10 max-w-[70%] truncate rounded-lg border border-blue-500/25 bg-slate-950/80 px-2.5 py-1 text-[9px] font-extrabold uppercase tracking-wider text-blue-300 shadow-sm backdrop-blur-md">
                      {category}
                    </span>
                  ) : null}
                </div>

                <div className="px-3.5 py-3.5">
                  <h3 className="line-clamp-2 min-h-[2.5em] text-xs font-extrabold leading-snug text-white sm:text-sm">
                    {product.name}
                  </h3>
                  <div className="mt-2.5 flex min-w-0 items-baseline gap-2">
                    <p className="truncate text-xs font-extrabold text-blue-400 sm:text-sm">
                      {product.price || "Fiyat sorun"}
                    </p>
                    {product.oldPriceAmount ? (
                      <span className="shrink-0 text-[10px] font-medium text-slate-500 line-through sm:text-[11px]">
                        {product.oldPriceAmount} TL
                      </span>
                    ) : null}
                  </div>
                  {stockStatus ? (
                    <div className={`mt-2 flex items-center gap-2 text-[10px] font-bold sm:text-[11px] ${tone.text}`}>
                      <span className={`h-1.5 w-1.5 shrink-0 rounded-full ${tone.dot}`} />
                      <span className="truncate">{stockStatus}</span>
                    </div>
                  ) : null}
                </div>
              </a>

              <button
                type="button"
                onClick={() => setLocationProductId(showLocation ? null : productKey)}
                className="absolute right-2.5 top-2.5 z-20 flex h-9 w-9 items-center justify-center rounded-full border border-white/15 bg-slate-950/75 text-white shadow-lg backdrop-blur-md transition hover:border-blue-400/40 hover:bg-slate-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
                aria-label={`${product.name} ürün konumu veya hizmet bölgesini göster`}
                aria-expanded={showLocation}
                title="Ürün konumu / hizmet bölgesi"
              >
                <MapPinIcon className="h-4 w-4" aria-hidden="true" />
              </button>

              {showLocation ? (
                <div className="absolute right-2.5 top-13 z-30 w-[min(220px,calc(100%-20px))] rounded-xl border border-blue-500/20 bg-slate-950/95 p-3 text-left shadow-2xl backdrop-blur-xl">
                  <div className="flex items-start gap-2">
                    <MapPinIcon className="mt-0.5 h-4 w-4 shrink-0 text-blue-400" aria-hidden="true" />
                    <div className="min-w-0">
                      <p className="text-[10px] font-extrabold uppercase tracking-wider text-blue-300">
                        Ürün konumu / hizmet bölgesi
                      </p>
                      <p className="mt-1 break-words text-xs font-semibold leading-5 text-slate-200">
                        {location || "Bu ürün için konum veya hizmet bölgesi eklenmemiş."}
                      </p>
                      {locationMapUrl ? (
                        <a
                          href={locationMapUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          onClick={(event) => event.stopPropagation()}
                          className="mt-2 inline-flex text-[11px] font-extrabold text-blue-400 hover:text-blue-300"
                        >
                          Haritada ara →
                        </a>
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
        <div
          className="fixed inset-0 z-[90] flex items-end justify-center bg-slate-950/75 p-0 backdrop-blur-md sm:items-center sm:p-5"
          role="presentation"
          onMouseDown={(event) => {
            if (event.currentTarget === event.target) setQuickView(null);
          }}
        >
          <div
            className="grid max-h-[94vh] w-full max-w-4xl overflow-y-auto rounded-t-[26px] border border-white/10 bg-[#0B1120] shadow-[0_30px_90px_rgba(0,0,0,0.55)] sm:max-h-[90vh] sm:grid-cols-[0.95fr_1.05fr] sm:overflow-hidden sm:rounded-[26px]"
            role="dialog"
            aria-modal="true"
            aria-labelledby="product-quick-view-title"
          >
            <div className="relative aspect-[4/3] bg-slate-950 sm:aspect-auto sm:min-h-[520px]">
              <CatalogProductImage src={quickView.image} alt={quickView.product.name} />
              <button
                type="button"
                onClick={() => setQuickView(null)}
                className="absolute right-4 top-4 z-20 flex h-10 w-10 items-center justify-center rounded-full border border-white/15 bg-slate-950/75 text-xl font-medium text-white backdrop-blur-md hover:bg-slate-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
                aria-label="Hızlı ürün görünümünü kapat"
              >
                ×
              </button>
            </div>

            <div className="flex min-h-0 flex-col p-5 sm:p-8">
              {quickView.product.category ? (
                <p className="text-[10px] font-extrabold uppercase tracking-[0.14em] text-blue-300">
                  {quickView.product.category}
                </p>
              ) : null}
              <h2
                id="product-quick-view-title"
                className="mt-2 text-2xl font-black leading-tight tracking-tight text-white sm:text-3xl"
              >
                {quickView.product.name}
              </h2>

              <div className="mt-3 flex items-baseline gap-3">
                <p className="text-xl font-black text-blue-400 sm:text-2xl">
                  {quickView.product.price || "Fiyat sorun"}
                </p>
                {quickView.product.oldPriceAmount ? (
                  <span className="text-sm font-medium text-slate-500 line-through">
                    {quickView.product.oldPriceAmount} TL
                  </span>
                ) : null}
              </div>

              {quickView.product.stockStatus ? (() => {
                const quickTone = stockTone(quickView.product.stockStatus);
                return (
                  <div className={`mt-3 flex items-center gap-2 text-xs font-bold ${quickTone.text}`}>
                    <span className={`h-1.5 w-1.5 rounded-full ${quickTone.dot}`} />
                    {quickView.product.stockStatus}
                  </div>
                );
              })() : null}

              {quickView.product.fulfillmentRegion ? (
                <div className="mt-5 flex items-start gap-2 rounded-xl border border-blue-500/15 bg-blue-500/5 p-3">
                  <MapPinIcon className="mt-0.5 h-4 w-4 shrink-0 text-blue-400" aria-hidden="true" />
                  <div>
                    <p className="text-[10px] font-extrabold uppercase tracking-wider text-blue-300">
                      Ürün konumu / hizmet bölgesi
                    </p>
                    <p className="mt-1 text-xs font-semibold leading-5 text-slate-200">
                      {quickView.product.fulfillmentRegion}
                    </p>
                    {productLocationMapUrl(quickView.product.fulfillmentRegion) ? (
                      <a
                        href={productLocationMapUrl(quickView.product.fulfillmentRegion) || undefined}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="mt-2 inline-flex text-xs font-extrabold text-blue-400 hover:text-blue-300"
                      >
                        Haritada ara →
                      </a>
                    ) : null}
                  </div>
                </div>
              ) : null}

              {quickView.product.description ? (
                <p className="mt-5 text-sm leading-6 text-slate-300">
                  {quickView.product.description}
                </p>
              ) : null}

              <div className="mt-7 sm:mt-auto sm:pt-7">
                <a
                  href={quickView.productUrl}
                  className="flex min-h-12 items-center justify-center rounded-xl bg-gradient-to-r from-blue-600 to-cyan-500 px-5 text-sm font-extrabold text-white shadow-lg shadow-blue-500/20 transition hover:brightness-110 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
                >
                  Tüm detayları görüntüle
                </a>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </section>
  );
}
