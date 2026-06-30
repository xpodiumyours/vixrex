"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import {
  getProductImages,
  getProductUrlSlug,
  type ProductItem,
} from "@/lib/products";

interface ProductCatalogProps {
  storeSlug: string;
  products: ProductItem[];
}

export default function ProductCatalog({ storeSlug, products }: ProductCatalogProps) {
  const [selectedCategory, setSelectedCategory] = useState("");
  const [visibleLimit, setVisibleLimit] = useState(12);

  const categories = useMemo(
    () =>
      Array.from(
        new Set(
          products
            .map((product) => String(product.category || "").trim())
            .filter(Boolean)
        )
      ),
    [products]
  );

  const filteredProducts = selectedCategory
    ? products.filter((product) => product.category === selectedCategory)
    : products;
  const visibleProducts = filteredProducts.slice(0, visibleLimit);

  function selectCategory(category: string) {
    setSelectedCategory(category);
    setVisibleLimit(12);
  }

  return (
    <section className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-4 shadow-[0_18px_45px_rgba(0,0,0,0.18)] sm:p-5">
      <div className="mb-4 flex items-center justify-between gap-3">
        <h2 className="text-base font-black text-white">Ürünler</h2>
        <span className="text-xs font-extrabold text-[#9DB2C8]">
          {filteredProducts.length} ürün
        </span>
      </div>

      {categories.length > 1 && (
        <div className="mb-4 flex gap-2 overflow-x-auto pb-1">
          <button
            type="button"
            onClick={() => selectCategory("")}
            className={`min-h-11 shrink-0 rounded-full border px-4 text-xs font-black ${
              selectedCategory === ""
                ? "border-[#38A0E4] bg-[#38A0E4] text-[#071322]"
                : "border-[#25415F] bg-[#13243A] text-[#C4D1E3]"
            }`}
          >
            Tümü
          </button>
          {categories.map((category) => (
            <button
              key={category}
              type="button"
              onClick={() => selectCategory(category)}
              className={`min-h-11 shrink-0 rounded-full border px-4 text-xs font-black ${
                selectedCategory === category
                  ? "border-[#38A0E4] bg-[#38A0E4] text-[#071322]"
                  : "border-[#25415F] bg-[#13243A] text-[#C4D1E3]"
              }`}
            >
              {category}
            </button>
          ))}
        </div>
      )}

      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-4">
        {visibleProducts.map((product, index) => {
          const productIndex = products.indexOf(product);
          const productUrl = `/v/${storeSlug}/urun/${getProductUrlSlug(product, productIndex)}`;
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

      {visibleProducts.length < filteredProducts.length && (
        <button
          type="button"
          onClick={() => setVisibleLimit((current) => current + 12)}
          className="mt-4 min-h-11 w-full rounded-2xl border border-[#38A0E4]/40 bg-[#38A0E4]/10 px-4 text-sm font-black text-[#B9E1FF]"
        >
          Daha fazla göster
        </button>
      )}
    </section>
  );
}
