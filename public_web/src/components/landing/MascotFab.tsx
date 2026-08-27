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

      {/*
        Maskot düğmesi — Flutter'daki `chatbot_badge.dart` rozetiyle aynı
        sunum. Oradaki ölçüler birebir alındı:

          60×60 daire
          zemin   #0E1B2E, alfa 200/255  (~%78)
          kenarlık 1.5px #38A0E4, alfa 160/255 (~%63)
          parıltı  #0EA5E9
          maskot   ClipOval içinde, 4px iç boşluk, contain

        Web'de iki fark vardı: kenarlık başka renkteydi ve görsel daireye
        KIRPILMIYORDU — maskot dosyasının siyah kare zemini çerçevenin
        içinde görünüyordu. `overflow-hidden` o kareyi kesiyor.

        BİLİNÇLİ SAPMA: Flutter'da parıltı nabız gibi atıyor. Buradaki
        sabit — hareketli gölge görsel karşılaştırma testlerini sonsuza
        kadar oynatır.

        Kenarlık rengi `--primary` (#38A0E4) ile aynı; bu landing değil
        vitrin mavisi. Flutter'da da öyle, bilerek korundu.
      */}
      <button
        type="button"
        onClick={onToggle}
        className="pointer-events-auto flex h-[60px] w-[60px] items-center justify-center overflow-hidden rounded-full border-[1.5px] border-[#38A0E4]/60 bg-[#0E1B2E]/80 shadow-[0_0_16px_2px_rgba(14,165,233,0.28)] transition-transform hover:scale-105"
        aria-label="Vixrex Asistan'ı aç"
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/images/vixrex_v_crystal_mascot.png"
          alt=""
          width={60}
          height={60}
          className="h-full w-full object-contain p-1"
        />
      </button>
    </div>
  );
}
