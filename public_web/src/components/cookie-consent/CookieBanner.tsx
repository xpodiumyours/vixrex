"use client";

import { useState, useSyncExternalStore } from "react";
import {
  type CookieConsent,
  parseConsentSnapshot,
  readConsentSnapshot,
  subscribeToConsent,
  writeConsent,
} from "@/lib/cookieConsent";

const subscribeToHydration = () => () => undefined;
const getClientHydrationSnapshot = () => true;
const getServerHydrationSnapshot = () => false;

export function CookieBanner() {
  const hydrated = useSyncExternalStore(
    subscribeToHydration,
    getClientHydrationSnapshot,
    getServerHydrationSnapshot,
  );
  const consentSnapshot = useSyncExternalStore(
    subscribeToConsent,
    readConsentSnapshot,
    () => null,
  );
  const existingConsent = parseConsentSnapshot(consentSnapshot);
  const [dismissed, setDismissed] = useState(false);
  const [reopened, setReopened] = useState(false);
  const [customize, setCustomize] = useState(false);
  const [analytics, setAnalytics] = useState(false);
  const [marketing, setMarketing] = useState(false);

  function persist(next: Pick<CookieConsent, "analytics" | "marketing">) {
    writeConsent(next);
    setDismissed(true);
    setReopened(false);
    setCustomize(false);
  }

  if (!hydrated) return null;

  if (existingConsent && !reopened) {
    return (
      <button
        type="button"
        aria-label="Çerez tercihlerini yeniden düzenle"
        onClick={() => {
          setAnalytics(existingConsent.analytics);
          setMarketing(existingConsent.marketing);
          setCustomize(true);
          setReopened(true);
          setDismissed(false);
        }}
        className="fixed bottom-1 left-2 z-30 text-[11px] text-lp-muted/40 hover:text-lp-text underline bg-transparent border-0 p-1 shadow-none transition-opacity focus:opacity-100"
      >
        Çerez tercihleri
      </button>
    );
  }

  if (dismissed) return null;

  return (
    <div
      className="fixed inset-x-0 bottom-0 z-50 border-t border-lp-border bg-lp-surface/98 px-4 py-3 shadow-2xl backdrop-blur-md md:px-8"
      role="dialog"
      aria-label="Çerez tercihleri"
    >
      <div className="mx-auto flex max-w-6xl flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div className="flex-1">
          <p className="text-xs leading-relaxed text-lp-text-alt md:text-sm">
            Sitemizde temel işlevler için gerekli çerezler kullanılmaktadır. Analitik ve pazarlama çerezleri yalnızca izninizle açılır.
          </p>
        </div>

        <div className="flex shrink-0 flex-wrap items-center gap-2">
          <button
            type="button"
            className="rounded-lg border border-lp-border bg-lp-surface-soft px-3.5 py-1.5 text-xs font-semibold text-lp-text transition-colors hover:bg-lp-surface md:text-sm"
            onClick={() => persist({ analytics: false, marketing: false })}
          >
            Yalnızca gerekli
          </button>
          <button
            type="button"
            className="rounded-lg bg-lp-primary px-4 py-1.5 text-xs font-black text-lp-on-primary transition-colors hover:bg-lp-secondary shadow md:text-sm"
            onClick={() => persist({ analytics: true, marketing: true })}
          >
            Tümünü kabul et
          </button>
          <button
            type="button"
            className="rounded-lg px-2.5 py-1.5 text-xs font-semibold text-lp-muted underline-offset-2 hover:text-lp-text hover:underline transition-colors"
            onClick={() => setCustomize((v) => !v)}
          >
            {customize ? "Gizle" : "Özelleştir"}
          </button>
          {reopened ? (
            <button
              type="button"
              className="rounded-lg px-2 py-1.5 text-xs font-semibold text-lp-muted underline-offset-2 hover:text-lp-text hover:underline transition-colors"
              onClick={() => setReopened(false)}
            >
              Vazgeç
            </button>
          ) : null}
        </div>
      </div>

      {customize ? (
        <div className="mx-auto mt-3 max-w-6xl flex flex-col gap-2.5 rounded-xl border border-lp-border/70 bg-lp-surface-soft/60 p-3.5">
          <label className="flex items-center justify-between gap-3 text-xs md:text-sm font-medium text-lp-text cursor-pointer">
            <span>Gerekli (zorunlu)</span>
            <input type="checkbox" checked disabled readOnly className="accent-lp-primary opacity-60" />
          </label>
          <label className="flex items-center justify-between gap-3 text-xs md:text-sm font-medium text-lp-text cursor-pointer">
            <span>Analitik</span>
            <input
              type="checkbox"
              checked={analytics}
              onChange={(e) => setAnalytics(e.target.checked)}
              className="accent-lp-primary cursor-pointer"
            />
          </label>
          <label className="flex items-center justify-between gap-3 text-xs md:text-sm font-medium text-lp-text cursor-pointer">
            <span>Pazarlama</span>
            <input
              type="checkbox"
              checked={marketing}
              onChange={(e) => setMarketing(e.target.checked)}
              className="accent-lp-primary cursor-pointer"
            />
          </label>
          <button
            type="button"
            className="mt-1 w-full rounded-lg bg-lp-primary px-4 py-2 text-xs md:text-sm font-black text-lp-on-primary transition-colors hover:bg-lp-secondary shadow"
            onClick={() => persist({ analytics, marketing })}
          >
            Tercihleri kaydet
          </button>
        </div>
      ) : null}
    </div>
  );
}
