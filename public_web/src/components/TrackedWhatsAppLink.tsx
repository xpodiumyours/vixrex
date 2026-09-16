"use client";

import type { AnchorHTMLAttributes, MouseEvent } from "react";
import { supabase } from "@/lib/supabase";
import { ziyaretAnahtariniOkuyaUret } from "@/lib/vitrinZiyaretAnahtari";

export const WHATSAPP_CLICK_EVENT = "whatsapp_click";

export type WhatsAppClickLocation =
  | "storefront_hero"
  | "storefront_contact"
  | "product_card"
  | "product_quick_view"
  | "product_detail"
  | "storefront_floating";

export type GtagCommand = (
  command: "event",
  eventName: string,
  parameters: Record<string, string>,
) => void;

declare global {
  interface Window {
    gtag?: GtagCommand;
  }
}

export interface WhatsAppClickContext {
  storeSlug: string;
  clickLocation: WhatsAppClickLocation;
  productSlug?: string;
}

function ownerPreviewActive(): boolean {
  return (
    typeof document !== "undefined" &&
    Boolean(
      document.querySelector(
        "[data-vixrex-editable], [data-vixrex-owner-preview]",
      ),
    )
  );
}

export function trackWhatsAppClick(
  gtag: GtagCommand | undefined,
  context: WhatsAppClickContext,
): void {
  const storeSlug = context.storeSlug.trim();
  if (!storeSlug || ownerPreviewActive()) return;
  const productSlug = context.productSlug?.trim() || "";

  if (gtag) {
    const parameters: Record<string, string> = {
      store_slug: storeSlug,
      click_location: context.clickLocation,
    };
    if (productSlug) parameters.product_slug = productSlug;
    gtag("event", WHATSAPP_CLICK_EVENT, parameters);
  }

  supabase
    .rpc("record_vitrin_engagement_v2", {
      p_store_slug: storeSlug,
      p_event_type: "whatsapp_click",
      p_session_key: ziyaretAnahtariniOkuyaUret(),
      p_product_slug: productSlug || null,
      p_surface: context.clickLocation,
    })
    .then(() => {});
}

interface TrackedWhatsAppLinkProps
  extends AnchorHTMLAttributes<HTMLAnchorElement>,
    WhatsAppClickContext {
  trackingEnabled?: boolean;
}

export function TrackedWhatsAppLink({
  storeSlug,
  clickLocation,
  productSlug,
  trackingEnabled = true,
  onClick,
  ...anchorProps
}: TrackedWhatsAppLinkProps) {
  function handleClick(event: MouseEvent<HTMLAnchorElement>) {
    onClick?.(event);
    if (event.defaultPrevented || !trackingEnabled) return;

    trackWhatsAppClick(window.gtag, {
      storeSlug,
      clickLocation,
      productSlug,
    });
  }

  return <a {...anchorProps} onClick={handleClick} />;
}
