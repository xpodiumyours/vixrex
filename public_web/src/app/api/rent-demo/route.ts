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
//   POST → gerçek akış: reCAPTCHA v3 ek sinyalini doğrula (Google erişilemezse
//          akışı kilitlemez) → IP'yi HMAC'le → SERVİS ROLÜYLE start_demo_trial
//          RPC'sini çağır. Zorunlu güvenlik kapısı DB'deki kısa/günlük/global
//          oran sınırı + atomik klonlama ve owner-session zinciridir →
//          /api/owner-session'a 303.
//
// /rent-demo/page.tsx (yeni köprü sayfası) reCAPTCHA token'ını alıp bu
// POST'u otomatik gönderir — hem web CTA'sı hem Flutter'ın harici
// tarayıcıda açtığı link aynı sayfaya düşer.

export const dynamic = "force-dynamic";

const PRODUCTION_RENT_DEMO_URL = "https://vixrex.com/api/rent-demo";

const ERROR_COPY: Record<string, string> = {
  INVALID_SLUG: "Vitrin bulunamadı.",
  SOURCE_NOT_FOUND: "Bu vitrin artık kiralık örnek olarak mevcut değil.",
  RATE_LIMITED: "Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar dene.",
  SLUG_GENERATION_FAILED: "Vitrin şu anda kiralanamıyor. Lütfen tekrar dene.",
  SERVICE_UNAVAILABLE: "Vitrin şu anda kiralanamıyor. Lütfen biraz sonra tekrar dene.",
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

/**
 * Vercel Preview ortamında server-only sırlar Preview'a tanımlı değilse
 * kiralama akışı daha `start_demo_trial` çağrısına ulaşmadan 500 oluyordu.
 *
 * Preview'a servis rolü anahtarı gömmek yerine yalnız ayrıcalıklı klonlama
 * adımını canlı Vixrex backend'ine yaptırıyoruz. Canlı backend kendi
 * RATE_LIMIT_SECRET + SERVICE_ROLE güvenlik sınırını kullanır ve tek
 * kullanımlık owner code döndüren 303 Location üretir. Bu kod burada
 * okunur ve PREVIEW domain'indeki /api/owner-session'a aktarılır; böylece
 * kullanıcı klonlanan vitrini aynı PR'ın sahiplik UI'ıyla açar.
 *
 * Production davranışı değişmez. Preview'da gerekli server secret'ları
 * gerçekten varsa da normal yerel akış kullanılmaya devam eder.
 */
async function previewRentalBridge(
  request: Request,
  demoSlug: string,
): Promise<Response | null> {
  if (process.env.VERCEL_ENV !== "preview") return null;

  const serviceRoleHazir = Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY?.trim());
  const rateLimitHazir = Boolean(process.env.RATE_LIMIT_SECRET?.trim());
  if (serviceRoleHazir && rateLimitHazir) return null;

  let upstream: Response;
  try {
    const body = new URLSearchParams({
      slug: demoSlug,
      recaptchaToken: "recaptcha-unavailable",
    });

    upstream = await fetch(PRODUCTION_RENT_DEMO_URL, {
      method: "POST",
      headers: {
        "content-type": "application/x-www-form-urlencoded",
        "user-agent": "Vixrex-Preview-Rental-Bridge/1.0",
      },
      body: body.toString(),
      redirect: "manual",
      cache: "no-store",
    });
  } catch (err) {
    console.error("[rent-demo] preview production bridge request failed", err);
    return rentErrorPage("Vitrin açılamadı", ERROR_COPY.SERVICE_UNAVAILABLE);
  }

  if (upstream.status >= 300 && upstream.status < 400) {
    const location = upstream.headers.get("location");
    if (!location) {
      console.error("[rent-demo] preview bridge redirect missing location");
      return rentErrorPage("Vitrin açılamadı", ERROR_COPY.SERVICE_UNAVAILABLE);
    }

    const upstreamDestination = new URL(location, PRODUCTION_RENT_DEMO_URL);
    const slug = upstreamDestination.searchParams.get("slug")?.trim() ?? "";
    const code = upstreamDestination.searchParams.get("ocode")?.trim() ?? "";

    if (
      upstreamDestination.pathname !== "/api/owner-session" ||
      !slug ||
      !code
    ) {
      console.error("[rent-demo] preview bridge returned unexpected redirect");
      return rentErrorPage("Vitrin açılamadı", ERROR_COPY.SERVICE_UNAVAILABLE);
    }

    const localUrl = new URL(request.url);
    const destination = new URL("/api/owner-session", localUrl);
    destination.searchParams.set("slug", slug);
    destination.searchParams.set("ocode", code);

    const response = NextResponse.redirect(destination, 303);
    response.headers.set("cache-control", "no-store");
    return response;
  }

  if (!upstream.ok) {
    const contentType = upstream.headers.get("content-type") || "text/html; charset=utf-8";
    const body = await upstream.text().catch(() => "");
    if (body) {
      return new Response(body, {
        status: upstream.status,
        headers: {
          "content-type": contentType,
          "cache-control": "no-store",
        },
      });
    }

    return rentErrorPage("Vitrin açılamadı", ERROR_COPY.SERVICE_UNAVAILABLE);
  }

  console.error("[rent-demo] preview bridge returned unexpected success response");
  return rentErrorPage("Vitrin açılamadı", ERROR_COPY.SERVICE_UNAVAILABLE);
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

  const bridged = await previewRentalBridge(request, demoSlug);
  if (bridged) return bridged;

  // reCAPTCHA ek bot sinyalidir; Google betiği/servisi mobil ağda
  // yüklenemezse kiralama sonsuza kadar beklememeli. Asıl zorunlu koruma
  // aşağıdaki HMAC istemci parmak izi ve start_demo_trial içindeki üç
  // katmanlı oran sınırıdır (3/10 dk, 10/gün, 100/saat global).
  if (recaptchaToken && recaptchaToken !== "recaptcha-unavailable") {
    const recaptchaResult = await verifyRecaptchaToken(
      recaptchaToken,
      "rent_demo",
      { minScore: 0.5 }
    );
    if (!recaptchaResult.success) {
      console.warn(
        "[rent-demo] reCAPTCHA kullanılamadı; oran sınırlı akış sürüyor:",
        recaptchaResult.error,
        "errorCodes:",
        recaptchaResult.errorCodes,
        "score:",
        recaptchaResult.score
      );
    }
  } else {
    console.warn(
      "[rent-demo] reCAPTCHA tokenı yok; oran sınırlı akış sürüyor"
    );
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

  let admin;
  try {
    admin = getSupabaseAdmin();
  } catch (err) {
    console.error("[rent-demo] Supabase admin unavailable", err);
    return rentErrorPage("Vitrin açılamadı", ERROR_COPY.SERVICE_UNAVAILABLE);
  }

  const { data, error } = await admin.rpc("start_demo_trial", {
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
