import type { Metadata } from "next";
import { getSiteUrl } from "@/lib/siteUrl";
import { CookieConsentRoot } from "@/components/cookie-consent/CookieConsentRoot";
import "./globals.css";

export const metadata: Metadata = {
  title: "Vixrex | İşletmenizin Dijital Vitrini",
  description:
    "İşletme bilgilerinizi, fotoğraflarınızı, ürün ve hizmetlerinizi, adresinizi ve WhatsApp iletişiminizi tek vitrin linkinde toplayın ve QR kodla paylaşın.",
  metadataBase: new URL(getSiteUrl()),
  verification: {
    google: "EDYISkto7FZ88bohG5vwlJJgR4UEqRcL8lkV48cu7t0",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr" className="h-full antialiased font-outfit">
      <body className="min-h-full flex flex-col bg-[#F4F5F8] dark:bg-[#0B0F13] text-[#182028] dark:text-[#F1F5F9]">
        {children}
        <CookieConsentRoot />
      </body>
    </html>
  );
}
