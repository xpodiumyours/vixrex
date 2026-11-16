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
        className="fixed bottom-3 left-3 z-40 rounded-full border border-lp-border bg-lp-surface px-3.5 py-2 text-xs font-semibold text-lp-text shadow-lg hover:bg-lp-surface-soft transition-colors"
      >
        Çerez tercihleri
      </button>
    );
  }

  if (dismissed) return null;

  return (
    <div
      className="fixed inset-x-4 bottom-4 z-50 mx-auto max-w-2xl rounded-2xl border border-lp-border bg-lp-surface/95 p-5 shadow-2xl backdrop-blur-md md:inset-x-auto md:left-1/2 md:w-[calc(100%-2rem)] md:-translate-x-1/2"
      role="dialog"
      aria-label="Çerez tercihleri"
    >
      <div className="flex flex-col gap-3">
        <p className="text-sm leading-relaxed text-lp-text-alt">
          Gerekli çerezler siteyi çalıştırmak için kullanılır. Analitik ve
          pazarlama çerezleri yalnızca izninizle açılır. Resmi çerez politikası
          yakında yayınlanacaktır.
        </p>

        {customize ? (
          <div className="flex flex-col gap-2.5 rounded-xl border border-lp-border/70 bg-lp-surface-soft/60 p-3.5">
            <label className="flex items-center justify-between gap-3 text-sm font-medium text-lp-text cursor-pointer">
              <span>Gerekli (zorunlu)</span>
              <input type="checkbox" checked disabled readOnly className="accent-lp-primary opacity-60" />
            </label>
            <label className="flex items-center justify-between gap-3 text-sm font-medium text-lp-text cursor-pointer">
              <span>Analitik</span>
              <input
                type="checkbox"
                checked={analytics}
                onChange={(e) => setAnalytics(e.target.checked)}
                className="accent-lp-primary cursor-pointer"
              />
            </label>
            <label className="flex items-center justify-between gap-3 text-sm font-medium text-lp-text cursor-pointer">
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
              className="mt-2 w-full rounded-lg bg-lp-primary px-4 py-2 text-sm font-black text-lp-on-primary transition-colors hover:bg-lp-secondary shadow"
              onClick={() => persist({ analytics, marketing })}
            >
              Tercihleri kaydet
            </button>
          </div>
        ) : null}

        <div className="flex flex-wrap items-center gap-2">
          <button
            type="button"
            className="rounded-lg bg-lp-primary px-4 py-2 text-sm font-black text-lp-on-primary transition-colors hover:bg-lp-secondary shadow"
            onClick={() => persist({ analytics: true, marketing: true })}
          >
            Tümünü kabul et
          </button>
          <button
            type="button"
            className="rounded-lg border border-lp-border bg-lp-surface-soft px-4 py-2 text-sm font-semibold text-lp-text transition-colors hover:bg-lp-surface"
            onClick={() => persist({ analytics: false, marketing: false })}
          >
            Yalnızca gerekli
          </button>
          {reopened ? (
            <button
              type="button"
              className="rounded-lg px-4 py-2 text-sm font-semibold text-lp-muted underline-offset-2 hover:text-lp-text hover:underline transition-colors"
              onClick={() => setReopened(false)}
            >
              Vazgeç
            </button>
          ) : null}
          <button
            type="button"
            className="rounded-lg px-4 py-2 text-sm font-semibold text-lp-muted underline-offset-2 hover:text-lp-text hover:underline transition-colors"
            onClick={() => setCustomize((v) => !v)}
          >
            {customize ? "Gizle" : "Özelleştir"}
          </button>
        </div>
      </div>
    </div>
  );
}
