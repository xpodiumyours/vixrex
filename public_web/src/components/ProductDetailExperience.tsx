"use client";

import { useMemo, type MouseEvent } from "react";
import { useSearchParams } from "next/navigation";
import ProductDetailExperienceBase from "./ProductDetailExperienceBase";
import { trackDirectionsClick } from "./TrackedContactLink";
import type { RichProductItem } from "@/lib/richProductItem";
import type { ProductQuickFact } from "@/lib/productCardPresentation";
import { normalizeProductVariants } from "@/lib/productRichData";

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
}

function isMapsUrl(href: string): boolean {
  try {
    const url = new URL(href, window.location.origin);
    return url.hostname.includes("google.") && url.pathname.includes("/maps");
  } catch {
    return false;
  }
}

export default function ProductDetailExperience(props: ProductDetailExperienceProps) {
  const searchParams = useSearchParams();
  const selectedVariantId = searchParams.get("variant")?.trim() || "";

  const product = useMemo(() => {
    if (!selectedVariantId) return props.product;
    const variants = normalizeProductVariants(props.product.variants);
    const selectedIndex = variants.findIndex((variant) => variant.id === selectedVariantId);
    if (selectedIndex <= 0) return props.product;
    const selected = variants[selectedIndex];
    const reordered = [selected, ...variants.filter((_, index) => index !== selectedIndex)];
    return { ...props.product, variants: reordered };
  }, [props.product, selectedVariantId]);

  function handleClickCapture(event: MouseEvent<HTMLDivElement>) {
    const target = event.target;
    if (!(target instanceof Element)) return;
    const anchor = target.closest("a");
    if (!(anchor instanceof HTMLAnchorElement) || !isMapsUrl(anchor.href)) return;
    trackDirectionsClick(window.gtag, {
      storeSlug: props.storeSlug,
      clickLocation: "product_detail",
      productSlug: props.productSlug,
    });
  }

  return (
    <div onClickCapture={handleClickCapture}>
      <ProductDetailExperienceBase {...props} product={product} />
    </div>
  );
}
