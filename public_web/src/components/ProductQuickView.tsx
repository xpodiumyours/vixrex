"use client";

import { useEffect, useMemo, useRef, useState, type MouseEvent } from "react";
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

const FOCUSABLE_SELECTOR = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(",");

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

export default function ProductQuickView(props: ProductQuickViewProps) {
  const sessionKey = props.product.id || props.productUrl;
  return <ProductQuickViewSession key={sessionKey} {...props} />;
}

function ProductQuickViewSession({
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
  const rootRef = useRef<HTMLDivElement>(null);
  const returnFocusRef = useRef<HTMLElement | null>(null);
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
    returnFocusRef.current = document.activeElement instanceof HTMLElement
      ? document.activeElement
      : null;
    const dialog = rootRef.current?.querySelector<HTMLElement>('[role="dialog"]');
    const title = dialog?.querySelector<HTMLElement>("#product-quick-view-title");
    if (title) {
      title.setAttribute("tabindex", "-1");
      title.focus();
    } else {
      dialog?.focus();
    }

    const trapFocus = (event: KeyboardEvent) => {
      if (event.key !== "Tab" || !dialog) return;
      const focusable = Array.from(dialog.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR))
        .filter((element) => !element.hasAttribute("disabled") && element.getAttribute("aria-hidden") !== "true");
      if (focusable.length === 0) {
        event.preventDefault();
        title?.focus();
        return;
      }
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      const active = document.activeElement;
      if (active === title || !dialog.contains(active)) {
        event.preventDefault();
        (event.shiftKey ? last : first).focus();
      } else if (event.shiftKey && active === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && active === last) {
        event.preventDefault();
        first.focus();
      }
    };

    document.addEventListener("keydown", trapFocus);
    return () => {
      document.removeEventListener("keydown", trapFocus);
      returnFocusRef.current?.focus();
    };
  }, []);

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
    <div ref={rootRef} onClickCapture={handleClickCapture}>
      <ProductQuickViewBase
        product={product}
        images={images}
        productUrl={detailUrl}
        storeName={storeName}
        storeSlug={storeSlug}
        productSlug={productSlug}
        commerceEnabled={trackingEnabled}
        whatsappBaseUrl={whatsappBaseUrl}
        storeLocationText={storeLocationText}
        storeMapsUrl={storeMapsUrl}
        onClose={onClose}
      />
    </div>
  );
}
