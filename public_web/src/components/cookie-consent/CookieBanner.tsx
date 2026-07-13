"use client";

import { useState, useSyncExternalStore } from "react";
import {
  type CookieConsent,
  parseConsentSnapshot,
  readConsentSnapshot,
  subscribeToConsent,
  writeConsent,
} from "@/lib/cookieConsent";

export function CookieBanner() {
  const consentSnapshot = useSyncExternalStore(
    subscribeToConsent,
    readConsentSnapshot,
    () => null,
  );
  const existingConsent = parseConsentSnapshot(consentSnapshot);
  const [dismissed, setDismissed] = useState(false);
  const [customize, setCustomize] = useState(false);
  const [analytics, setAnalytics] = useState(false);
  const [marketing, setMarketing] = useState(false);

  function persist(next: Pick<CookieConsent, "analytics" | "marketing">) {
    writeConsent(next);
    setDismissed(true);
    setCustomize(false);
  }

  if (existingConsent || dismissed) return null;

  return (
    <div
      className="fixed inset-x-0 bottom-0 z-50 border-t border-black/10 bg-white p-4 shadow-lg dark:border-white/10 dark:bg-[#121820]"
      role="dialog"
      aria-label="Çerez tercihleri"
    >
      <div className="mx-auto flex max-w-3xl flex-col gap-3">
        <p className="text-sm leading-relaxed text-[#182028] dark:text-[#E2E8F0]">
          Gerekli çerezler siteyi çalıştırmak için kullanılır. Analitik ve
          pazarlama çerezleri yalnızca izninizle açılır. Resmi çerez politikası
          yakında yayınlanacaktır.
        </p>

        {customize ? (
          <div className="flex flex-col gap-2 rounded-xl border border-black/10 p-3 dark:border-white/10">
            <label className="flex items-center justify-between gap-3 text-sm">
              <span>Gerekli (zorunlu)</span>
              <input type="checkbox" checked disabled readOnly />
            </label>
            <label className="flex items-center justify-between gap-3 text-sm">
              <span>Analitik</span>
              <input
                type="checkbox"
                checked={analytics}
                onChange={(e) => setAnalytics(e.target.checked)}
              />
            </label>
            <label className="flex items-center justify-between gap-3 text-sm">
              <span>Pazarlama</span>
              <input
                type="checkbox"
                checked={marketing}
                onChange={(e) => setMarketing(e.target.checked)}
              />
            </label>
            <button
              type="button"
              className="mt-1 rounded-lg bg-[#00F0FF] px-4 py-2 text-sm font-bold text-black"
              onClick={() => persist({ analytics, marketing })}
            >
              Tercihleri kaydet
            </button>
          </div>
        ) : null}

        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            className="rounded-lg bg-[#00F0FF] px-4 py-2 text-sm font-bold text-black"
            onClick={() => persist({ analytics: true, marketing: true })}
          >
            Tümünü kabul et
          </button>
          <button
            type="button"
            className="rounded-lg border border-black/15 px-4 py-2 text-sm font-semibold dark:border-white/20"
            onClick={() => persist({ analytics: false, marketing: false })}
          >
            Yalnızca gerekli
          </button>
          <button
            type="button"
            className="rounded-lg px-4 py-2 text-sm font-semibold underline-offset-2 hover:underline"
            onClick={() => setCustomize((v) => !v)}
          >
            {customize ? "Gizle" : "Özelleştir"}
          </button>
        </div>
      </div>
    </div>
  );
}
