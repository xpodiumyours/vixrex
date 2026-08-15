import { NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
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
// Yeni zincir:
//   GET  → veritabanına DOKUNMAZ, yalnız /rent-demo?slug=x'e 303 (eski
//          yüklü Flutter APK'ları hâlâ GET atıyor — kırmadan yönlendirir).
//   POST → gerçek akış: reCAPTCHA v3 doğrula → IP'yi HMAC'le → SERVİS
//          ROLÜYLE start_demo_trial RPC'sini çağır (oran sınırı + klonlama
//          + owner-session TEK transaction'da, bkz. migration) →
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

  const clientKey = fingerprintClient(getClientIp(request));

  const { data, error } = await getSupabaseAdmin().rpc("start_demo_trial", {
    p_source_slug: demoSlug,
    p_client_key: clientKey,
  });

  if (error) {
    const message = ERROR_COPY[error.message] ?? "Vitrin şu anda kiralanamıyor. Lütfen tekrar dene.";
    console.error("[rent-demo] start_demo_trial failed", error.message);
    return rentErrorPage("Vitrin açılamadı", message);
  }

  const result = data as { slug?: string; code?: string } | null;
  if (!result?.slug || !result?.code) {
    console.error("[rent-demo] start_demo_trial returned no slug/code");
    return rentErrorPage(
      "Vitrin açılamadı",
      "Kopya oluşturuldu ama düzenleme oturumu açılamadı. Lütfen tekrar dene."
    );
  }

  const url = new URL(request.url);
  const destination = new URL("/api/owner-session", url);
  destination.searchParams.set("slug", result.slug);
  destination.searchParams.set("ocode", result.code);

  const response = NextResponse.redirect(destination, 303);
  response.headers.set("cache-control", "no-store");
  return response;
}
