"use client";

import { supabase } from "@/lib/supabase";
import { ziyaretAnahtariniOkuyaUret } from "@/lib/vitrinZiyaretAnahtari";

export type VitrinSiparisKalemi = {
  product_slug: string;
  name: string;
  quantity: number;
  unit_price: number | null;
  variant: string | null;
};

export async function siparisiKaydet(args: {
  storeSlug: string;
  orderKey: string;
  items: VitrinSiparisKalemi[];
  totalQuantity: number;
  totalAmount: number | null;
}) {
  if (typeof window === "undefined") return;
  const storeSlug = args.storeSlug.trim();
  if (!storeSlug || args.items.length === 0) return;

  const { error } = await supabase.rpc("record_vitrin_whatsapp_order", {
    p_store_slug: storeSlug,
    p_session_key: ziyaretAnahtariniOkuyaUret(),
    p_order_key: args.orderKey,
    p_items: args.items,
    p_total_quantity: args.totalQuantity,
    p_total_amount: args.totalAmount,
  });

  if (error && process.env.NODE_ENV !== "production") {
    console.warn("[vitrin-siparis] sipariş kaydedilemedi:", error.message);
  }
}
