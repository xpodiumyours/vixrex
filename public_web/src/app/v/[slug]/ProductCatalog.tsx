"use client";

import { useSearchParams } from "next/navigation";
import Image from "next/image";
import { useCallback, useMemo } from "react";
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
      <div className="mb-3 flex items-center justify-between gap-3">
        <span className="text-xs font-extrabold uppercase tracking-[0.08em] text-white/45">
          {totalCount} ürün
        </span>
      </div>

      {categoryMap.length > 1 && (
        <div className="mb-4 flex gap-2 overflow-x-auto pb-1">
          <a
            href={buildCategoryUrl("")}
            className={`min-h-10 shrink-0 rounded-full border px-3.5 text-xs font-black sm:min-h-11 sm:px-4 ${
              currentCategory === ""
                ? "border-transparent bg-[#f4f1ea] text-[#0c0d10]"
                : "border-white/10 bg-[#15171c] text-white/60"
            }`}
          >
            Tümü
          </a>
          {categoryMap.map((cat) => (
            <a
              key={cat.id}
              href={buildCategoryUrl(cat.id)}
              className={`min-h-10 shrink-0 rounded-full border px-3.5 text-xs font-black sm:min-h-11 sm:px-4 ${
                currentCategory === cat.id
                  ? "border-transparent bg-[#f4f1ea] text-[#0c0d10]"
                  : "border-white/10 bg-[#15171c] text-white/60"
              }`}
            >
              {cat.name}
            </a>
          ))}
        </div>
      )}

      <div
        className="grid grid-cols-2 md:grid-cols-3"
        style={{ gap: "var(--v-card-gap, 0.625rem)" }}
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
              className="group min-w-0 overflow-hidden rounded-[18px] border border-white/10 bg-[#0E1B2E] shadow-[0_8px_16px_rgba(0,0,0,0.28)] transition hover:-translate-y-0.5 hover:border-white/25 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#E8A87C]"
            >
              <div className="relative v-product-media overflow-hidden bg-[#162A42]">
                {image ? (
                  <Image
                    src={image}
                    alt={product.name}
                    width={320}
                    height={400}
                    className="h-full w-full object-cover transition duration-300 group-hover:scale-[1.03]"
                  />
                ) : (
                  <div className="flex h-full flex-col items-center justify-center gap-1 bg-[linear-gradient(160deg,#25415F,#0E1B2E)] px-2 text-center">
                    <span className="text-2xl font-black text-[#38A0E4]/90">{storeInitial}</span>
                    <span className="text-[10px] font-bold uppercase tracking-wide text-white/35">
                      Görsel yok
                    </span>
                  </div>
                )}
                <div className="pointer-events-none absolute inset-0 bg-[linear-gradient(180deg,transparent_45%,rgba(7,19,34,0.75)_100%)]" />
                {category && category.toLowerCase() !== "tümü" && (
                  <span className="absolute left-2 top-2 rounded-full border border-white/15 bg-black/45 px-2 py-0.5 text-[9px] font-extrabold uppercase tracking-[0.08em] text-[#7eb8ff] backdrop-blur-sm">
                    {category}
                  </span>
                )}
              </div>
              <div className="space-y-1 px-3 py-2.5">
                <h3 className="truncate text-[13px] font-extrabold leading-snug text-white">
                  {product.name}
                </h3>
                <p className="truncate text-xs font-bold text-[#E8A87C]">
                  {product.price || "Fiyat sorun"}
                </p>
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
