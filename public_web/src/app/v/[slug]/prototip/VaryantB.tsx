"use client";

import { useState } from "react";
import {
  PROTIP_VARYANTLAR,
  PrototipGorsel,
  stokRengi,
  whatsappSiparisUrl,
  type PrototipKart,
} from "./prototipOrtak";

export default function VaryantB({
  kartlar,
  storeName,
  whatsappBaseUrl,
}: {
  kartlar: PrototipKart[];
  storeName: string;
  whatsappBaseUrl: string | null;
}) {
  const [adetler, setAdetler] = useState<Record<string, number>>({});
  const [acik, setAcik] = useState<string | null>(null);

  const adet = (anahtar: string) => adetler[anahtar] ?? 0;
  const yaz = (anahtar: string, deger: number) =>
    setAdetler((onceki) => ({ ...onceki, [anahtar]: Math.max(0, deger) }));

  return (
    <section>
      <p className="mb-3 text-[10px] font-extrabold uppercase tracking-[0.18em] text-blue-300">
        {PROTIP_VARYANTLAR[1].ad} · satır listesi + satır içi detay
      </p>

      <div className="flex flex-col gap-2">
        {kartlar.map((kart) => {
          const stok = stokRengi(kart.stokTuru);
          const mevcutAdet = adet(kart.anahtar);
          const genis = acik === kart.anahtar;
          return (
            <article
              key={kart.anahtar}
              className={`overflow-hidden rounded-2xl border bg-[#0E1B2E] transition ${
                genis ? "border-blue-500/40" : "border-white/10"
              }`}
            >
              <div className="flex items-center gap-3 p-3">
                <button
                  type="button"
                  onClick={() => setAcik(genis ? null : kart.anahtar)}
                  className="relative h-16 w-16 shrink-0 overflow-hidden rounded-xl bg-slate-950"
                >
                  <PrototipGorsel src={kart.gorsel} alt={kart.ad} />
                </button>

                <button
                  type="button"
                  onClick={() => setAcik(genis ? null : kart.anahtar)}
                  className="min-w-0 flex-1 text-left"
                >
                  <div className="flex items-center gap-1.5">
                    {kart.marka ? (
                      <span className="truncate text-[9px] font-extrabold uppercase tracking-[0.12em] text-slate-500">
                        {kart.marka}
                      </span>
                    ) : null}
                    {kart.varyantEtiketi ? (
                      <span className="shrink-0 rounded-md border border-white/10 px-1 py-0.5 text-[8px] font-bold text-slate-400">
                        {kart.varyantEtiketi}
                      </span>
                    ) : null}
                  </div>
                  <p className="mt-0.5 truncate text-sm font-extrabold text-white">{kart.ad}</p>
                  <div className="mt-1 flex items-center gap-2">
                    <p className="text-sm font-black text-blue-400">{kart.fiyat}</p>
                    {kart.eskiFiyat ? (
                      <span className="text-[10px] text-slate-500 line-through">{kart.eskiFiyat}</span>
                    ) : null}
                    {stok && kart.stokMetni ? (
                      <span className={`flex min-w-0 items-center gap-1 text-[9px] font-bold ${stok.metin}`}>
                        <span className={`h-1 w-1 shrink-0 rounded-full ${stok.nokta}`} />
                        <span className="truncate">{kart.stokMetni}</span>
                      </span>
                    ) : null}
                  </div>
                </button>

                <div className="flex shrink-0 flex-col items-center gap-1">
                  {mevcutAdet === 0 ? (
                    <button
                      type="button"
                      onClick={() => yaz(kart.anahtar, 1)}
                      aria-label={`${kart.ad} sepete ekle`}
                      className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-600 text-xl font-black text-white"
                    >
                      +
                    </button>
                  ) : (
                    <div className="flex items-center gap-1 rounded-full border border-blue-500/40 bg-blue-500/10 px-1">
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
                  <button
                    type="button"
                    onClick={() => setAcik(genis ? null : kart.anahtar)}
                    className="text-[9px] font-extrabold text-blue-400"
                  >
                    {genis ? "Kapat" : "Detay"}
                  </button>
                </div>
              </div>

              {genis ? (
                <div className="border-t border-white/10 bg-slate-950/40 p-4">
                  {kart.ozellikler ? (
                    <div className="flex flex-wrap gap-1.5">
                      {kart.ozellikler
                        .split(" · ")
                        .filter(Boolean)
                        .map((ozellik) => (
                          <span
                            key={ozellik}
                            className="rounded-md border border-white/10 bg-white/[0.04] px-2 py-1 text-[10px] font-bold text-slate-300"
                          >
                            {ozellik}
                          </span>
                        ))}
                    </div>
                  ) : null}
                  {kart.aciklama ? (
                    <p className="mt-3 text-xs font-medium leading-6 text-slate-300">{kart.aciklama}</p>
                  ) : null}
                  {whatsappSiparisUrl(whatsappBaseUrl, storeName, kart, mevcutAdet || 1) ? (
                    <a
                      href={whatsappSiparisUrl(whatsappBaseUrl, storeName, kart, mevcutAdet || 1) || "#"}
                      className="mt-3 inline-flex rounded-xl bg-emerald-600 px-5 py-2.5 text-xs font-extrabold text-white"
                    >
                      WhatsApp&apos;tan sipariş ver
                    </a>
                  ) : null}
                  <a
                    href={kart.urunUrl}
                    className="mt-3 ml-2 inline-flex rounded-xl border border-white/15 px-5 py-2.5 text-xs font-extrabold text-white/70"
                  >
                    Tam sayfa →
                  </a>
                </div>
              ) : null}
            </article>
          );
        })}
      </div>
    </section>
  );
}
