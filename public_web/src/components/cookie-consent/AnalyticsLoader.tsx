"use client";

import { useEffect, useState } from "react";
import Script from "next/script";
import { readConsent, type CookieConsent } from "@/lib/cookieConsent";

const GA_ID = process.env.NEXT_PUBLIC_GA_ID ?? "";

export function AnalyticsLoader() {
  const [consent, setConsent] = useState<CookieConsent | null>(null);

  useEffect(() => {
    setConsent(readConsent());
    const onUpdate = (event: Event) => {
      const detail = (event as CustomEvent<CookieConsent>).detail;
      setConsent(detail ?? readConsent());
    };
    window.addEventListener("vixrex-cookie-consent", onUpdate);
    return () => window.removeEventListener("vixrex-cookie-consent", onUpdate);
  }, []);

  if (!GA_ID || !consent?.analytics) return null;

  return (
    <>
      <Script
        src={`https://www.googletagmanager.com/gtag/js?id=${GA_ID}`}
        strategy="afterInteractive"
      />
      <Script id="vixrex-ga4" strategy="afterInteractive">
        {`
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          gtag('js', new Date());
          gtag('config', '${GA_ID}', { anonymize_ip: true });
        `}
      </Script>
    </>
  );
}
