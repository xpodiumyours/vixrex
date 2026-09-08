"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import type { MockupProfili } from "./mockupProfilleri";
import { PhoneMockupSlaytlari } from "./PhoneMockupSlaytlari";
import { LandingApkAssistant } from "./LandingApkAssistant";
import { MaterialRoundIcon } from "./MaterialRoundIcon";

/**
 * Flutter `landing_hero_mockup.dart` + `phone_mockup.dart` karşılığı.
 * Flutter tarafı değiştirilmez; ölçü ve davranış buraya taşınır.
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

  const telefon = (
    <div
      className="relative h-[640px] w-[325px] overflow-hidden rounded-[40px] border-[2.5px] border-white/[0.18] bg-[#0A101C] p-2"
      style={{
        boxShadow: [
          "0 0 0 1.5px rgba(14, 165, 233, 0.3)",
          "0 25px 50px rgba(0, 0, 0, 0.55)",
          "0 16px 36px rgba(14, 165, 233, 0.35)",
        ].join(", "),
      }}
    >
      <div className="relative h-full w-full overflow-hidden rounded-[34px] border border-lp-border bg-lp-bg-editor">
        <div className="absolute left-1/2 top-[10px] z-30 -translate-x-1/2">
          <div className="flex h-[22px] w-[96px] items-center justify-between rounded-[20px] bg-black px-[10px] shadow-[0_2px_8px_rgba(0,0,0,0.55)]">
            <span className="h-[10px] w-[10px] rounded-full border border-white/10 bg-[#0D131F]" />
            <span className="h-[6px] w-[6px] rounded-full bg-[#0A2540]" />
          </div>
        </div>

        <div className="h-full">
          {isChatOpen ? (
            <LandingApkAssistant
              initialName={initialAssistantName}
              onClose={onChatClose}
            />
          ) : (
            <div
              key={profil.ad}
              className="h-full motion-safe:animate-[landing-phone-slide_520ms_cubic-bezier(0.22,1,0.36,1)_both]"
            >
              <PhoneMockupSlaytlari profiller={profiller} aktif={aktif} />
            </div>
          )}
        </div>

        <div className="absolute bottom-2 left-1/2 z-30 -translate-x-1/2">
          <div className="h-1 w-[110px] rounded-[10px] bg-white/30" />
        </div>
      </div>
    </div>
  );

  return (
    <div className="relative mx-auto w-[320px] shrink-0">
      <div className="relative h-[640px] w-[320px]">
        {!isChatOpen ? (
          <>
            <div className="landing-floating-badge-right absolute -right-[14px] top-[100px] z-40 flex items-center gap-2 rounded-[20px] border-[1.2px] border-lp-primary/30 bg-lp-surface/[0.92] px-3 py-[9px] shadow-[0_5px_10px_rgba(0,0,0,0.1)] backdrop-blur-[12px] min-[360px]:-right-[40px]">
              <span
                className="flex h-[27px] w-[27px] items-center justify-center rounded-full"
                style={{
                  color: profil.uStRozet.renk,
                  backgroundColor: `${profil.uStRozet.renk}33`,
                }}
              >
                <MaterialRoundIcon name={profil.uStRozet.simge} size={15} />
              </span>
              <span className="text-[12px] font-extrabold text-lp-text">
                {profil.uStRozet.metin}
              </span>
            </div>

            <div className="landing-floating-badge-left absolute -left-[12px] bottom-[120px] z-40 flex items-center gap-2 rounded-[20px] border-[1.2px] border-lp-primary/30 bg-lp-surface/[0.92] px-3 py-[9px] shadow-[0_5px_10px_rgba(0,0,0,0.1)] backdrop-blur-[12px] min-[360px]:-left-[30px]">
              <span
                className="flex h-[27px] w-[27px] items-center justify-center rounded-full"
                style={{
                  color: profil.altRozet.renk,
                  backgroundColor: `${profil.altRozet.renk}33`,
                }}
              >
                <MaterialRoundIcon name={profil.altRozet.simge} size={15} />
              </span>
              <span className="text-[12px] font-extrabold text-lp-text">
                {profil.altRozet.metin}
              </span>
            </div>
          </>
        ) : null}

        <div className="absolute left-1/2 top-1/2 h-[640px] w-[325px] -translate-x-1/2 -translate-y-1/2 scale-[0.9142857]">
          {isChatOpen ? (
            telefon
          ) : (
            <Link
              href={profil.hedefUrl}
              aria-label={`${profil.ad} demo vitrinini aç`}
              className="block h-full w-full rounded-[40px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary focus-visible:ring-offset-4 focus-visible:ring-offset-lp-bg-editor"
            >
              {telefon}
            </Link>
          )}
        </div>
      </div>

      {!isChatOpen ? (
        <div className="mt-8 flex items-center justify-center">
          {profiller.map((aday, sira) => (
            <span
              key={aday.ad}
              aria-hidden="true"
              className={`mx-1 h-2 rounded-full transition-all duration-[260ms] ${
                sira === aktif ? "w-6 bg-lp-primary" : "w-2 bg-lp-border"
              }`}
            />
          ))}
        </div>
      ) : null}
    </div>
  );
}
