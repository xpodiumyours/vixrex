import { createHash } from "node:crypto";
import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { isLikelyBotUserAgent } from "@/lib/vitrinBotFilter";

const SOURCES = new Set([
  "direct", "qr", "share", "unknown",
  "google", "instagram", "facebook", "whatsapp", "twitter", "tiktok",
  "diger_site",
]);

function clean(value: unknown, max: number) {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

export async function POST(request: NextRequest) {
  try {
    const userAgent = clean(request.headers.get("user-agent"), 300);
    if (isLikelyBotUserAgent(userAgent)) {
      return new NextResponse(null, { status: 204 });
    }

    const body = await request.json().catch(() => null) as Record<string, unknown> | null;
    const storeSlug = clean(body?.storeSlug, 120);
    const sessionKey = clean(body?.sessionKey, 160);
    const rawSource = clean(body?.source, 40).toLowerCase();
    const source = SOURCES.has(rawSource) ? rawSource : "unknown";

    if (!storeSlug || sessionKey.length < 16) {
      return new NextResponse(null, { status: 204 });
    }

    const forwardedFor = clean(request.headers.get("x-forwarded-for"), 500);
    const ip = forwardedFor.split(",")[0]?.trim() || clean(request.headers.get("x-real-ip"), 120);
    const fingerprintBase = ip
      ? `${ip}|${userAgent}`
      : `session:${sessionKey}|${userAgent}`;
    const requestFingerprint = createHash("sha256")
      .update(fingerprintBase)
      .digest("hex");

    const { error } = await getSupabaseAdmin().rpc("record_vitrin_view_web", {
      p_store_slug: storeSlug,
      p_session_key: sessionKey,
      p_source: source,
      p_request_fingerprint: requestFingerprint,
      p_user_agent: userAgent,
    });

    if (error && process.env.NODE_ENV !== "production") {
      console.warn("[vitrin-view] kayıt başarısız:", error.message);
    }
  } catch (error) {
    if (process.env.NODE_ENV !== "production") {
      console.warn("[vitrin-view] istek işlenemedi:", error);
    }
  }

  // Ölçüm hiçbir zaman public vitrinin kullanıcı deneyimini bozmamalı.
  return new NextResponse(null, { status: 204 });
}
