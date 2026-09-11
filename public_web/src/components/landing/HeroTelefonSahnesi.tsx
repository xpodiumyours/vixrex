"use client";

import { PhoneMockup } from "./PhoneMockup";
import type { MockupProfili } from "./mockupProfilleri";

type CamKart = {
  simge: string;
  baslik: string;
  alt: string;
};

const SOL_KARTLAR: CamKart[] = [
  { simge: "💬", baslik: "WhatsApp", alt: "ile kolay ulaşım" },
  { simge: "📅", baslik: "Randevu", alt: "Randevuları topla" },
  { simge: "🌐", baslik: "Tek Link", alt: "Her yerde paylaş" },
];

const SAG_KARTLAR: CamKart[] = [
  { simge: "📷", baslik: "Sosyal Medya", alt: "Profilleri ekle" },
  { simge: "📍", baslik: "Google İşletme", alt: "Daha fazla müşteri" },
  { simge: "🔳", baslik: "QR Kod", alt: "Dükkanda kullan" },
];

function CamKartGorunumu({ kart }: { kart: CamKart }) {
  return (
    <div className="flex items-center gap-2.5 rounded-[20px] border border-white/[0.12] bg-white/[0.07] px-3.5 py-2.5 shadow-[0_8px_24px_rgba(0,0,0,0.35)] backdrop-blur-[12px]">
      <span className="flex h-[32px] w-[32px] shrink-0 items-center justify-center rounded-full bg-lp-primary/25 text-[17px]">
        {kart.simge}
      </span>
      <span className="leading-tight">
        <span className="block text-[12px] font-extrabold text-white">
          {kart.baslik}
        </span>
        <span className="block text-[11px] font-semibold text-white/60">
          {kart.alt}
        </span>
      </span>
    </div>
  );
}

export function HeroTelefonSahnesi({
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
  return (
    <div className="flex w-full justify-center md:h-lp-mockup-kutu md:w-[540px] md:shrink-0">
      <div className="relative md:w-[540px]">
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 hidden md:block"
        >
          <div
            aria-hidden="true"
            className="absolute left-1/2 top-1/2 h-[420px] w-[420px] -translate-x-1/2 -translate-y-1/2 rounded-full"
            style={{
              background:
                "radial-gradient(closest-side, color-mix(in srgb, var(--color-lp-primary) 35%, transparent), transparent)",
            }}
          />
        </div>

        <div className="absolute left-0 top-[8%] z-20 hidden w-[168px] flex-col gap-4 md:flex">
          {SOL_KARTLAR.map((kart) => (
            <CamKartGorunumu key={kart.baslik} kart={kart} />
          ))}
        </div>
        <div className="absolute right-0 top-[12%] z-20 hidden w-[168px] flex-col gap-4 md:flex">
          {SAG_KARTLAR.map((kart) => (
            <CamKartGorunumu key={kart.baslik} kart={kart} />
          ))}
        </div>

        <div
          className={`relative z-10 mx-auto w-[325px] transition-transform duration-500 motion-reduce:transition-none motion-reduce:rotate-0 ${
            isChatOpen
              ? "md:rotate-0 md:scale-[0.85]"
              : "md:rotate-[8deg] md:scale-[0.85]"
          }`}
        >
          <div className="md:origin-top">
            <PhoneMockup
              profiller={profiller}
              isChatOpen={isChatOpen}
              initialAssistantName={initialAssistantName}
              onChatClose={onChatClose}
            />
          </div>
        </div>

        {!isChatOpen && (
          <div aria-hidden="true" className="absolute -bottom-2 right-0 z-20 hidden w-[228px] md:block">
            <div className="rounded-[20px] border border-white/[0.12] bg-[#0B1426]/95 p-3.5 shadow-[0_12px_32px_rgba(0,0,0,0.5)]">
              <p className="text-[12px] font-extrabold text-white">
                Vixrex Asistan
              </p>
              <p className="mt-1 text-[12px] font-medium leading-snug text-white/70">
                Merhaba! Vitrininle ilgili sana nasıl yardımcı olabilirim?
              </p>
              <div className="mt-2.5 flex items-center gap-2 rounded-xl bg-white/[0.07] px-3 py-2.5">
                <span className="flex-1 text-[12px] font-semibold text-white/35">
                  Bir mesaj yazın...
                </span>
                <span className="flex h-7 w-7 items-center justify-center rounded-full bg-lp-primary text-[13px] text-white">
                  ➤
                </span>
              </div>
            </div>
            <p className="mt-2 -rotate-6 text-right text-[13px] font-bold italic text-white/75">
              Vixrex Asistan her zaman yanınızda 💙
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
