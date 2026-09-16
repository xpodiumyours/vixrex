"use client";

import { useEffect, useRef } from "react";
import { supabase } from "@/lib/supabase";
import { ziyaretAnahtariniOkuyaUret } from "@/lib/vitrinZiyaretAnahtari";

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

export default function ProductViewTracker({
  storeSlug,
  productSlug,
}: {
  storeSlug: string;
  productSlug: string;
}) {
  const firedRef = useRef(false);

  useEffect(() => {
    if (
      firedRef.current ||
      !storeSlug ||
      !productSlug ||
      ownerPreviewActive()
    ) {
      return;
    }
    firedRef.current = true;

    supabase
      .rpc("record_vitrin_engagement_v2", {
        p_store_slug: storeSlug,
        p_event_type: "product_view",
        p_session_key: ziyaretAnahtariniOkuyaUret(),
        p_product_slug: productSlug,
        p_surface: "product_detail",
      })
      .then(({ error }) => {
        if (error) console.error("record_vitrin_engagement_v2 failed:", error);
      });
  }, [storeSlug, productSlug]);

  return null;
}
