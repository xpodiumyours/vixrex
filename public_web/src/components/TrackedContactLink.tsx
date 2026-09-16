"use client";

import type { AnchorHTMLAttributes, MouseEvent } from "react";
import type { GtagCommand, WhatsAppClickLocation } from "./TrackedWhatsAppLink";
import { supabase } from "@/lib/supabase";
import { ziyaretAnahtariniOkuyaUret } from "@/lib/vitrinZiyaretAnahtari";

export const PHONE_CLICK_EVENT = "phone_click";
export const DIRECTIONS_CLICK_EVENT = "directions_click";

export interface ContactClickContext {
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

function trackContactEvent(
  eventName: string,
  gtag: GtagCommand | undefined,
  context: ContactClickContext,
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
    gtag("event", eventName, parameters);
  }

  supabase
    .rpc("record_vitrin_engagement_v2", {
      p_store_slug: storeSlug,
      p_event_type: eventName,
      p_session_key: ziyaretAnahtariniOkuyaUret(),
      p_product_slug: productSlug || null,
      p_surface: context.clickLocation,
    })
    .then(() => {});
}

export function trackPhoneClick(
  gtag: GtagCommand | undefined,
  context: ContactClickContext,
): void {
  trackContactEvent(PHONE_CLICK_EVENT, gtag, context);
}

export function trackDirectionsClick(
  gtag: GtagCommand | undefined,
  context: ContactClickContext,
): void {
  trackContactEvent(DIRECTIONS_CLICK_EVENT, gtag, context);
}

interface TrackedContactLinkProps
  extends AnchorHTMLAttributes<HTMLAnchorElement>,
    ContactClickContext {
  trackingEnabled?: boolean;
}

export function TrackedPhoneLink({
  storeSlug,
  clickLocation,
  productSlug,
  trackingEnabled = true,
  onClick,
  ...anchorProps
}: TrackedContactLinkProps) {
  function handleClick(event: MouseEvent<HTMLAnchorElement>) {
    onClick?.(event);
    if (event.defaultPrevented || !trackingEnabled) return;

    trackPhoneClick(window.gtag, {
      storeSlug,
      clickLocation,
      productSlug,
    });
  }

  return <a {...anchorProps} onClick={handleClick} />;
}

export function TrackedDirectionsLink({
  storeSlug,
  clickLocation,
  productSlug,
  trackingEnabled = true,
  onClick,
  ...anchorProps
}: TrackedContactLinkProps) {
  function handleClick(event: MouseEvent<HTMLAnchorElement>) {
    onClick?.(event);
    if (event.defaultPrevented || !trackingEnabled) return;

    trackDirectionsClick(window.gtag, {
      storeSlug,
      clickLocation,
      productSlug,
    });
  }

  return <a {...anchorProps} onClick={handleClick} />;
}
