"use client";

import { useSyncExternalStore } from "react";
import {
  parseConsentSnapshot,
  readConsentSnapshot,
  subscribeToConsent,
} from "@/lib/cookieConsent";

/**
 * Yüzen maskot — envanter §2.12.
 *
 * Flutter'da bu düğme sohbet motorunu (VixRexSessionController) açıyor;
 * web'de aynı akışı taklit eder: tıklanınca asistan sohbeti telefon
 * mockup'ının içinde açılır (VixRexOnboardingChatScreen compact modu).
 *
 * Bu bileşen SADECE maskot butonunu ve balonunu gösterir.
 * Sohbet paneli PhoneMockup içinde çizilir.
 *
 * Davranış:
 *  - Sayfa açıldığında balon görünür (uygulamadaki gibi).
 *  - Maskot tıklanınca balon kapanır, ascendant'a toggle sinyali gider.
 *  - Ascendant (page.tsx) bu sinyalle PhoneMockup'a isChatOpen geçirir.
 *
 * ÇEREZ BİLDİRİMİ ÇAKIŞMASI (2026-08-26, gerçek tarayıcıda ölçüldü):
 * `CookieBanner` ekranın altını baştan sona kaplıyor (`fixed inset-x-0
 * bottom-0 z-50`) ve maskotun üstüne biniyordu — siteye İLK giren kişi,
 * yani çerez seçimini henüz yapmamış herkes, maskota tıklayamıyordu.
 * Asistanı açan tek düğme oydu. (Playwright 60 denemenin hepsinde
 * "cookie dialog intercepts pointer events" ile düştü.)
 *
 * Çözüm: çerez seçimi yapılana kadar maskot hiç çizilmez. Yukarı kaydırmak
 * yerine gizlemeyi seçtim çünkü bildirimin yüksekliği içeriğe ve ekran
 * genişliğine göre değişiyor; sabit bir kaydırma değeri dar ekranda yine
 * çakışırdı. Seçim yapılır yapılmaz maskot kendiliğinden görünür.
 */
export function MascotFab({ onToggle }: { onToggle: () => void }) {
  const consentSnapshot = useSyncExternalStore(
    subscribeToConsent,
    readConsentSnapshot,
    () => null,
  );
  if (!parseConsentSnapshot(consentSnapshot)) return null;

  return (
    <div className="pointer-events-none fixed bottom-5 right-5 z-40 flex flex-col items-end gap-2">
      {/* Balon — tıklanınca da asistan açılır */}
      <p
        className="pointer-events-auto max-w-[230px] cursor-pointer rounded-2xl border border-lp-border bg-lp-surface px-4 py-3 text-[13px] font-semibold text-lp-text-alt shadow-lp-card transition-opacity hover:opacity-90"
        onClick={onToggle}
      >
        👋 Dijital vitrinini hazırlayayım mı?
      </p>

      {/* Maskot butonu */}
      <button
        type="button"
        onClick={onToggle}
        className="pointer-events-auto flex h-[60px] w-[60px] items-center justify-center rounded-full border border-lp-primary/40 bg-lp-surface shadow-lp-panel transition-transform hover:scale-105"
        aria-label="Vixrex Asistan'ı aç"
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/images/vixrex_v_crystal_mascot.png"
          alt=""
          width={44}
          height={44}
          className="h-11 w-11 object-contain"
        />
      </button>
    </div>
  );
}
