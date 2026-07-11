"use client";

import { CookieBanner } from "./CookieBanner";
import { AnalyticsLoader } from "./AnalyticsLoader";

export function CookieConsentRoot() {
  return (
    <>
      <CookieBanner />
      <AnalyticsLoader />
    </>
  );
}
