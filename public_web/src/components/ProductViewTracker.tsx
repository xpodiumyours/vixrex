"use client";

import { useEffect, useRef } from "react";
import { supabase } from "@/lib/supabase";
import { detectVitrinViewSource } from "@/components/VitrinViewTracker";
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

    const sessionKey = ziyaretAnahtariniOkuyaUret();

    void Promise.all([
      supabase.rpc("record_vitrin_view", {
        p_store_slug: storeSlug,
        p_session_key: sessionKey,
        p_source: detectVitrinViewSource(),
      }),
      supabase.rpc("record_vitrin_engagement_v2", {
        p_store_slug: storeSlug,
        p_event_type: "product_view",
        p_session_key: sessionKey,
        p_product_slug: productSlug,
        p_surface: "product_detail",
      }),
    ]).then(([viewResult, engagementResult]) => {
      if (viewResult.error) {
        console.error("record_vitrin_view failed:", viewResult.error);
      }
      if (engagementResult.error) {
        console.error(
          "record_vitrin_engagement_v2 failed:",
          engagementResult.error,
        );
      }
    });
  }, [storeSlug, productSlug]);

  return null;
}
