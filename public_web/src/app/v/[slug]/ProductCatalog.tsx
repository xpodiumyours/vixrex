import Link from "next/link";
import {
  getProductImages,
  getProductUrlSlug,
  type ProductItem,
} from "@/lib/products";

interface ProductPagination {
  page: number;
  pageSize: number;
  totalCount: number;
  hasNext: boolean;
  category: string;
  query: string;
}

interface CategoryItem {
  id: string;
  name: string;
}

interface ProductCatalogProps {
  storeSlug: string;
  products: ProductItem[];
  categoryMap: CategoryItem[];
  pagination: ProductPagination;
}

export default function ProductCatalog({
  storeSlug,
  products,
  categoryMap,
  pagination,
}: ProductCatalogProps) {
  const { page, totalCount, hasNext, category, query } = pagination;

  function buildPageUrl(pageNum: number) {
    const params = new URLSearchParams();
    if (pageNum > 1) params.set("page", String(pageNum));
    if (category) params.set("category", category);
    if (query) params.set("q", query);
    const qs = params.toString();
    return `/v/${storeSlug}${qs ? `?${qs}` : ""}`;
  }

  function buildCategoryUrl(catId: string) {
    const params = new URLSearchParams();
    if (catId) params.set("category", catId);
    if (query) params.set("q", query);
    const qs = params.toString();
    return `/v/${storeSlug}${qs ? `?${qs}` : ""}`;
  }

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
          <Link
            href={buildCategoryUrl("")}
            className={`min-h-11 shrink-0 rounded-full border px-4 text-xs font-black ${
              category === ""
                ? "border-[#38A0E4] bg-[#38A0E4] text-[#071322]"
                : "border-[#25415F] bg-[#13243A] text-[#C4D1E3]"
            }`}
          >
            Tümü
          </Link>
          {categoryMap.map((cat) => (
            <Link
              key={cat.id}
              href={buildCategoryUrl(cat.id)}
              className={`min-h-11 shrink-0 rounded-full border px-4 text-xs font-black ${
                category === cat.id
                  ? "border-[#38A0E4] bg-[#38A0E4] text-[#071322]"
                  : "border-[#25415F] bg-[#13243A] text-[#C4D1E3]"
              }`}
            >
              {cat.name}
            </Link>
          ))}
        </div>
      )}

      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-4">
        {products.map((product, index) => {
          const globalIndex = (page - 1) * pagination.pageSize + index;
          const productUrl = `/v/${storeSlug}/urun/${getProductUrlSlug(product, globalIndex)}`;
          const image = getProductImages(product)[0];
          return (
            <Link
              key={product.id || `${product.name}-${index}`}
              href={productUrl}
              className="min-w-0 rounded-2xl border border-[#25415F] bg-[#13243A] p-2 transition hover:border-[#38A0E4]/70 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#38A0E4]"
            >
              <div className="aspect-square overflow-hidden rounded-xl bg-[#162A42]">
                {image ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={image} alt={product.name} className="h-full w-full object-cover" />
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
            </Link>
          );
        })}
      </div>

      {(page > 1 || hasNext) && (
        <div className="mt-4 flex items-center justify-between gap-3">
          {page > 1 ? (
            <Link
              href={buildPageUrl(page - 1)}
              className="min-h-11 rounded-2xl border border-[#25415F] bg-[#13243A] px-5 text-sm font-black text-[#C4D1E3]"
            >
              Önceki sayfa
            </Link>
          ) : (
            <div />
          )}
          <span className="text-xs font-bold text-[#9DB2C8]">
            Sayfa {page} / {Math.ceil(totalCount / pagination.pageSize)}
          </span>
          {hasNext ? (
            <Link
              href={buildPageUrl(page + 1)}
              className="min-h-11 rounded-2xl border border-[#38A0E4]/40 bg-[#38A0E4]/10 px-5 text-sm font-black text-[#B9E1FF]"
            >
              Sonraki sayfa
            </Link>
          ) : (
            <div />
          )}
        </div>
      )}
    </section>
  );
}
