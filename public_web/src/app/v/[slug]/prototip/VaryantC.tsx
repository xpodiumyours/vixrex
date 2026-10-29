"use client";

import { useState } from "react";
import {
  PROTIP_VARYANTLAR,
  PrototipGorsel,
  stokRengi,
  whatsappSiparisUrl,
  type PrototipKart,
} from "./prototipOrtak";

export default function VaryantC({
  kartlar,
  storeName,
  whatsappBaseUrl,
}: {
  kartlar: PrototipKart[];
  storeName: string;
  whatsappBaseUrl: string | null;
}) {
  const [adetler, setAdetler] = useState<Record<string, number>>({});
  const [pencere, setPencere] = useState<PrototipKart | null>(null);

  const adet = (anahtar: string) => adetler[anahtar] ?? 0;
  const yaz = (anahtar: string, deger: number) =>
    setAdetler((onceki) => ({ ...onceki, [anahtar]: Math.max(0, deger) }));

  return (
    <section>
      <p className="mb-3 text-[10px] font-extrabold uppercase tracking-[0.18em] text-blue-300">
        {PROTIP_VARYANTLAR[2].ad} · görsel öncelikli + alt panel sipariş
      </p>

      <div className="flex flex-col gap-5">
        {kartlar.map((kart) => {
          const stok = stokRengi(kart.stokTuru);
          const mevcutAdet = adet(kart.anahtar);
          return (
            <article key={kart.anahtar} className="overflow-hidden rounded-3xl border border-white/10 bg-[#0E1B2E]">
              <button
                type="button"
                onClick={() => setPencere(kart)}
                className="relative block aspect-[4/3] w-full bg-slate-950"
              >
                <PrototipGorsel src={kart.gorsel} alt={kart.ad} />
                <div className="pointer-events-none absolute inset-x-0 bottom-0 h-24 bg-gradient-to-t from-[#0B1120]/90 to-transparent" />
                {kart.rozet ? (
                  <span className="absolute left-3 top-3 rounded-lg bg-blue-600 px-2.5 py-1 text-[10px] font-extrabold text-white">
                    {kart.rozet}
                  </span>
                ) : null}
                <div className="absolute bottom-3 left-3 right-3 flex items-end justify-between gap-2 text-left">
                  <div className="min-w-0">
                    {kart.marka ? (
                      <p className="truncate text-[9px] font-extrabold uppercase tracking-[0.14em] text-slate-300">
                        {kart.marka}
                      </p>
                    ) : null}
                    <p className="line-clamp-1 text-sm font-black text-white">{kart.ad}</p>
                  </div>
                  <p className="shrink-0 rounded-lg bg-white/10 px-2.5 py-1 text-sm font-black text-white backdrop-blur-md">
                    {kart.fiyat}
                  </p>
                </div>
              </button>

              <div className="flex items-center gap-3 p-3.5">
                <div className="min-w-0 flex-1">
                  {kart.ozellikler ? (
                    <p className="truncate text-[10px] font-semibold text-slate-400">{kart.ozellikler}</p>
                  ) : null}
                  <div className="mt-1 flex items-center gap-2">
                    {kart.eskiFiyat ? (
                      <span className="text-[10px] text-slate-500 line-through">{kart.eskiFiyat}</span>
                    ) : null}
                    {stok && kart.stokMetni ? (
                      <span className={`flex min-w-0 items-center gap-1 text-[10px] font-bold ${stok.metin}`}>
                        <span className={`h-1 w-1 shrink-0 rounded-full ${stok.nokta}`} />
                        <span className="truncate">{kart.stokMetni}</span>
                      </span>
                    ) : null}
                  </div>
                </div>

                {mevcutAdet === 0 ? (
                  <button
                    type="button"
                    onClick={() => yaz(kart.anahtar, 1)}
                    className="shrink-0 rounded-full bg-blue-600 px-5 py-2.5 text-xs font-extrabold text-white"
                  >
                    Sepete ekle
                  </button>
                ) : (
                  <div className="flex shrink-0 items-center gap-1 rounded-full border border-blue-500/40 bg-blue-500/10 px-1.5">
                    <button
                      type="button"
                      onClick={() => yaz(kart.anahtar, mevcutAdet - 1)}
                      aria-label="Azalt"
                      className="flex h-8 w-8 items-center justify-center rounded-full text-lg font-black text-white"
                    >
                      −
                    </button>
                    <span className="min-w-[1.1rem] text-center text-xs font-extrabold text-white">
                      {mevcutAdet}
                    </span>
                    <button
                      type="button"
                      onClick={() => yaz(kart.anahtar, mevcutAdet + 1)}
                      aria-label="Artır"
                      className="flex h-8 w-8 items-center justify-center rounded-full text-lg font-black text-white"
                    >
                      +
                    </button>
                  </div>
                )}
              </div>
            </article>
          );
        })}
      </div>

      {pencere ? (
        <div
          className="fixed inset-0 z-[80] flex items-end justify-center bg-black/70"
          onClick={() => setPencere(null)}
        >
          <div
            className="max-h-[85vh] w-full overflow-y-auto rounded-t-3xl border-t border-white/10 bg-[#0E1B2E]"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="sticky top-0 z-10 flex items-center justify-between border-b border-white/10 bg-[#0E1B2E]/95 px-5 py-3.5 backdrop-blur-md">
              <p className="min-w-0 truncate text-sm font-black text-white">{pencere.ad}</p>
              <button
                type="button"
                onClick={() => setPencere(null)}
                aria-label="Kapat"
                className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-white/10 text-white"
              >
                ✕
              </button>
            </div>

            <div className="flex gap-4 p-5">
              <div className="relative h-28 w-28 shrink-0 overflow-hidden rounded-2xl bg-slate-950">
                <PrototipGorsel src={pencere.gorsel} alt={pencere.ad} />
              </div>
              <div className="min-w-0 flex-1">
                {pencere.marka ? (
                  <p className="text-[10px] font-extrabold uppercase tracking-[0.14em] text-slate-500">
                    {pencere.marka}
                  </p>
                ) : null}
                <div className="mt-1.5 flex items-baseline gap-2">
                  <p className="text-2xl font-black text-white">{pencere.fiyat}</p>
                  {pencere.eskiFiyat ? (
                    <span className="text-xs text-slate-500 line-through">{pencere.eskiFiyat}</span>
                  ) : null}
                </div>
                {pencere.ozellikler ? (
                  <p className="mt-2 text-[11px] font-semibold text-slate-400">{pencere.ozellikler}</p>
                ) : null}
                {pencere.aciklama ? (
                  <p className="mt-2 line-clamp-4 text-xs font-medium leading-6 text-slate-300">
                    {pencere.aciklama}
                  </p>
                ) : null}
              </div>
            </div>

            <div className="border-t border-white/10 p-5 pt-4">
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-2 rounded-2xl border border-white/15 px-2 py-1.5">
                  <button
                    type="button"
                    onClick={() => yaz(pencere.anahtar, adet(pencere.anahtar) - 1)}
                    aria-label="Azalt"
                    className="flex h-9 w-9 items-center justify-center rounded-xl text-xl font-black text-white"
                  >
                    −
                  </button>
                  <span className="min-w-[1.6rem] text-center text-base font-black text-white">
                    {adet(pencere.anahtar) || 1}
                  </span>
                  <button
                    type="button"
                    onClick={() => yaz(pencere.anahtar, (adet(pencere.anahtar) || 1) + 1)}
                    aria-label="Artır"
                    className="flex h-9 w-9 items-center justify-center rounded-xl text-xl font-black text-white"
                  >
                    +
                  </button>
                </div>
                <button
                  type="button"
                  onClick={() => yaz(pencere.anahtar, adet(pencere.anahtar) || 1)}
                  className="flex-1 rounded-2xl bg-blue-600 py-3.5 text-sm font-extrabold text-white"
                >
                  Sepete ekle · {pencere.fiyat}
                </button>
              </div>
              {whatsappSiparisUrl(whatsappBaseUrl, storeName, pencere, adet(pencere.anahtar) || 1) ? (
                <a
                  href={whatsappSiparisUrl(whatsappBaseUrl, storeName, pencere, adet(pencere.anahtar) || 1) || "#"}
                  className="mt-2.5 flex w-full items-center justify-center rounded-2xl border border-emerald-500/40 bg-emerald-500/10 py-3.5 text-sm font-extrabold text-emerald-300"
                >
                  WhatsApp&apos;tan sipariş ver
                </a>
              ) : null}
            </div>
          </div>
        </div>
      ) : null}
    </section>
  );
}
