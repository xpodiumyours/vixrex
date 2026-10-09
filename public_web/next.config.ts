import type { NextConfig } from "next";
import { withSentryConfig } from "@sentry/nextjs";
import path from "path";

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
//   - Google Maps embed iframe (VitrinProfileView.tsx): www.google.com +
//     maps.google.com (embed URL'i maps.google.com/maps?... kullanır)
//   - Demo vitrin görselleri: images.unsplash.com (VitrinProfileView + ürün
//     kartları, canlı HTML'de doğrulandı)
//   - Vitrin QR kodu: api.qrserver.com (VitrinProfileView QR bileşeni)
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
const isVercelPreview = process.env.VERCEL_ENV === "preview";

// Supabase URL ve publishable key gizli değildir; web istemcisine zaten
// gönderilen public proje kimlikleridir. Vercel env varsa her zaman öncelikli.
// Yalnız Vercel Preview env'i eksik kaldığında placeholder Supabase'e
// düşmemek için gerçek public değerler son fallback olarak kullanılır.
// Production ve yerel geliştirme bu fallback'i kullanmaz.
const publicSupabaseUrl =
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  process.env.SUPABASE_URL ||
  (isVercelPreview ? "https://chfulefxczbgurtgavtp.supabase.co" : "");
const publicSupabaseKey =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  process.env.SUPABASE_PUBLISHABLE_KEY ||
  (isVercelPreview
    ? "sb_publishable_GcCRXDh6vXFGR1UvBFG-3w_x85hvXbN" // gitleaks:allow — Supabase publishable key, sır değil
    : "");

const CSP =
  "default-src 'self'; " +
  "script-src 'self' 'unsafe-inline'" +
  (isDev ? " 'unsafe-eval'" : "") +
  " https://challenges.cloudflare.com https://www.google.com https://www.gstatic.com https://www.googletagmanager.com; " +
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; " +
  "img-src 'self' data: blob: https://*.supabase.co https://*.cdninstagram.com https://*.gstatic.com https://www.google.com https://www.google-analytics.com https://*.analytics.google.com https://challenges.cloudflare.com https://images.unsplash.com https://api.qrserver.com; " +
  "font-src 'self' data: https://fonts.gstatic.com; " +
  "connect-src 'self' https://*.supabase.co wss://*.supabase.co https://challenges.cloudflare.com https://www.google.com https://www.googleapis.com https://www.google-analytics.com https://*.analytics.google.com; " +
  "frame-src 'self' https://challenges.cloudflare.com https://www.google.com https://maps.google.com; " +
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

// sharp'in libvips paylaşımlı kütüphanesi (2026-10-01 canlı teşhisi):
//   sharp 0.35.x, linux'ta `.so` dosyalarını `@img/sharp-linux-x64` paketinin
//   İÇİNDE değil, ayrı bir hard bağımlılık olan `@img/sharp-libvips-linux-x64`
//   paketinde taşır ve oraya RPATH ile bağlanır. Next.js'in kullandığı nft
//   (node file trace) yalnız `require()` zincirini statik izler; RPATH/dlop
//   ile açılan `.so` dosyaları bu zincirde görünmez. Sonuç: derleme yeşil,
//   kurulum tam (`@img/sharp-libvips-linux-x64` lock'ta 1.3.3 olarak var) ama
//   lambda paketinde `.so` yok -> ilk istekte modül yüklenemiyor ve rota
//   500 veriyor:
//     Failed to load external module sharp-<hash>
//     Could not load the "sharp" module using the linux-x64 runtime
//     ERR_DLOPEN_FAILED: libvips-cpp.so.8.18.6: cannot open shared object file
//   Bu bilinen bir upstream sorunu (lovell/sharp#4567: sharp 0.35.x + Next 16
//   + Turbopack + Vercel; orada önerilen geçici çözüm sharp'ı 0.34.x'e
//   düşürmek — bizim kodumuz 0.35 API'sini kullanıyor, sürüm düşürmüyoruz).
//   Kalıcı çözüm: paketleri izlemeye AÇIKÇA eklemek.
const SHARP_TRACE = [
  "./node_modules/sharp/**",
  "./node_modules/@img/sharp-linux-x64/**",
  "./node_modules/@img/sharp-libvips-linux-x64/**",
];

// Bu uçlardan 9'u sharp'e RUNTIME'da transitif ulaşıyor (`import type`
// derlemede silindiği için dikkate alınmadı; liste transitive çözümle
// hesaplandı ve canlıdaki 500'lerle birebir örtüştü). Yeni bir uç sharp'e
// ulaşırsa BURAYA EKLENMEK zorunda: scripts/kontrol/sharp-trace-kapsam.mjs
// bu kuralı CI'da zorunlu kılar (eksik uç ya da bayat liste kırmızı verir).
const SHARP_ROUTES = [
  "/api/fatura-oku",
  "/api/instagram/import",
  "/api/owner-upload",
  "/api/product-image-upload",
  "/api/products/batch",
];

const nextConfig: NextConfig = {
  outputFileTracingIncludes: {
    ...Object.fromEntries(
      SHARP_ROUTES.map((route) => [route, SHARP_TRACE]),
    ),
  },
  env: {
    NEXT_PUBLIC_SUPABASE_URL: publicSupabaseUrl,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: publicSupabaseKey,
  },
  turbopack: {
    root: path.join(__dirname, ".."),
  },
  allowedDevOrigins: ["30897-ifdgxe4prkss0eold8upd.e2b.app"],
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
};

export default withSentryConfig(nextConfig, {
  sourcemaps: {
    disable: true,
  },
  widenClientFileUpload: true,
});
