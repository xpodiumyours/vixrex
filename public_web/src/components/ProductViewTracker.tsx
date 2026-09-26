"use client";

import { useEffect, useRef } from "react";
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

/** Ürün detay görüntülemesini aynı Vixrex engagement hattına yazar. */
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

    void fetch("/api/vitrin-engagement", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        storeSlug,
        productSlug,
        sessionKey: ziyaretAnahtariniOkuyaUret(),
        eventType: "product_view",
      }),
      keepalive: true,
    }).catch(() => {
      // Pasif ölçüm hatası ürün sayfasını etkilemez.
    });
  }, [storeSlug, productSlug]);

  return null;
}
