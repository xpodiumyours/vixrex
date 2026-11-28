"use client";

import type { MockupAksiyonHapi, MockupProfili } from "./mockupProfilleri";

function aksiyonSinifi(vurgu: MockupAksiyonHapi["vurgu"]): string {
  if (vurgu === "whatsapp") {
    return "border-emerald-400/35 bg-emerald-500/20 text-emerald-200";
  }
  if (vurgu === "birincil") {
    return "border-sky-400/35 bg-[#147DFF]/25 text-white";
  }
  return "border-white/15 bg-black/35 text-slate-100";
}

export function PhoneMockupSlaytlari({
  profiller,
  aktif,
}: {
  profiller: MockupProfili[];
  aktif: number;
}) {
  const profil = profiller[aktif] ?? profiller[0];
  if (!profil) return null;

  return (
    <div className="flex h-full w-full flex-col overflow-hidden bg-[#080F20]">
      <div className="relative overflow-hidden bg-gradient-to-b from-[#1E293B] via-[#0F172A] to-[#080F20] px-3.5 pb-3 pt-9">
        {profil.kapakUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={profil.kapakUrl}
            alt=""
            className="pointer-events-none absolute inset-0 h-full w-full object-cover opacity-40"
            loading="eager"
          />
        ) : null}
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 bg-gradient-to-b from-[#080F20]/60 via-[#080F20]/88 to-[#080F20]"
        />
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 bg-gradient-to-tr from-[#147DFF]/25 via-transparent to-sky-400/20 opacity-45"
        />

        <div className="relative z-10">
          <div className="flex flex-col items-start gap-1.5">
            <span className="inline-flex items-center gap-1.5 rounded-full border border-sky-400/35 bg-[#147DFF]/25 px-2.5 py-0.5 text-[8.5px] font-black uppercase tracking-wider text-sky-300">
              <span aria-hidden="true" className="h-1.5 w-1.5 rounded-full bg-sky-300" />
              {profil.kategoriSeridi}
            </span>
            <span className="inline-flex items-center gap-1.5 rounded-full border border-emerald-400/35 bg-emerald-500/20 px-2.5 py-0.5 text-[8.5px] font-black uppercase tracking-wider text-emerald-300">
              <span aria-hidden="true" className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
              Örnek vitrin
            </span>
          </div>

          <div className="mt-2.5 flex items-center gap-2.5">
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-white/30 bg-white text-xs font-black text-slate-900 shadow-md">
              {profil.basHarfler}
            </span>
            <div className="min-w-0">
              <p className="truncate text-[16px] font-black uppercase leading-none tracking-tight text-white">
                {profil.ad}
              </p>
              <p className="mt-1 truncate text-[9px] font-extrabold uppercase tracking-wider text-sky-400">
                {profil.kategoriSeridi} · {profil.konumSatiri}
              </p>
            </div>
          </div>

          <p className="mt-2 line-clamp-2 text-[10px] leading-[1.4] text-slate-300">
            {profil.aciklama}
          </p>

          <div className="mt-2 space-y-0.5 text-[9px] font-medium text-slate-300">
            <p className="flex items-center gap-1 truncate">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true" className="h-2.5 w-2.5 shrink-0 text-sky-400">
                <path d="M12 21s-6-5.2-6-10a6 6 0 1 1 12 0c0 4.8-6 10-6 10Z" />
                <circle cx="12" cy="11" r="2" />
              </svg>
              <span className="truncate">{profil.konumSatiri}</span>
            </p>
            <p className="flex items-center gap-1 truncate text-slate-400">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true" className="h-2.5 w-2.5 shrink-0 text-emerald-400">
                <circle cx="12" cy="12" r="9" />
                <path d="M12 7v5l3 2" />
              </svg>
              <span className="truncate">{profil.calismaSaati}</span>
            </p>
          </div>

          <div className="mt-2.5 grid grid-cols-2 gap-1.5">
            {profil.aksiyonHaplari.map((hap) => (
              <div
                key={hap.etiket}
                className={`truncate rounded-full border px-2 py-1.5 text-center text-[9.5px] font-bold backdrop-blur-sm ${aksiyonSinifi(hap.vurgu)}`}
              >
                {hap.etiket}
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="flex flex-1 flex-col overflow-hidden bg-[#070D1D] px-3.5 pb-6 pt-2.5">
        <div className="mb-2 flex shrink-0 items-center justify-between">
          <span className="text-[12px] font-black text-white">{profil.bolumBasligi}</span>
          <span className="text-[9.5px] font-bold text-sky-400">Tümünü gör →</span>
        </div>

        <div className="grid flex-1 grid-cols-2 gap-2">
          {profil.vitrinKartlari.map((kart) => (
            <div
              key={kart.baslik}
              className="relative overflow-hidden rounded-xl border border-white/15 bg-slate-900"
            >
              {kart.gorselUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={kart.gorselUrl}
                  alt=""
                  className="h-full w-full object-cover"
                  loading="eager"
                />
              ) : (
                <div className="h-full w-full bg-gradient-to-br from-[#102B59] to-[#08132D]" />
              )}
              <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-slate-950/95 via-slate-950/60 to-transparent p-2">
                <p className="truncate text-[8.5px] font-bold leading-none text-slate-300">
                  {kart.altBilgi}
                </p>
                <p className="mt-0.5 truncate text-[11px] font-black leading-tight text-white">
                  {kart.baslik}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
