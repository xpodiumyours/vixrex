import type { NextConfig } from "next";
import { withSentryConfig } from "@sentry/nextjs";
import path from "path";

const fallbackAppUrl = "https://vixrex-app.vercel.app";

function getAppUrl() {
  const configured = process.env.NEXT_PUBLIC_APP_URL?.trim();
  if (!configured) return fallbackAppUrl;

  try {
    return new URL(configured).origin;
  } catch {
    return fallbackAppUrl;
  }
}

// CSP (2026-08-15 taraması: CSP eksikti). 2026-08-16 sıkılaştırma:
//   - 'unsafe-eval' KALDIRILDI (yalnız dev React'inin eval'i için gerekiyor,
//     prod build'te gerekmez — bu yüzden yalnız NODE_ENV==='development'
//     iken eklenir, prod CSP'sinde YOK).
//   - img-src jokeri ('*') KALDIRILDI: yerine projein gerçekten kullandığı
//     host allowlist'i kondu (supabase storage, instagram CDN, recaptcha/
//     turnstile/GA domainleri). Gereksiz '*' yok.
//   - script-src hâlâ 'unsafe-inline' taşıyor: Next.js App Router'ın kendi
//     inline hydration script'leri nonce olmadan çalışmaz. Nonce tabanlı
//     sıkı CSP, tüm sayfaların dinamik render edilmesini zorunlu kılar
//     (Next.js 16 belgeli kısıt) — bu, üretim vitrinini invaziv değiştirir
//     ve bu ortamda runtime doğrulanamaz; bu yüzden kapsam dışı bırakıldı.
//     KALAN RİSK: 'unsafe-inline' script-src'te — izole XSS'yi tam
//     engellemez (bkz. rapor). İleride proxy.ts + per-request nonce ile
//     kaldırılacak takip işi olarak not edildi.
// Kullanılan gerçek kaynaklar (grep ile tarandı):
//   - reCAPTCHA v3: www.google.com, www.gstatic.com (script)
//   - Cloudflare Turnstile: challenges.cloudflare.com (script + frame + img)
//   - GA4 (rıza varsa): www.googletagmanager.com (script),
//     www.google-analytics.com / *.analytics.google.com (connect + img)
//   - Google Maps embed iframe (VitrinProfileView.tsx): www.google.com
//   - Supabase: *.supabase.co (connect + img/storage)
//   - Instagram medya: *.cdninstagram.com (img)
// 2026-08-16: Google Fonts (fonts.googleapis.com CSS + fonts.gstatic.com
// font dosyaları) gerçekten KULLANILIYOR — globals.css'teki
// `@import url('https://fonts.googleapis.com/css2?...')` sayesinde
// (Instrument Serif + Outfit, iki yüzeyde ortak yazı tipi). Önceki grep
// gözden kaçırmıştı; tarayıcı konsolu bu yüzden "Loading the stylesheet ...
// violates CSP" hatası veriyordu ve fontlar yüklenmiyordu. style-src'e
// fonts.googleapis.com, font-src'e fonts.gstatic.com eklendi.
const isDev = process.env.NODE_ENV === "development";

const CSP =
  "default-src 'self'; " +
  "script-src 'self' 'unsafe-inline'" +
  (isDev ? " 'unsafe-eval'" : "") +
  " https://challenges.cloudflare.com https://www.google.com https://www.gstatic.com https://www.googletagmanager.com; " +
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; " +
  "img-src 'self' data: blob: https://*.supabase.co https://*.cdninstagram.com https://*.gstatic.com https://www.google.com https://www.google-analytics.com https://*.analytics.google.com https://challenges.cloudflare.com; " +
  "font-src 'self' data: https://fonts.gstatic.com; " +
  "connect-src 'self' https://*.supabase.co https://challenges.cloudflare.com https://www.google.com https://www.googleapis.com https://www.google-analytics.com https://*.analytics.google.com; " +
  "frame-src 'self' https://challenges.cloudflare.com https://www.google.com; " +
  "worker-src 'self'; " +
  "manifest-src 'self'; " +
  "frame-ancestors 'none'; " +
  "base-uri 'self'; " +
  "form-action 'self';";

const securityHeaders = [
  {
    key: "X-Frame-Options",
    value: "DENY",
  },
  {
    key: "X-Content-Type-Options",
    value: "nosniff",
  },
  {
    key: "Referrer-Policy",
    value: "strict-origin-when-cross-origin",
  },
  {
    key: "Strict-Transport-Security",
    value: "max-age=63072000; includeSubDomains; preload",
  },
  {
    key: "Content-Security-Policy",
    value: CSP,
  },
];

const nextConfig: NextConfig = {
  turbopack: {
    root: path.join(__dirname, ".."),
  },
  images: {
    unoptimized: true,
    remotePatterns: [
      {
        protocol: "https",
        hostname: "**",
      },
      {
        protocol: "http",
        hostname: "**",
      },
    ],
  },
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: securityHeaders,
      },
    ];
  },
  async redirects() {
    return [
      {
        source: "/",
        destination: getAppUrl(),
        permanent: false,
      },
    ];
  },
};

export default withSentryConfig(nextConfig, {
  sourcemaps: {
    disable: true,
  },
  widenClientFileUpload: true,
});
