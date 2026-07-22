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
    <section className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-4 shadow-[0_18px_45px_rgba(0,0,0,0.18)] sm:p-5">
      <div className="mb-4 flex items-center justify-between gap-3">
        <h2 className="text-base font-black text-white">Ürünler</h2>
        <span className="text-xs font-extrabold text-[#9DB2C8]">
          {totalCount} ürün
        </span>
      </div>

      {categoryMap.length > 1 && (
        <div className="mb-4 flex gap-2 overflow-x-auto pb-1">
          <a
            href={buildCategoryUrl("")}
            className={`min-h-11 shrink-0 rounded-full border px-4 text-xs font-black ${
              currentCategory === ""
                ? "border-[#38A0E4] bg-[#38A0E4] text-[#071322]"
                : "border-[#25415F] bg-[#13243A] text-[#C4D1E3]"
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
                  ? "border-[#38A0E4] bg-[#38A0E4] text-[#071322]"
                  : "border-[#25415F] bg-[#13243A] text-[#C4D1E3]"
              }`}
            >
              {cat.name}
            </a>
          ))}
        </div>
      )}

      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-4">
        {paginatedProducts.map((product, index) => {
          const globalIndex = from + index;
          const productUrl = `/v/${storeSlug}/urun/${getProductUrlSlug(product, globalIndex)}`;
          const image = getProductImages(product)[0];
          return (
            <a
              key={product.id || `${product.name}-${index}`}
              href={productUrl}
              className="min-w-0 rounded-2xl border border-[#25415F] bg-[#13243A] p-2 transition hover:border-[#38A0E4]/70 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#38A0E4]"
            >
              <div className="aspect-square overflow-hidden rounded-xl bg-[#162A42]">
                {image ? (
                  <Image src={image} alt={product.name} width={200} height={200} className="h-full w-full object-cover" />
                ) : (
                  <div className="flex h-full items-center justify-center text-xs font-black text-[#9DB2C8]">
                    Ürün görseli bekleniyor
                  </div>
                )}
              </div>
              <div className="mt-3 min-w-0">
                <h3 className="truncate text-sm font-black text-white">{product.name}</h3>
                <p className="mt-1 truncate text-[11px] font-semibold text-[#9DB2C8]">
                  {product.category || "Genel"}
                </p>
                <div className="mt-2 flex items-center justify-between gap-2">
                  <span className="truncate text-xs font-black text-[#7BC7FF]">
                    {product.price || "Fiyat sorun"}
                  </span>
                  <span className="truncate rounded-full bg-emerald-400/12 px-2 py-0.5 text-[10px] font-extrabold text-emerald-200">
                    {product.stockStatus || "Bilgi alın"}
                  </span>
                </div>
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
              className="min-h-11 rounded-2xl border border-[#25415F] bg-[#13243A] px-5 text-sm font-black text-[#C4D1E3]"
            >
              Önceki sayfa
            </a>
          ) : (
            <div />
          )}
          <span className="text-xs font-bold text-[#9DB2C8]">
            Sayfa {page} / {totalPages}
          </span>
          {hasNext ? (
            <a
              href={buildPageUrl(page + 1)}
              className="min-h-11 rounded-2xl border border-[#38A0E4]/40 bg-[#38A0E4]/10 px-5 text-sm font-black text-[#B9E1FF]"
            >
              Sonraki sayfa
            </a>
          ) : (
            <div />
          )}
        </div>
      )}
    </section>
  );
}
