"use client";

import { useSearchParams, useRouter } from "next/navigation";
import Image from "next/image";
import { useCallback, useMemo } from "react";
import {
  getProductImages,
  getProductUrlSlug,
  type ProductItem,
} from "@/lib/products";

interface CatalogProduct extends ProductItem {
  categoryId?: string;
}

interface ProductPagination {
  page: number;
  pageSize: number;
  totalCount: number;
  hasNext: boolean;
}

interface CategoryItem {
  id: string;
  name: string;
}

interface ProductCatalogProps {
  storeSlug: string;
  products: CatalogProduct[];
  categoryMap: CategoryItem[];
}

const PAGE_SIZE = 24;

export default function ProductCatalog({
  storeSlug,
  products,
  categoryMap,
}: ProductCatalogProps) {
  const searchParams = useSearchParams();
  const router = useRouter();

  const currentPage = Math.max(1, parseInt(searchParams.get("page") || "1", 10) || 1);
  const currentCategory = searchParams.get("category") || "";
  const currentQuery = searchParams.get("q") || "";

  const filteredProducts = useMemo(() => {
    return products.filter((product) => {
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

  const pagination: ProductPagination = {
    page: safePage,
    pageSize: PAGE_SIZE,
    totalCount,
    hasNext,
  };

  const buildPageUrl = useCallback(
    (pageNum: number) => {
      const params = new URLSearchParams();
      if (pageNum > 1) params.set("page", String(pageNum));
      if (currentCategory) params.set("category", currentCategory);
      if (currentQuery) params.set("q", currentQuery);
      const qs = params.toString();
      return `/v/${storeSlug}${qs ? `?${qs}` : ""}`;
    },
    [storeSlug, currentCategory, currentQuery]
  );

  const buildCategoryUrl = useCallback(
    (catId: string) => {
      const params = new URLSearchParams();
      if (catId) params.set("category", catId);
      if (currentQuery) params.set("q", currentQuery);
      const qs = params.toString();
      return `/v/${storeSlug}${qs ? `?${qs}` : ""}`;
    },
    [storeSlug, currentQuery]
  );

  const { page } = pagination;

  return (
    <section>
      <div className="mb-3 flex items-center justify-between gap-3">
        <span className="text-xs font-extrabold text-white/45">{totalCount} ürün</span>
      </div>

      {categoryMap.length > 1 && (
        <div className="mb-4 flex gap-2 overflow-x-auto pb-1">
          <a
            href={buildCategoryUrl("")}
            className={`min-h-11 shrink-0 rounded-full border px-4 text-xs font-black ${
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
              className={`min-h-11 shrink-0 rounded-full border px-4 text-xs font-black ${
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
        style={{ gap: "var(--v-card-gap, 0.5rem)" }}
      >
        {paginatedProducts.map((product, index) => {
          const globalIndex = from + index;
          const productUrl = `/v/${storeSlug}/urun/${getProductUrlSlug(product, globalIndex)}`;
          const image = getProductImages(product)[0];
          return (
            <a
              key={product.id || `${product.name}-${index}`}
              href={productUrl}
              className="min-w-0 overflow-hidden border border-white/8 bg-[#15171c] transition hover:-translate-y-0.5 hover:border-white/20 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#E8A87C]"
              style={{ borderRadius: "var(--v-card-radius, 0.875rem)" }}
            >
              <div className="v-product-media overflow-hidden bg-[#1c1f27]">
                {image ? (
                  <Image src={image} alt={product.name} width={320} height={400} className="h-full w-full object-cover" />
                ) : (
                  <div className="flex h-full items-center justify-center px-2 text-center text-[10px] font-bold text-white/40 sm:text-xs">
                    Ürün görseli bekleniyor
                  </div>
                )}
              </div>
              <div style={{ padding: "var(--v-card-pad, 0.625rem)" }}>
                <h3
                  className="truncate font-extrabold text-white"
                  style={{ fontSize: "var(--v-card-name, 0.75rem)" }}
                >
                  {product.name}
                </h3>
                <p
                  className="mt-0.5 truncate font-bold text-[#E8A87C] sm:mt-1"
                  style={{ fontSize: "var(--v-card-price, 0.6875rem)" }}
                >
                  {product.price || "Fiyat sorun"}
                </p>
              </div>
            </a>
          );
        })}
      </div>

      {(page > 1 || hasNext) && (
        <div className="mt-4 flex items-center justify-between gap-3">
          {page > 1 ? (
            <a
              href={buildPageUrl(page - 1)}
              className="min-h-11 rounded-full border border-white/10 bg-[#15171c] px-5 text-sm font-black text-white/70"
            >
              Önceki
            </a>
          ) : (
            <div />
          )}
          <span className="text-xs font-bold text-white/40">
            {page} / {totalPages}
          </span>
          {hasNext ? (
            <a
              href={buildPageUrl(page + 1)}
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
