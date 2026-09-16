"use client";

import { useEffect, useRef } from "react";
import { supabase } from "@/lib/supabase";
import {
  resolveVitrinViewSource,
  type VitrinViewSource,
} from "@/lib/vitrinViewSource";
import { tuketVitrinKaynakHandoff } from "@/lib/vitrinSourceHandoff";
import { ziyaretAnahtariniOkuyaUret } from "@/lib/vitrinZiyaretAnahtari";

export function detectVitrinViewSource(): VitrinViewSource {
  let srcParam: string | null = null;
  try {
    srcParam = new URLSearchParams(window.location.search).get("src");
  } catch {
    srcParam = null;
  }

  if (!srcParam) {
    try {
      srcParam = tuketVitrinKaynakHandoff(window.location.pathname);
    } catch {
      srcParam = null;
    }
  }

  let referrer = "";
  try {
    referrer = document.referrer || "";
  } catch {
    referrer = "";
  }

  let currentHostname = "";
  try {
    currentHostname = window.location.hostname || "";
  } catch {
    currentHostname = "";
  }

  return resolveVitrinViewSource({ srcParam, referrer, currentHostname });
}

interface VitrinViewTrackerProps {
  storeSlug: string;
}

export default function VitrinViewTracker({ storeSlug }: VitrinViewTrackerProps) {
  const firedRef = useRef(false);

  useEffect(() => {
    if (firedRef.current || !storeSlug) return;
    firedRef.current = true;

    supabase
      .rpc("record_vitrin_view", {
        p_store_slug: storeSlug,
        p_session_key: ziyaretAnahtariniOkuyaUret(),
        p_source: detectVitrinViewSource(),
      })
      .then(({ error }) => {
        if (error) console.error("record_vitrin_view failed:", error);
      });
  }, [storeSlug]);

  return null;
}
