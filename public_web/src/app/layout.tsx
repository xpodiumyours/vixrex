import type { Metadata, Viewport } from "next";
import { Instrument_Serif, Outfit } from "next/font/google";
import * as Sentry from "@sentry/nextjs";
import { getSiteUrl } from "@/lib/siteUrl";
import { CookieConsentRoot } from "@/components/cookie-consent/CookieConsentRoot";
import { RecaptchaProvider } from "@/components/recaptcha/RecaptchaProvider";
import "./globals.css";

// 2026-08-26 (#344): fontlar globals.css'in en ustundeki Google Fonts
// `@import`'undan alinmisti — render'i bloklayan bir ucuncu taraf stil
// dosyasi, ustelik yalnizca 300-800 agirliklarini getiriyordu. Landing
// basliklarinin tamami w900 (Black). next/font derleme aninda indirip
// kendi alan adimizdan servis eder; agirlik listesi eksiksiz.
const outfit = Outfit({
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700", "800", "900"],
  variable: "--font-outfit-src",
  display: "swap",
});

const instrumentSerif = Instrument_Serif({
  subsets: ["latin"],
  weight: "400",
  style: ["normal", "italic"],
  variable: "--font-vitrin-display-src",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Vixrex | İşletmenizin Dijital Vitrini",
  description:
    "İşletme bilgilerinizi, fotoğraflarınızı, ürün ve hizmetlerinizi, adresinizi ve WhatsApp iletişiminizi tek vitrin linkinde toplayın ve QR kodla paylaşın.",
  metadataBase: new URL(getSiteUrl()),
  verification: {
    google: "EDYISkto7FZ88bohG5vwlJJgR4UEqRcL8lkV48cu7t0",
  },
};

/** Mobil tarayıcı + Flutter APK WebView için tutarlı ölçek */
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
            {children}
          </RecaptchaProvider>
        </Sentry.ErrorBoundary>
        <CookieConsentRoot />
      </body>
    </html>
  );
}
