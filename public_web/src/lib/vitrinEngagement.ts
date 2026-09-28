"use client";

import { supabase } from "@/lib/supabase";
import { ziyaretAnahtariniOkuyaUret } from "@/lib/vitrinZiyaretAnahtari";

export type VitrinOlcerEvent =
  | "whatsapp_click"
  | "phone_click"
  | "directions_click"
  | "product_view"
  | "product_like"
  | "product_unlike"
  | "comment_create"
  | "cart_add"
  | "cart_remove"
  | "cart_quantity_change"
  | "cart_whatsapp_order";

export async function recordVitrinEngagement(args: {
  storeSlug: string;
  eventType: VitrinOlcerEvent;
  productSlug?: string | null;
  quantity?: number | null;
  metadata?: Record<string, unknown>;
}) {
  if (typeof window === "undefined") return;
  const storeSlug = args.storeSlug.trim();
  if (!storeSlug) return;

  const { error } = await supabase.rpc("record_vitrin_engagement_v2", {
    p_store_slug: storeSlug,
    p_event_type: args.eventType,
    p_session_key: ziyaretAnahtariniOkuyaUret(),
    p_product_slug: args.productSlug?.trim() || null,
    p_quantity:
      typeof args.quantity === "number" && Number.isFinite(args.quantity)
        ? Math.max(1, Math.min(999, Math.round(args.quantity)))
        : null,
    p_metadata: args.metadata ?? {},
  });

  if (error && process.env.NODE_ENV !== "production") {
    console.warn("[vitrin-olcer] olay kaydedilemedi:", error.message);
  }
}
