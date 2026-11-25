import type { Metadata, Viewport } from "next";
import localFont from "next/font/local";
import * as Sentry from "@sentry/nextjs";
import { getSiteUrl } from "@/lib/siteUrl";
import { CookieConsentRoot } from "@/components/cookie-consent/CookieConsentRoot";
import { RecaptchaProvider } from "@/components/recaptcha/RecaptchaProvider";
import { AppShellBoundary } from "@/components/app/AppShellBoundary";
import "./globals.css";
import "./vixrex-app-ui.css";

// 2026-08-26 (#344): fontlar globals.css'in en ustundeki Google Fonts
// `@import`'undan alinmisti — render'i bloklayan bir ucuncu taraf stil
// dosyasi, ustelik yalnizca 300-800 agirliklarini getiriyordu. Landing
// basliklarinin tamami w900 (Black). next/font derleme aninda indirip
// kendi alan adimizdan servis eder; agirlik listesi eksiksiz.
const outfit = localFont({
  src: [
    { path: "./fonts/Outfit-300.woff2", weight: "300", style: "normal" },
    { path: "./fonts/Outfit-400.woff2", weight: "400", style: "normal" },
    { path: "./fonts/Outfit-500.woff2", weight: "500", style: "normal" },
    { path: "./fonts/Outfit-600.woff2", weight: "600", style: "normal" },
    { path: "./fonts/Outfit-700.woff2", weight: "700", style: "normal" },
    { path: "./fonts/Outfit-800.woff2", weight: "800", style: "normal" },
    { path: "./fonts/Outfit-900.woff2", weight: "900", style: "normal" },
  ],
  variable: "--font-outfit-src",
  display: "swap",
  adjustFontFallback: "Arial",
});

const instrumentSerif = localFont({
  src: [
    {
      path: "./fonts/InstrumentSerif-Regular.woff2",
      weight: "400",
      style: "normal",
    },
    {
      path: "./fonts/InstrumentSerif-Italic.woff2",
      weight: "400",
      style: "italic",
    },
  ],
  variable: "--font-vitrin-display-src",
  display: "swap",
  adjustFontFallback: "Times New Roman",
});

export const metadata: Metadata = {
  title: "Vixrex | İşletmenizin Dijital Vitrini",
  description:
    "İşletme bilgilerinizi, fotoğraflarınızı, ürün ve hizmetlerinizi, adresinizi ve WhatsApp iletişiminizi tek vitrin linkinde toplayın ve QR kodla paylaşın.",
  metadataBase: new URL(getSiteUrl()),
  verification: {
    google: "EDYISkto7FZ88bohG5vwlJJgR4UEqRcL8lkV48cu7t0",
  },
  other: {
    "mitgo-verification": "7db678d9-bb04-443d-9502-6c60d868823a",
    // Next.js standart adı (`mobile-web-app-capable`) yazıyor; Apple'ın eski
    // adını artık yazmıyor. Eski iOS sürümleri yalnız eskisini tanıdığı için
    // ikisi birden veriliyor — fazlası zararsız, eksiği iPhone'da siteyi
    // tarayıcı çubuğuyla açtırır.
    "apple-mobile-web-app-capable": "yes",
  },
  // iOS manifest'i ana ekran ikonu için OKUMAZ; ayrıca apple-touch-icon ister.
  // Bu olmadan iPhone'da ana ekrana eklenen site, sayfanın ekran görüntüsünü
  // ikon olarak kullanır.
  icons: {
    apple: "/apple-icon-180.png",
  },
  // iOS'ta tarayıcı çubuğu olmadan, kendi penceresinde açılması için.
  // (Android bunu manifest'teki `display: standalone` ile yapar.)
  appleWebApp: {
    capable: true,
    title: "Vixrex",
    statusBarStyle: "black-translucent",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  viewportFit: "cover",
  themeColor: "#0c0d10",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="tr"
      className={`h-full antialiased font-outfit ${outfit.variable} ${instrumentSerif.variable}`}
    >
      <body className="min-h-full flex flex-col bg-[#F4F5F8] dark:bg-[#0B0F13] text-[#182028] dark:text-[#F1F5F9]">
        <Sentry.ErrorBoundary fallback={<p>Bir hata oluştu.</p>}>
          <RecaptchaProvider>
            <AppShellBoundary>{children}</AppShellBoundary>
          </RecaptchaProvider>
        </Sentry.ErrorBoundary>
        <CookieConsentRoot />
      </body>
    </html>
  );
}
