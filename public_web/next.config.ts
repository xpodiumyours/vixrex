import type { NextConfig } from "next";
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

// CSP (2026-08-15 güvenlik taraması — eksikti). Sıkı/nonce'lı bir politika
// DEĞİL — Next.js'in kendi inline hydration script'i 'unsafe-inline'
// gerektiriyor (nonce tabanlı sıkı CSP ayrı, daha büyük bir iş, kapsam
// dışı bırakıldı). Amaç: rastgele üçüncü parti script/iframe enjeksiyonuna
// karşı savunma katmanı, mükemmel izolasyon değil. Kullanılan gerçek
// kaynaklar taranarak yazıldı:
//   - reCAPTCHA v3: www.google.com, www.gstatic.com (script)
//   - GA4 (rıza varsa): www.googletagmanager.com (script),
//     www.google-analytics.com/*.analytics.google.com (connect)
//   - Görseller: next.config'teki remotePatterns zaten "**" (herhangi bir
//     host) — img-src da aynı genişlikte olmak zorunda.
//   - Google Maps embed iframe (VitrinProfileView.tsx)
//   - Supabase: connect-src'e *.supabase.co
const CSP =
  "default-src 'self'; " +
  "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.google.com https://www.gstatic.com https://www.googletagmanager.com; " +
  "style-src 'self' 'unsafe-inline'; " +
  "img-src * data: blob:; " +
  "font-src 'self' data:; " +
  "connect-src 'self' https://*.supabase.co https://www.google.com https://www.googleapis.com https://www.google-analytics.com https://*.analytics.google.com; " +
  "frame-src https://www.google.com; " +
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
  // Faz G2 (Tek Asistan planı): vixrexMesajlari.ts repo kökündeki
  // shared/vixrex_mesajlar.json'ı import ediyor — public_web'in dışında.
  // Turbopack varsayılan olarak proje kökü dışına izin vermiyor
  // ("Module not found"); kök burada bir üst dizine (repo köküne)
  // genişletiliyor. Yalnız build-time dosya çözümlemesi, çalışma zamanı
  // bir şey açmıyor.
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

export default nextConfig;
