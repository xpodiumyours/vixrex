import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { verifyRecaptchaToken } from "@/lib/recaptchaServer";
import { fingerprintClient, getClientIp } from "@/lib/rentDemoSecurity";

// "Bu vitrini kirala" — Keşfet ekranındaki demo vitrin kartından açılır.
//
// GÜVENLİK AÇIĞI KAPATILDI (2026-08-15): bu rota önceden GET'te doğrudan
// veritabanı yazıyordu, hiçbir kimlik/oran sınırlaması yoktu — saldırgan
// bu rotayı hiç görmeden Supabase'in herkese açık anon anahtarıyla
// clone_demo_store_as_draft RPC'sini doğrudan çağırıp sınırsız kopya
// üretebiliyordu (bkz. supabase/migrations/20260815180000_secure_rent_demo_flow.sql).
//
// V-57 FIX (2026-08-24): service role bypass kapatıldı.
// Yeni zincir (Option A — Least Privilege):
//   GET  → veritabanına DOKUNMAZ, yalnız /rent-demo?slug=x'e 303 (eski
//          yüklü Flutter APK'ları hâlâ GET atıyor — kırmadan yönlendirir).
//   POST → reCAPTCHA v3 doğrula → IP'yi HMAC'le → NORMAL CLIENT (user JWT)
//          ile start_demo_trial RPC'sini çağır (oran sınırı + klonlama,
//          TEK transaction'da) → slug + edit_token al → yine NORMAL CLIENT
//          ile create_owner_session çağır (edit_token ile) → code al →
//          /api/owner-session'a 303.
//
// /rent-demo/page.tsx (yeni köprü sayfası) reCAPTCHA token'ını alıp bu
// POST'u otomatik gönderir — hem web CTA'sı hem Flutter'ın harici
// tarayıcıda açtığı link aynı sayfaya düşer.

export const dynamic = "force-dynamic";

const ERROR_COPY: Record<string, string> = {
  INVALID_SLUG: "Vitrin bulunamadı.",
  SOURCE_NOT_FOUND: "Bu vitrin artık kiralık örnek olarak mevcut değil.",
  RATE_LIMITED: "Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar dene.",
  SLUG_GENERATION_FAILED: "Vitrin şu anda kiralanamıyor. Lütfen tekrar dene.",
  RECAPTCHA_FAILED: "Güvenlik doğrulaması başarısız. Lütfen sayfayı yenileyip tekrar dene.",
  SERVICE_UNAVAILABLE: "Vitrin şu anda kiralanamıyor. Lütfen biraz sonra tekrar dene.",
  OWNER_SESSION_FAILED: "Düzenleme oturumu açılamadı. Lütfen tekrar dene.",
};

function rentErrorPage(title: string, message: string): Response {
  const html = `<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta name="robots" content="noindex" />
<title>Vitrin Açılamadı</title>
<style>
  body { margin: 0; background: #0B1120; color: #fff; font-family: system-ui, -apple-system, sans-serif; display: grid; place-items: center; min-height: 100vh; }
  main { max-width: 420px; padding: 24px; text-align: center; }
  h1 { font-size: 20px; }
  p { color: rgba(255,255,255,0.7); line-height: 1.6; }
</style>
</head>
<body>
<main>
  <h1>${title}</h1>
  <p>${message}</p>
</main>
</body>
</html>`;

  return new Response(html, {
    status: 400,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

// GET: artık veritabanına dokunmaz. Eski (güncellenmemiş) Flutter APK'ları
// hâlâ bu URL'i açıyor — onları kırmadan güvenli köprü sayfasına taşır.
export async function GET(request: Request) {
  const url = new URL(request.url);
  const demoSlug = url.searchParams.get("slug")?.trim() ?? "";

  const destination = new URL("/rent-demo", url);
  if (demoSlug) destination.searchParams.set("slug", demoSlug);

  const response = NextResponse.redirect(destination, 303);
  response.headers.set("cache-control", "no-store");
  return response;
}

export async function POST(request: Request) {
  // /rent-demo/page.tsx gerçek bir <form method="POST"> gönderiyor (fetch
  // değil, bilerek — tarayıcı böylece 303 → owner-session → 303 zincirini
  // ve çerez kurulumunu native izliyor) — gövde form-urlencoded, JSON değil.
  let formData: FormData;
  try {
    formData = await request.formData();
  } catch {
    return rentErrorPage("Vitrin bulunamadı", "Geçersiz istek.");
  }

  const slugValue = formData.get("slug");
  const tokenValue = formData.get("recaptchaToken");
  const demoSlug = typeof slugValue === "string" ? slugValue.trim() : "";
  const recaptchaToken = typeof tokenValue === "string" ? tokenValue.trim() : "";

  if (!demoSlug) {
    return rentErrorPage(
      "Vitrin bulunamadı",
      "Kiralama isteğinde vitrin bilgisi eksik."
    );
  }

  if (!recaptchaToken) {
    return rentErrorPage("Vitrin açılamadı", ERROR_COPY.RECAPTCHA_FAILED);
  }

  // rent_demo daha maliyetli bir eylem (gerçek veri üretimi) olduğu için
  // proje genelindeki varsayılan eşikten (0.3, bkz. recaptchaServer.ts)
  // bilerek daha sıkı bir eşik kullanılıyor.
  const recaptchaResult = await verifyRecaptchaToken(recaptchaToken, "rent_demo", {
    minScore: 0.5,
  });
  if (!recaptchaResult.success) {
    console.warn("[rent-demo] reCAPTCHA reddedildi:", recaptchaResult.error);
    return rentErrorPage("Vitrin açılamadı", ERROR_COPY.RECAPTCHA_FAILED);
  }

  let clientKey: string;
  try {
    clientKey = fingerprintClient(getClientIp(request));
  } catch (err) {
    // V-16: RATE_LIMIT_SECRET üretimde yoksa fail-closed — ham IP asla
    // kullanılmaz, kiralama devam etmez.
    console.error("[rent-demo] client fingerprint unavailable:", err);
    return rentErrorPage("Vitrin açılamadı", ERROR_COPY.SERVICE_UNAVAILABLE);
  }

  // V-57 FIX: Normal client (user JWT) ile çağır — service role KULLANMA.
  // Authorization header'ı form POST'unda gelmez (browser native form submit),
  // bu yüzden anon client kullanırız. Rate limit IP tabanlı (clientKey) zaten
  // start_demo_trial içinde uygulanıyor.
  const authHeader = request.headers.get("Authorization");
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      global: authHeader ? { headers: { Authorization: authHeader } } : undefined,
    }
  );

  // 1) start_demo_trial: rate limit + klonlama → slug + edit_token döner
  const { data: trialData, error: trialError } = await supabase.rpc(
    "start_demo_trial",
    {
      p_source_slug: demoSlug,
      p_client_key: clientKey,
    }
  );

  if (trialError) {
    const message = ERROR_COPY[trialError.message] ?? "Vitrin şu anda kiralanamıyor. Lütfen tekrar dene.";
    console.error("[rent-demo] start_demo_trial failed", trialError.message);
    return rentErrorPage("Vitrin açılamadı", message);
  }

  const trialResult = trialData as { slug?: string; edit_token?: string; expires_at?: string } | null;
  if (!trialResult?.slug || !trialResult?.edit_token) {
    console.error("[rent-demo] start_demo_trial returned no slug/edit_token");
    return rentErrorPage("Vitrin açılamadı", "Kopya oluşturuldu ama düzenleme oturumu açılamadı. Lütfen tekrar dene.");
  }

  // 2) create_owner_session: edit_token ile owner session aç → code döner
  const { data: sessionData, error: sessionError } = await supabase.rpc(
    "create_owner_session",
    {
      p_slug: trialResult.slug,
      p_edit_token: trialResult.edit_token,
    }
  );

  if (sessionError) {
    console.error("[rent-demo] create_owner_session failed", sessionError.message);
    return rentErrorPage("Vitrin açılamadı", ERROR_COPY.OWNER_SESSION_FAILED);
  }

  const sessionResult = sessionData as { code?: string; expires_at?: string } | null;
  if (!sessionResult?.code) {
    console.error("[rent-demo] create_owner_session returned no code");
    return rentErrorPage("Vitrin açılamadı", ERROR_COPY.OWNER_SESSION_FAILED);
  }

  const url = new URL(request.url);
  const destination = new URL("/api/owner-session", url);
  destination.searchParams.set("slug", trialResult.slug);
  destination.searchParams.set("ocode", sessionResult.code);

  const response = NextResponse.redirect(destination, 303);
  response.headers.set("cache-control", "no-store");
  return response;
}