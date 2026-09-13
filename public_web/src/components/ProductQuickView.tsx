"use client";

import { useEffect, useMemo, useState, type MouseEvent } from "react";
import ProductQuickViewBase from "./ProductQuickViewBase";
import { trackDirectionsClick } from "./TrackedContactLink";
import { trackWhatsAppClick } from "./TrackedWhatsAppLink";
import type { RichProductItem } from "@/lib/richProductItem";
import {
  buildVariantOptionGroups,
  findMatchingVariant,
  productVariantsForTemplate,
} from "@/lib/productCardPresentation";
import { normalizeProductMetadata } from "@/lib/productRichData";

interface ProductQuickViewProps {
  product: RichProductItem;
  images: string[];
  productUrl: string;
  productSlug: string;
  storeSlug: string;
  storeName: string;
  whatsappBaseUrl?: string | null;
  storeLocationText?: string | null;
  storeMapsUrl?: string | null;
  trackingEnabled?: boolean;
  onClose: () => void;
}

function ownerPreviewActive(): boolean {
  return typeof document !== "undefined" && Boolean(document.querySelector("[data-vixrex-editable]"));
}

function isWhatsAppUrl(href: string): boolean {
  try {
    const url = new URL(href, window.location.origin);
    return url.hostname === "wa.me" || url.hostname.endsWith(".whatsapp.com");
  } catch {
    return false;
  }
}

function isMapsUrl(href: string): boolean {
  try {
    const url = new URL(href, window.location.origin);
    return url.hostname.includes("google.") && url.pathname.includes("/maps");
  } catch {
    return false;
  }
}

export default function ProductQuickView({
  product,
  images,
  productUrl,
  productSlug,
  storeSlug,
  storeName,
  whatsappBaseUrl = null,
  storeLocationText = null,
  storeMapsUrl = null,
  trackingEnabled = true,
  onClose,
}: ProductQuickViewProps) {
  const metadata = useMemo(() => normalizeProductMetadata(product.metadata), [product.metadata]);
  const variants = useMemo(
    () => productVariantsForTemplate(product.variants, metadata.templateKey),
    [product.variants, metadata.templateKey],
  );
  const groups = useMemo(
    () => buildVariantOptionGroups(product.variants, metadata.templateKey),
    [product.variants, metadata.templateKey],
  );
  const [selectedOptions, setSelectedOptions] = useState<Record<string, string>>(
    variants[0] ? { ...variants[0].options } : {},
  );

  useEffect(() => {
    setSelectedOptions(variants[0] ? { ...variants[0].options } : {});
  }, [product.id, variants]);

  const selectedVariant = useMemo(
    () => findMatchingVariant(product.variants, selectedOptions, metadata.templateKey),
    [product.variants, selectedOptions, metadata.templateKey],
  );

  const detailUrl = selectedVariant?.id
    ? `${productUrl}?variant=${encodeURIComponent(selectedVariant.id)}`
    : productUrl;

  function mirrorVariantSelection(button: HTMLButtonElement) {
    if (!button.hasAttribute("aria-pressed")) return;
    const value = button.textContent?.trim() || "";
    const label = button.parentElement?.previousElementSibling?.textContent?.trim() || "";
    if (!value || !label) return;
    const group = groups.find((candidate) => candidate.label === label);
    if (!group) return;

    const preferred = variants.find(
      (variant) =>
        variant.options[group.key] === value &&
        Object.entries(selectedOptions).every(([otherKey, otherValue]) =>
          otherKey === group.key ? true : !otherValue || variant.options[otherKey] === otherValue,
        ),
    );
    const fallback = variants.find((variant) => variant.options[group.key] === value);
    const next = preferred || fallback;
    if (next) setSelectedOptions({ ...next.options });
  }

  function handleClickCapture(event: MouseEvent<HTMLDivElement>) {
    const target = event.target;
    if (!(target instanceof Element)) return;

    const button = target.closest("button");
    if (button instanceof HTMLButtonElement) mirrorVariantSelection(button);

    const anchor = target.closest("a");
    if (!(anchor instanceof HTMLAnchorElement)) return;
    if (!trackingEnabled || ownerPreviewActive()) return;

    const href = anchor.href;
    if (isWhatsAppUrl(href)) {
      trackWhatsAppClick(window.gtag, {
        storeSlug,
        clickLocation: "product_quick_view",
        productSlug,
      });
      return;
    }
    if (isMapsUrl(href)) {
      trackDirectionsClick(window.gtag, {
        storeSlug,
        clickLocation: "product_quick_view",
        productSlug,
      });
    }
  }

  return (
    <div onClickCapture={handleClickCapture}>
      <ProductQuickViewBase
        product={product}
        images={images}
        productUrl={detailUrl}
        storeName={storeName}
        whatsappBaseUrl={whatsappBaseUrl}
        storeLocationText={storeLocationText}
        storeMapsUrl={storeMapsUrl}
        onClose={onClose}
      />
    </div>
  );
}
