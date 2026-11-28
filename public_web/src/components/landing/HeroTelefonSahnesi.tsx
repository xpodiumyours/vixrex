"use client";

import {
  BaglantiIkonu,
  InstagramIkonu,
  RandevuIkonu,
  WhatsAppIkonu,
} from "./MarkaIkonlari";
import { PhoneMockup } from "./PhoneMockup";
import type { MockupProfili } from "./mockupProfilleri";

type CamKart = {
  Ikon: (props: { className?: string }) => React.ReactElement;
  baslik: string;
  alt: string;
  renk: string;
};

const SOL_KARTLAR: CamKart[] = [
  {
    Ikon: WhatsAppIkonu,
    baslik: "WhatsApp",
    alt: "Tek tıkla iletişim",
    renk: "bg-[#25D366] text-white",
  },
  {
    Ikon: InstagramIkonu,
    baslik: "Instagram",
    alt: "Sosyal medyada seni keşfetsinler",
    renk: "bg-gradient-to-br from-[#F58529] via-[#DD2A7B] to-[#8134AF] text-white",
  },
];

const SAG_KARTLAR: CamKart[] = [
  {
    Ikon: RandevuIkonu,
    baslik: "Randevu",
    alt: "Kolay randevu aldır",
    renk: "bg-[#FF2D78] text-white",
  },
  {
    Ikon: BaglantiIkonu,
    baslik: "Link ve QR",
    alt: "Paylaşması kolay",
    renk: "bg-lp-primary text-white",
  },
];

function CamKartGorunumu({
  kart,
  animasyonSinifi = "",
}: {
  kart: CamKart;
  animasyonSinifi?: string;
}) {
  return (
    <div
      className={`${animasyonSinifi} flex w-full max-w-[180px] items-center gap-2.5 rounded-[18px] border border-white/[0.16] bg-[#09152E]/88 px-3 py-2.5 shadow-[0_14px_32px_rgba(0,0,0,0.45)] backdrop-blur-xl`}
    >
      <span
        className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full shadow-md ${kart.renk}`}
      >
        <kart.Ikon className="h-[17px] w-[17px]" />
      </span>
      <span className="min-w-0 leading-tight">
        <span className="block truncate text-[11.5px] font-extrabold text-white">
          {kart.baslik}
        </span>
        <span className="block truncate text-[10px] font-semibold text-slate-300">
          {kart.alt}
        </span>
      </span>
    </div>
  );
}

function ElYazisiNot({ metin, yon }: { metin: string; yon: "sol" | "sag" }) {
  const solTaraf = yon === "sol";
  return (
    <div
      aria-hidden="true"
      className={`hidden w-full max-w-[168px] xl:block ${solTaraf ? "text-left" : "text-right"}`}
    >
      <p
        className={`text-[12.5px] font-bold italic leading-snug text-sky-200/85 ${
          solTaraf ? "-rotate-3" : "rotate-3"
        }`}
      >
        {metin}
      </p>
      <svg
        viewBox="0 0 120 44"
        fill="none"
        className={`mt-1 h-[34px] w-[82px] text-sky-300/55 ${
          solTaraf ? "" : "ml-auto -scale-x-100"
        }`}
      >
        <path
          d="M8 8 C 48 12, 82 22, 100 36"
          stroke="currentColor"
          strokeWidth="2.4"
          strokeLinecap="round"
        />
        <path
          d="M90 27 L 102 38 L 86 40"
          stroke="currentColor"
          strokeWidth="2.4"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
}

export function HeroTelefonSahnesi({
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
  const tumKartlar = [...SOL_KARTLAR, ...SAG_KARTLAR];

  return (
    <div className="relative flex min-w-0 w-full flex-col items-center">
      <div className="relative grid w-full grid-cols-1 items-center justify-items-center gap-3 py-4 xl:grid-cols-[minmax(118px,1fr)_auto_minmax(118px,1fr)] xl:gap-4">
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 flex items-center justify-center overflow-visible"
        >
          <div className="lp-aurora absolute left-1/2 top-1/2 h-[340px] w-[340px] rounded-full opacity-80 sm:h-[400px] sm:w-[400px]" />
          <div className="absolute left-1/2 top-1/2 h-[270px] w-[270px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#147DFF]/35 blur-[46px]" />
          <div className="lp-rim-ring absolute left-1/2 top-1/2 h-[390px] w-[390px] rounded-full opacity-75 sm:h-[450px] sm:w-[450px]" />
          <div className="lp-ring-pulse absolute left-1/2 top-1/2 hidden h-[480px] w-[480px] rounded-full border border-sky-400/20 shadow-[0_0_80px_10px_rgba(20,125,255,0.18)] sm:block" />
        </div>

        <div
          className={`z-20 hidden min-w-0 w-full flex-col items-end justify-center gap-3.5 transition-opacity duration-500 xl:flex xl:gap-5 ${
            isChatOpen ? "opacity-40" : "opacity-100"
          }`}
        >
          <CamKartGorunumu kart={SOL_KARTLAR[0]} animasyonSinifi="lp-float-a" />
          <ElYazisiNot metin="Tüm bilgilerin tek vitrinde" yon="sol" />
          <CamKartGorunumu kart={SOL_KARTLAR[1]} animasyonSinifi="lp-float-b" />
        </div>

        <div className="relative z-30 flex min-w-0 flex-col items-center">
          <PhoneMockup
            profiller={profiller}
            isChatOpen={isChatOpen}
            initialAssistantName={initialAssistantName}
            onOpenChat={onOpenChat}
            onChatClose={onChatClose}
          />
        </div>

        <div
          className={`z-20 hidden min-w-0 w-full flex-col items-start justify-center gap-3.5 transition-opacity duration-500 xl:flex xl:gap-5 ${
            isChatOpen ? "opacity-40" : "opacity-100"
          }`}
        >
          <CamKartGorunumu kart={SAG_KARTLAR[0]} animasyonSinifi="lp-float-b" />
          <ElYazisiNot
            metin="İşletmeni daha fazla kişiye ulaştır"
            yon="sag"
          />
          <CamKartGorunumu kart={SAG_KARTLAR[1]} animasyonSinifi="lp-float-a" />
        </div>
      </div>

      <div className="z-20 mt-4 grid w-full max-w-[340px] grid-cols-2 gap-2.5 xl:hidden">
        {tumKartlar.map((kart) => (
          <div
            key={kart.baslik}
            className="flex items-center gap-2 rounded-2xl border border-white/15 bg-[#09152E]/85 px-3 py-2 backdrop-blur-md"
          >
            <span
              className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full ${kart.renk}`}
            >
              <kart.Ikon className="h-[15px] w-[15px]" />
            </span>
            <span className="min-w-0 leading-tight">
              <span className="block truncate text-[11px] font-extrabold text-white">
                {kart.baslik}
              </span>
              <span className="block truncate text-[9.5px] text-slate-300">
                {kart.alt}
              </span>
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
