"use client";

import { useEffect, useRef } from "react";
import { supabase } from "@/lib/supabase";
import {
  resolveVitrinViewSource,
  type VitrinViewSource,
} from "@/lib/vitrinViewSource";

const SESSION_KEY_STORAGE_KEY = "vixrex_visit_session";

function readOrCreateSessionKey(): string {
  try {
    const existing = window.localStorage.getItem(SESSION_KEY_STORAGE_KEY);
    if (existing && existing.length >= 16) return existing;
  } catch {
    // localStorage erişilemezse (gizli sekme, engellenmiş depolama) sorun
    // değil — aşağıda yeni bir anahtar üretilir, bu ziyaret yine sayılır.
  }

  const generated =
    typeof crypto !== "undefined" && "randomUUID" in crypto
      ? crypto.randomUUID()
      : `${Date.now()}-${Math.random().toString(36).slice(2)}`;

  try {
    window.localStorage.setItem(SESSION_KEY_STORAGE_KEY, generated);
  } catch {
    // depolanamazsa sorun değil, bu ziyaret yine de sayılır — yalnız
    // ertesi gün aynı tarayıcıdan gelen ziyaret ayrı sayılabilir.
  }

  return generated;
}

function detectSource(): VitrinViewSource {
  let srcParam: string | null = null;
  try {
    srcParam = new URLSearchParams(window.location.search).get("src");
  } catch {
    // yoksay — parametre okunamazsa referrer mantığına düşer
  }

  let referrer = "";
  try {
    referrer = document.referrer || "";
  } catch {
    // yoksay, direct/unknown ayrımı resolveVitrinViewSource'ta yapılır
  }

  let currentHostname = "";
  try {
    currentHostname = window.location.hostname || "";
  } catch {
    // yoksay — kendi domain kontrolü atlanır
  }

  return resolveVitrinViewSource({ srcParam, referrer, currentHostname });
}

interface VitrinViewTrackerProps {
  storeSlug: string;
}

/**
 * Gerçek vitrin ziyaretini `record_vitrin_view` RPC'siyle `vitrin_views`e
 * kaydeder (#255). Bu bileşen SAHİP/ÖNİZLEME modunda MOUNT EDİLMEMELİDİR —
 * çağıran taraf (`VitrinProfileView`) `!ownerMode && !isPreviewMode` şartını
 * `TrackedWhatsAppLink`ile aynı desende sağlar.
 *
 * Kaynak çözümlemesi `resolveVitrinViewSource` (src/lib/vitrinViewSource.ts)
 * içindedir: ?src=qr|share önceliklidir; referrer Google/Instagram/Facebook/
 * WhatsApp/Twitter/TikTok olarak sınıflanır, kendi domaini "direct"tir,
 * dış siteler "diger_site"tır. Yeni değerler DB'de
 * `20260823120000_vitrin_views_kaynak_genisletme` migration'ı canlıya
 * alınana kadar fonksiyon tarafından 'unknown'a düşürülür.
 *
 * RPC zaten yayınlanmamış vitrinleri ve 16 karakterden kısa session_key'i
 * sessizce reddediyor (SECURITY DEFINER, search_path sabit, anon'a açık) —
 * burada ekstra bir yetki/doğrulama yok, tek iş tetiklemek. Aynı
 * (mağaza, session_key, gün) DB tarafında `on conflict do nothing` ile
 * tekilleşiyor; `firedRef` yalnız React StrictMode'un çift-mount'unda aynı
 * bileşenin iki kez RPC çağırmasını önler.
 */
export default function VitrinViewTracker({ storeSlug }: VitrinViewTrackerProps) {
  const firedRef = useRef(false);

  useEffect(() => {
    if (firedRef.current || !storeSlug) return;
    firedRef.current = true;

    const sessionKey = readOrCreateSessionKey();
    const source = detectSource();

    supabase
      .rpc("record_vitrin_view", {
        p_store_slug: storeSlug,
        p_session_key: sessionKey,
        p_source: source,
      })
      .then(({ error }) => {
        if (error) console.error("record_vitrin_view failed:", error);
      });
  }, [storeSlug]);

  return null;
}
