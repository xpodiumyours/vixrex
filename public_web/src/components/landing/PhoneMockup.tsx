"use client";

import { useEffect, useState } from "react";
import type { MockupProfili } from "./mockupProfilleri";
import { PhoneMockupSlaytlari } from "./PhoneMockupSlaytlari";
import { LandingApkAssistant } from "./LandingApkAssistant";

/**
 * Hero'nun telefon mockup'ı — envanter §2.3.
 *
 * Flutter'daki phone_mockup.dart + landing_hero_mockup.dart ile birebir aynı:
 *  - 325×640 sabit boyut (LayoutBuilder ile dikey ölçekleme)
 *  - 40px köşe yuvarlatması
 *  - 2.5px kenarlık, beyaz %18
 *  - 3 katmanlı gölge (mavi parıltı + siyah + mavi glow)
 *  - Dynamic Island notch (96×22)
 *  - Home indicator (110×4)
 *
 * 2026-09-08 CANLI KARŞILAŞTIRMA DÜZELTMESİ (Playwright ekran görüntüsü +
 * iki kaynak kod): yüzen rozetler Next'te hep ilk profilde donuyordu;
 * Flutter'da (landing_hero_mockup.dart:104-122) rozetler AKTİF slayttan
 * beslenir. Bu yüzden slayt sırası buraya taşındı — rozetler ve slayt
 * aynı state'i paylaşır. Slayt noktaları da Flutter'daki gibi telefonun
 * DIŞINA alındı (orada satır 127-145: mockup Column'unun devamı).
 *
 * Flutter chat açıldığında VixRexOnboardingChatScreen telefon iç ekranına
 * gömülmez; dış Stack'in üzerinde 10px inset ve 36px radius ile overlay olur.
 * Web de aynı katman düzenini kullanır; notch/home indicator chat'in üstüne
 * binmez.
 */
export function PhoneMockup({
  profiller,
  isChatOpen = false,
  initialAssistantName = "",
  onOpenChat,
  onChatClose,
}: {
  profiller: MockupProfili[];
  isChatOpen?: boolean;
  initialAssistantName?: string;
  onOpenChat?: () => void;
  onChatClose?: () => void;
}) {
  const [aktif, setAktif] = useState(0);

  useEffect(() => {
    if (profiller.length < 2 || isChatOpen) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const zamanlayici = window.setInterval(() => {
      setAktif((mevcut) => (mevcut + 1) % profiller.length);
    }, 4000);
    return () => window.clearInterval(zamanlayici);
  }, [profiller.length, isChatOpen]);

  const profil = profiller[aktif] ?? profiller[0];
  if (!profil) return null;

  return (
    <div className="lp-phone-perspective relative mx-auto w-[280px] shrink-0 sm:w-[296px] lg:w-[304px]">
      <div
        role={isChatOpen ? undefined : "button"}
        tabIndex={isChatOpen ? -1 : 0}
        aria-label={isChatOpen ? undefined : "Vixrex Yapay Zeka Asistanını Başlat"}
        className={`lp-phone-chassis relative overflow-hidden rounded-[40px] border-[2.5px] border-sky-200/25 bg-[#0A101C] p-[8px] ${
          isChatOpen ? "lp-phone-chassis-straight" : "cursor-pointer"
        }`}
        onClick={() => {
          if (!isChatOpen) onOpenChat?.();
        }}
        onKeyDown={(event) => {
          if (!isChatOpen && (event.key === "Enter" || event.key === " ")) {
            event.preventDefault();
            onOpenChat?.();
          }
        }}
      >
        <div className="relative h-[536px] overflow-hidden rounded-[32px] border border-[#25415F] bg-[#070E1F] sm:h-[560px]">
          <div className="pointer-events-none absolute left-1/2 top-[10px] z-20 -translate-x-1/2">
            <div className="flex h-[20px] w-[86px] items-center justify-between rounded-[20px] bg-black px-[9px] shadow-[0_2px_8px_rgba(0,0,0,0.55)]">
              <div className="h-[8px] w-[8px] rounded-full border border-white/10 bg-[#0D131F]" />
              <div className="h-[5px] w-[5px] rounded-full bg-[#0A2540]" />
            </div>
          </div>

          <div className="h-full">
            <PhoneMockupSlaytlari profiller={profiller} aktif={aktif} />
          </div>

          <div className="pointer-events-none absolute bottom-[8px] left-1/2 z-20 -translate-x-1/2">
            <div className="h-[4px] w-[104px] rounded-[10px] bg-white/30" />
          </div>
        </div>

        {isChatOpen ? (
          <div className="absolute inset-[10px] z-30 overflow-hidden rounded-[36px]">
            <LandingApkAssistant
              initialName={initialAssistantName}
              onClose={onChatClose}
            />
          </div>
        ) : null}
      </div>

      {/* Slayt gösterge noktaları — Flutter landing_hero_mockup.dart:127-145:
          telefonun DIŞINDA, 32px altında; aktif 24×8, pasif 8×8, 260ms. */}
      {!isChatOpen && (
        <div className="mt-7 flex items-center justify-center">
          {profiller.map((aday, sira) => (
            <button
              key={aday.ad}
              type="button"
              aria-label={aday.ad}
              aria-pressed={sira === aktif}
              onClick={(event) => {
                event.stopPropagation();
                setAktif(sira);
              }}
              className={`mx-1 h-2 cursor-pointer rounded-full border-0 p-0 transition-all duration-[260ms] ${
                sira === aktif ? "w-6 bg-lp-primary" : "w-2 bg-lp-border"
              }`}
            />
          ))}
        </div>
      )}
    </div>
  );
}
