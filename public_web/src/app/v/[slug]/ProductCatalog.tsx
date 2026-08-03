"use client";

import { useSearchParams } from "next/navigation";
import Image from "next/image";
import { useCallback, useMemo, useState } from "react";
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
  fallbackImage?: string | null;
  storeInitial?: string;
}

const PAGE_SIZE = 24;

function CatalogProductImage({
  src,
  alt,
  fallbackImage,
  storeInitial,
}: {
  src: string | null;
  alt: string;
  fallbackImage?: string | null;
  storeInitial: string;
}) {
  const [prevSrc, setPrevSrc] = useState(src);
  const [imgSrc, setImgSrc] = useState<string | null>(src);
  const [hasError, setHasError] = useState(false);

  // "src" değişince yerel durumu render sırasında sıfırlar (React'ın
  // önerdiği desen) — effect içinde setState çağırıp basamaklı render'a
  // yol açmaz.
  if (src !== prevSrc) {
    setPrevSrc(src);
    setImgSrc(src);
    setHasError(false);
  }

  if (!imgSrc || hasError) {
    return (
      <div className="flex h-full flex-col items-center justify-center gap-1.5 bg-gradient-to-br from-slate-900 via-slate-950 to-slate-900 px-2 text-center">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-blue-500/20 bg-blue-500/10 text-blue-400 font-extrabold text-lg">
          {storeInitial}
        </div>
        <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
          Görsel Hazırlanıyor
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
      className="object-cover object-center transition duration-500 group-hover:scale-[1.04]"
    />
  );
}

/** Keşfet VitrinStoreCard diline yakın ürün kartı */
export default function ProductCatalog({
  storeSlug,
  products,
  categoryMap,
  fallbackImage = null,
  storeInitial = "V",
}: ProductCatalogProps) {
  const searchParams = useSearchParams();

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
        <div className="mb-8 flex items-center gap-2.5 overflow-x-auto pb-2 scrollbar-none">
          <a
            href={buildCategoryUrl("")}
            className={`inline-flex items-center justify-center shrink-0 px-5 py-2.5 rounded-xl text-xs sm:text-sm transition duration-200 ${
              currentCategory === ""
                ? "bg-gradient-to-r from-blue-600 via-blue-500 to-cyan-500 text-white font-extrabold shadow-lg shadow-blue-500/25 border border-blue-400/40"
                : "bg-slate-900/60 border border-blue-500/15 backdrop-blur-xl text-slate-300 font-semibold hover:text-white hover:border-blue-500/30"
            }`}
          >
            Tümü
          </a>
          {categoryMap.map((cat) => (
            <a
              key={cat.id}
              href={buildCategoryUrl(cat.id)}
              className={`inline-flex items-center justify-center shrink-0 px-5 py-2.5 rounded-xl text-xs sm:text-sm transition duration-200 ${
                currentCategory === cat.id
                  ? "bg-gradient-to-r from-blue-600 via-blue-500 to-cyan-500 text-white font-extrabold shadow-lg shadow-blue-500/25 border border-blue-400/40"
                  : "bg-slate-900/60 border border-blue-500/15 backdrop-blur-xl text-slate-300 font-semibold hover:text-white hover:border-blue-500/30"
              }`}
            >
              {cat.name}
            </a>
          ))}
        </div>
      )}

      <div
        className="grid grid-cols-2 md:grid-cols-3"
        style={{ gap: "var(--v-card-gap, 0.75rem)" }}
      >
        {paginatedProducts.map((product, index) => {
          const globalIndex = from + index;
          const productUrl = `/v/${storeSlug}/urun/${getProductUrlSlug(product, globalIndex)}`;
          const image = resolveCatalogImage(product, fallbackImage);
          const category = String(product.category || "").trim();

          return (
            <a
              key={product.id || `${product.name}-${index}`}
              href={productUrl}
              className="group min-w-0 overflow-hidden rounded-2xl border border-blue-500/15 bg-slate-900/70 shadow-lg shadow-black/40 backdrop-blur-xl transition duration-300 hover:-translate-y-1 hover:border-blue-500/35 hover:shadow-blue-500/10 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
            >
              <div className="relative w-full aspect-[4/5] v-product-media overflow-hidden bg-slate-950">
                <CatalogProductImage
                  src={image}
                  alt={product.name}
                  fallbackImage={fallbackImage}
                  storeInitial={storeInitial}
                />
                <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-[#0B1120]/80 via-transparent to-transparent" />
                {product.badgeTag ? (
                  <span className="absolute left-2.5 top-2.5 z-10 rounded-lg bg-gradient-to-r from-blue-600 to-cyan-600 px-2.5 py-1 text-[10px] font-extrabold text-white shadow-md">
                    {product.badgeTag}
                  </span>
                ) : category && category.toLowerCase() !== "tümü" ? (
                  <span className="absolute left-2.5 top-2.5 z-10 rounded-lg border border-blue-500/25 bg-slate-950/80 px-2.5 py-1 text-[9px] font-extrabold uppercase tracking-wider text-blue-300 backdrop-blur-md shadow-sm">
                    {category}
                  </span>
                ) : null}
              </div>
              <div className="space-y-1.5 px-3.5 py-3">
                <h3 className="truncate text-xs sm:text-sm font-extrabold leading-snug text-white">
                  {product.name}
                </h3>
                <div className="flex items-baseline gap-2">
                  <p className="truncate text-xs sm:text-sm font-extrabold text-blue-400">
                    {product.price || "Fiyat sorun"}
                  </p>
                  {product.oldPriceAmount ? (
                    <span className="text-[11px] font-medium text-slate-500 line-through">
                      {product.oldPriceAmount} TL
                    </span>
                  ) : null}
                </div>
                {product.fulfillmentRegion ? (
                  <p className="truncate text-[11px] text-slate-500">
                    {product.fulfillmentRegion}
                  </p>
                ) : null}
              </div>
            </a>
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
    </section>
  );
}
