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
}

function trackContactEvent(
  eventName: string,
  gtag: GtagCommand | undefined,
  context: ContactClickContext,
): void {
  const storeSlug = context.storeSlug.trim();
  if (!storeSlug) return;

  if (gtag) {
    gtag("event", eventName, {
      store_slug: storeSlug,
      click_location: context.clickLocation,
    });
  }

  // Faz F (Tek Asistan planı, 2026-09-02): GA'nın yanına çift yazım —
  // eventName zaten record_vitrin_engagement'ın event_type'ıyla eşleşiyor
  // (phone_click / directions_click).
  supabase
    .rpc("record_vitrin_engagement", {
      p_store_slug: storeSlug,
      p_event_type: eventName,
      p_session_key: ziyaretAnahtariniOkuyaUret(),
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
    });
  }

  return <a {...anchorProps} onClick={handleClick} />;
}

export function TrackedDirectionsLink({
  storeSlug,
  clickLocation,
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
    });
  }

  return <a {...anchorProps} onClick={handleClick} />;
}
