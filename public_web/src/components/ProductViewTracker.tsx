"use client";

import { useEffect, useRef } from "react";
import { supabase } from "@/lib/supabase";
import { ziyaretAnahtariniOkuyaUret } from "@/lib/vitrinZiyaretAnahtari";

/**
 * Faz F (Tek Asistan planı, 2026-09-02) — ürün detay sayfası görüntülemesini
 * `record_vitrin_engagement`'a yazar. VitrinViewTracker'ın (mağaza sayfası
 * görüntülemesi) ürün karşılığı — aynı ziyaretçi anahtarını kullanır.
 * Bugüne kadar ürün görüntüleme hiçbir yerde (ne GA'da ne Supabase'de)
 * izlenmiyordu.
 */
export default function ProductViewTracker({
  storeSlug,
  productSlug,
}: {
  storeSlug: string;
  productSlug: string;
}) {
  const firedRef = useRef(false);

  useEffect(() => {
    if (firedRef.current || !storeSlug || !productSlug) return;
    firedRef.current = true;

    supabase
      .rpc("record_vitrin_engagement", {
        p_store_slug: storeSlug,
        p_event_type: "product_view",
        p_session_key: ziyaretAnahtariniOkuyaUret(),
        p_product_slug: productSlug,
      })
      .then(({ error }) => {
        if (error) console.error("record_vitrin_engagement failed:", error);
      });
  }, [storeSlug, productSlug]);

  return null;
}
