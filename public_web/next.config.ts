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
