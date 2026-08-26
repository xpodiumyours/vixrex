"use client";

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
 */
export function MascotFab({ onToggle }: { onToggle: () => void }) {
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
