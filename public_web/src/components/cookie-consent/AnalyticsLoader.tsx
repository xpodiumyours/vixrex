"use client";

import { useSyncExternalStore } from "react";
import Script from "next/script";
import {
  parseConsentSnapshot,
  readConsentSnapshot,
  subscribeToConsent,
} from "@/lib/cookieConsent";

const GA_ID = process.env.NEXT_PUBLIC_GA_ID ?? "";

export function AnalyticsLoader() {
  const consentSnapshot = useSyncExternalStore(
    subscribeToConsent,
    readConsentSnapshot,
    () => null,
  );
  const consent = parseConsentSnapshot(consentSnapshot);

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
