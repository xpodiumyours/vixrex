"use client";

import { useEffect, useRef } from "react";
import {
  resolveVitrinViewSource,
  type VitrinViewSource,
} from "@/lib/vitrinViewSource";
import { ziyaretAnahtariniOkuyaUret } from "@/lib/vitrinZiyaretAnahtari";

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
 * Gerçek web vitrin ziyaretini sunucu tarafındaki /api/vitrin-view kapısından
 * geçirip `vitrin_views`e kaydeder. Bilinen bot/crawler User-Agent'ları sunucu
 * tarafında elenir; ham IP veritabanına yazılmaz. Bu bileşen SAHİP/ÖNİZLEME modunda MOUNT EDİLMEMELİDİR —
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

    const sessionKey = ziyaretAnahtariniOkuyaUret();
    const source = detectSource();

    void fetch("/api/vitrin-view", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        storeSlug,
        sessionKey,
        source,
      }),
      keepalive: true,
    }).catch(() => {
      // Ölçüm hatası vitrini etkilemez.
    });
  }, [storeSlug]);

  return null;
}
