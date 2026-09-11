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
  onChatClose,
}: {
  profiller: MockupProfili[];
  isChatOpen?: boolean;
  initialAssistantName?: string;
  onChatClose?: () => void;
}) {
  const [aktif, setAktif] = useState(0);

  useEffect(() => {
    if (profiller.length < 2) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const zamanlayici = window.setInterval(() => {
      setAktif((mevcut) => (mevcut + 1) % profiller.length);
    }, 4000);
    return () => window.clearInterval(zamanlayici);
  }, [profiller.length]);

  const profil = profiller[aktif] ?? profiller[0];
  if (!profil) return null;

  return (
    <div className="relative mx-auto w-[325px] shrink-0">
      {!isChatOpen && (
        <>
          {/*
            Yüzen rozetler — Flutter _buildFloatingBadge ölçüleri
            (landing_hero_mockup.dart:152-198): rounded 20, zemin surface %92,
            kenarlık primary %28 1.2px, blur 12, gölge siyah %10 (0,5),
            padding 12×9, simge dairesi 27px (%20 alfa), metin w800 12px.
            Konum: sağ -40/üst 100, sol -30/alt 120; dar kapsayıcıda -14/-12
            (isNarrow). Salınım ±10 bilinçli sapma — web'de sabit.
            Not: web'de simge emoji (kendini renklendirir); Flutter'daki gibi
            monokrom ikon rengi uygulanmaz, daire zemini %20 alfa ile eşleşir.
          */}
          <div className="absolute -right-[14px] top-[100px] z-20 flex items-center gap-2 rounded-[20px] border-[1.2px] border-lp-primary/30 bg-lp-surface/[0.92] px-3 py-[9px] shadow-[0_5px_10px_rgba(0,0,0,0.1)] backdrop-blur-[12px] min-[408px]:-right-[40px]">
            <div
              className="flex h-[27px] w-[27px] items-center justify-center rounded-full"
              style={{ backgroundColor: `${profil.uStRozet.renk}33` }}
            >
              <span className="text-[15px]">{profil.uStRozet.simge}</span>
            </div>
            <span className="text-[12px] font-extrabold text-lp-text">
              {profil.uStRozet.metin}
            </span>
          </div>
          <div className="absolute -left-[12px] bottom-[120px] z-20 flex items-center gap-2 rounded-[20px] border-[1.2px] border-lp-primary/30 bg-lp-surface/[0.92] px-3 py-[9px] shadow-[0_5px_10px_rgba(0,0,0,0.1)] backdrop-blur-[12px] min-[408px]:-left-[30px]">
            <div
              className="flex h-[27px] w-[27px] items-center justify-center rounded-full"
              style={{ backgroundColor: `${profil.altRozet.renk}33` }}
            >
              <span className="text-[15px]">{profil.altRozet.simge}</span>
            </div>
            <span className="text-[12px] font-extrabold text-lp-text">
              {profil.altRozet.metin}
            </span>
          </div>
        </>
      )}

      <div className="relative">
        <div
          className="relative overflow-hidden rounded-[40px] border-[2.5px] border-white/[0.18] bg-[#0A101C] p-[8px]"
          style={{
            boxShadow: [
              "0 0 0 1.5px rgba(14, 165, 233, 0.3)",
              "0 25px 50px rgba(0, 0, 0, 0.55)",
              "0 16px 36px rgba(14, 165, 233, 0.22)",
            ].join(", "),
          }}
        >
          <div className="h-lp-mockup overflow-hidden rounded-[34px] border border-[#25415F] bg-[#050B1A]">
            <div className="absolute left-1/2 top-[10px] z-10 -translate-x-1/2">
              <div className="flex h-[22px] w-[96px] items-center justify-between rounded-[20px] bg-black px-[10px] shadow-[0_2px_8px_rgba(0,0,0,0.55)]">
                <div className="h-[10px] w-[10px] rounded-full border border-white/10 bg-[#0D131F]" />
                <div className="h-[6px] w-[6px] rounded-full bg-[#0A2540]" />
              </div>
            </div>

            <div className="h-full">
              <PhoneMockupSlaytlari profiller={profiller} aktif={aktif} />
            </div>

            <div className="absolute bottom-[8px] left-1/2 z-10 -translate-x-1/2">
              <div className="h-[4px] w-[110px] rounded-[10px] bg-white/30" />
            </div>
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
        <div className="mt-8 flex items-center justify-center">
          {profiller.map((aday, sira) => (
            <span
              key={aday.ad}
              aria-hidden
              className={`mx-1 h-2 rounded-full transition-all duration-[260ms] ${
                sira === aktif ? "w-6 bg-lp-primary" : "w-2 bg-lp-border"
              }`}
            />
          ))}
        </div>
      )}
    </div>
  );
}
