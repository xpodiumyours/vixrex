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
    alt: "Sosyal medyada sizi keşfetsinler",
    renk: "bg-gradient-to-br from-[#F58529] via-[#DD2A7B] to-[#8134AF] text-white",
  },
];

const SAG_KARTLAR: CamKart[] = [
  {
    Ikon: RandevuIkonu,
    baslik: "Randevu",
    alt: "Kolay randevu oluşturun",
    renk: "bg-[#FF2D78] text-white",
  },
  {
    Ikon: BaglantiIkonu,
    baslik: "Link ve QR",
    alt: "Paylaşması kolay",
    renk: "bg-lp-primary text-white",
  },
];

function CamKartGorunumu({ kart }: { kart: CamKart }) {
  return (
    <div className="flex w-[178px] items-center gap-2.5 rounded-[20px] border border-white/[0.12] bg-white/[0.07] px-3.5 py-2.5 shadow-[0_8px_24px_rgba(0,0,0,0.35)] backdrop-blur-[12px]">
      <span
        className={`flex h-[32px] w-[32px] shrink-0 items-center justify-center rounded-full text-[17px] ${kart.renk}`}
      >
        <kart.Ikon className="h-[17px] w-[17px]" />
      </span>
      <span className="min-w-0 leading-tight">
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

function ElYazisiNot({ metin, yon }: { metin: string; yon: "sol" | "sag" }) {
  const solTaraf = yon === "sol";
  return (
    <div
      aria-hidden="true"
      className={`hidden w-[168px] md:block ${solTaraf ? "text-left" : "text-right"}`}
    >
      <p
        className={`text-[15px] font-bold italic leading-snug text-white/80 ${
          solTaraf ? "-rotate-3" : "rotate-3"
        }`}
      >
        {metin}
      </p>
      <svg
        viewBox="0 0 120 58"
        fill="none"
        className={`mt-1.5 h-[50px] w-[108px] text-white/40 ${
          solTaraf ? "" : "ml-auto -scale-x-100"
        }`}
      >
        <path
          d="M8 8 C 52 12, 88 26, 104 48"
          stroke="currentColor"
          strokeWidth="2.5"
          strokeLinecap="round"
        />
        <path
          d="M94 36 L 106 50 L 88 52"
          stroke="currentColor"
          strokeWidth="2.5"
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
  onChatClose,
}: {
  profiller: MockupProfili[];
  isChatOpen?: boolean;
  initialAssistantName?: string;
  onChatClose?: () => void;
}) {
  return (
    <div className="flex w-full justify-center md:h-lp-mockup-kutu md:w-[648px] md:shrink-0">
      <div className="relative md:w-[648px]">
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 hidden md:block"
        >
          <div
            aria-hidden="true"
            className="absolute left-1/2 top-1/2 h-[540px] w-[540px] -translate-x-1/2 -translate-y-1/2 rounded-full"
            style={{
              background:
                "radial-gradient(closest-side, color-mix(in srgb, var(--color-lp-primary) 62%, transparent), color-mix(in srgb, var(--color-lp-primary) 18%, transparent) 62%, transparent)",
            }}
          />
          <div
            aria-hidden="true"
            className="absolute left-1/2 top-1/2 h-[380px] w-[380px] -translate-x-1/2 -translate-y-1/2 rounded-full blur-[40px]"
            style={{
              background:
                "radial-gradient(closest-side, color-mix(in srgb, var(--color-lp-primary) 85%, transparent), transparent)",
            }}
          />
          <div
            aria-hidden="true"
            className="absolute left-1/2 top-1/2 h-[500px] w-[500px] -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-lp-primary/45 shadow-[0_0_60px_12px_color-mix(in_srgb,var(--color-lp-primary)_30%,transparent)]"
          />
          <div
            aria-hidden="true"
            className="absolute left-1/2 top-1/2 h-[610px] w-[610px] -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-lp-primary/25"
          />
        </div>

        <div className="absolute left-0 top-[4%] z-20 hidden flex-col items-start gap-3 md:flex">
          <CamKartGorunumu kart={SOL_KARTLAR[0]} />
          <ElYazisiNot metin="Tüm bilgileriniz tek vitrinde" yon="sol" />
          <CamKartGorunumu kart={SOL_KARTLAR[1]} />
        </div>

        <div className="absolute right-0 top-[6%] z-20 hidden flex-col items-end gap-3 md:flex">
          <CamKartGorunumu kart={SAG_KARTLAR[0]} />
          <ElYazisiNot
            metin="İşletmenizi daha fazla kişiye ulaştırın"
            yon="sag"
          />
          <CamKartGorunumu kart={SAG_KARTLAR[1]} />
        </div>

        <div
          className={`relative z-10 mx-auto w-[325px] transition-transform duration-500 motion-reduce:transition-none motion-reduce:rotate-0 ${
            isChatOpen
              ? "md:rotate-0 md:scale-[0.80]"
              : "md:rotate-[8deg] md:scale-[0.80]"
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
      </div>
    </div>
  );
}
