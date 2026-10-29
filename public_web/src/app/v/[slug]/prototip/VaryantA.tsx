"use client";

import { useState } from "react";
import {
  PROTIP_VARYANTLAR,
  PrototipGorsel,
  stokRengi,
  tutarYazisi,
  whatsappSiparisUrl,
  type PrototipKart,
} from "./prototipOrtak";

function KalpDugmesi({ begenildi, onDegisti, urunAdi }: { begenildi: boolean; onDegisti: () => void; urunAdi: string }) {
  return (
    <button
      type="button"
      onClick={(event) => {
        event.stopPropagation();
        onDegisti();
      }}
      aria-label={begenildi ? `${urunAdi} favorilerden çıkar` : `${urunAdi} favorilere ekle`}
      aria-pressed={begenildi}
      className="absolute right-1.5 top-1.5 z-10 flex h-9 w-9 items-center justify-center rounded-full border border-white/25 bg-black/45 text-white backdrop-blur-sm transition-colors hover:bg-black/65 active:scale-95"
    >
      <svg
        width="16"
        height="16"
        viewBox="0 0 24 24"
        fill={begenildi ? "#ff5252" : "none"}
        stroke={begenildi ? "#ff5252" : "currentColor"}
        strokeWidth="1.8"
        aria-hidden="true"
      >
        <path d="M12 21s-6.5-4.2-8.2-8.2A5.2 5.2 0 0 1 12 5.2a5.2 5.2 0 0 1 8.2 7.6C18.5 16.8 12 21 12 21z" />
      </svg>
    </button>
  );
}

function AdetSecici({
  adet,
  maksAdet,
  onAzalt,
  onArtir,
  kompakt = false,
}: {
  adet: number;
  maksAdet: number | null;
  onAzalt: () => void;
  onArtir: () => void;
  kompakt?: boolean;
}) {
  const sinirda = maksAdet != null && adet >= maksAdet;
  return (
    <div
      className={`flex items-center justify-between rounded-xl border border-blue-500/40 bg-blue-500/10 ${kompakt ? "px-1.5 py-1" : "px-2 py-2"}`}
    >
      <button
        type="button"
        onClick={onAzalt}
        aria-label="Adedi azalt"
        className={`flex items-center justify-center rounded-lg font-black text-white transition active:scale-90 ${kompakt ? "h-7 w-7 text-lg" : "h-9 w-9 text-xl"}`}
      >
        −
      </button>
      <span
        aria-live="polite"
        className={`font-extrabold text-white ${kompakt ? "text-xs" : "text-sm"}`}
      >
        {adet}
      </span>
      <button
        type="button"
        onClick={onArtir}
        disabled={sinirda}
        aria-label={sinirda ? "Stok sınırına ulaşıldı" : "Adedi artır"}
        title={sinirda ? `Stokta ${maksAdet} adet var` : undefined}
        className={`flex items-center justify-center rounded-lg font-black transition active:scale-90 ${
          sinirda
            ? "cursor-not-allowed text-white/25"
            : "text-white hover:bg-white/10"
        } ${kompakt ? "h-7 w-7 text-lg" : "h-9 w-9 text-xl"}`}
      >
        +
      </button>
    </div>
  );
}

function FiyatBlogu({ kart, buyuk = false }: { kart: PrototipKart; buyuk?: boolean }) {
  return (
    <div className="flex flex-wrap items-baseline gap-x-2 gap-y-1">
      <p
        className={`font-black text-white ${buyuk ? "text-2xl" : "text-base"}`}
      >
        {kart.fiyat}
      </p>
      {kart.indirimYuzdesi != null ? (
        <span className="rounded-md bg-red-500/15 px-1.5 py-0.5 text-[10px] font-black text-red-400">
          %{kart.indirimYuzdesi}
        </span>
      ) : null}
      {kart.eskiFiyat ? (
        <span className={`text-slate-500 line-through ${buyuk ? "text-sm" : "text-[10px]"}`}>
          {kart.eskiFiyat}
        </span>
      ) : null}
    </div>
  );
}

function BirimFiyatSatiri({ kart }: { kart: PrototipKart }) {
  if (!kart.miktar && !kart.birimFiyat) return null;
  return (
    <p className="mt-1 flex flex-wrap items-center gap-x-1.5 text-[11px] font-semibold text-slate-400">
      {kart.miktar ? <span>{kart.miktar}</span> : null}
      {kart.miktar && kart.birimFiyat ? <span aria-hidden="true">·</span> : null}
      {kart.birimFiyat ? <span className="text-slate-300">{kart.birimFiyat}</span> : null}
    </p>
  );
}

export default function VaryantA({
  kartlar,
  storeName,
  whatsappBaseUrl,
}: {
  kartlar: PrototipKart[];
  storeName: string;
  whatsappBaseUrl: string | null;
}) {
  const [adetler, setAdetler] = useState<Record<string, number>>({});
  const [begeniler, setBegeniler] = useState<Record<string, boolean>>({});
  const [pencere, setPencere] = useState<PrototipKart | null>(null);
  const [gorselIndex, setGorselIndex] = useState(0);

  const adet = (anahtar: string) => adetler[anahtar] ?? 0;
  const yaz = (anahtar: string, deger: number) =>
    setAdetler((onceki) => ({ ...onceki, [anahtar]: Math.max(0, deger) }));

  const pencereAc = (kart: PrototipKart) => {
    setGorselIndex(0);
    setPencere(kart);
  };

  return (
    <section className="pb-20">
      <p className="mb-3 text-[10px] font-extrabold uppercase tracking-[0.18em] text-blue-300">
        {PROTIP_VARYANTLAR[0].ad} · kartta sepete ekle
      </p>

      <div className="grid grid-cols-2 gap-3">
        {kartlar.map((kart) => {
          const stok = stokRengi(kart.stokTuru);
          const mevcutAdet = adet(kart.anahtar);
          const tukendi = kart.stokTuru === "tukendi";
          return (
            <article
              key={kart.anahtar}
              className="flex flex-col overflow-hidden rounded-2xl border border-white/10 bg-[#0E1B2E] transition active:scale-[0.98]"
            >
              <div className="relative">
                <button
                  type="button"
                  onClick={() => pencereAc(kart)}
                  className="block aspect-square w-full bg-slate-950 text-left"
                >
                  <PrototipGorsel src={kart.gorsel} alt={kart.ad} />
                </button>
                {kart.rozet ? (
                  <span className="absolute left-2 top-2 z-10 max-w-[calc(100%-3.5rem)] truncate rounded-lg bg-red-600 px-2 py-0.5 text-[9px] font-black text-white">
                    {kart.rozet}
                  </span>
                ) : null}
                <KalpDugmesi
                  begenildi={Boolean(begeniler[kart.anahtar])}
                  onDegisti={() =>
                    setBegeniler((onceki) => ({
                      ...onceki,
                      [kart.anahtar]: !onceki[kart.anahtar],
                    }))
                  }
                  urunAdi={kart.ad}
                />
                {kart.fotoSayisi > 1 ? (
                  <span className="absolute bottom-2 right-2 z-10 rounded-full bg-black/60 px-2 py-0.5 text-[10px] font-bold text-white">
                    1/{kart.fotoSayisi}
                  </span>
                ) : null}
                {tukendi ? (
                  <span className="absolute inset-x-0 bottom-0 bg-black/70 py-1.5 text-center text-[11px] font-black text-white">
                    Tükendi
                  </span>
                ) : null}
              </div>

              <div className="flex flex-1 flex-col p-3">
                {kart.marka ? (
                  <p className="truncate text-[9px] font-extrabold uppercase tracking-[0.12em] text-slate-500">
                    {kart.marka}
                  </p>
                ) : null}
                <button
                  type="button"
                  onClick={() => pencereAc(kart)}
                  className="mt-0.5 line-clamp-2 min-h-[2.4em] text-left text-xs font-extrabold leading-snug text-white"
                >
                  {kart.ad}
                </button>

                <BirimFiyatSatiri kart={kart} />

                <div className="mt-2">
                  <FiyatBlogu kart={kart} />
                </div>

                {stok && kart.stokMetni && !tukendi ? (
                  <p className={`mt-1.5 flex items-center gap-1.5 text-[10px] font-bold ${stok.metin}`}>
                    <span className={`h-1.5 w-1.5 shrink-0 rounded-full ${stok.nokta}`} />
                    <span className="truncate">{kart.stokMetni}</span>
                  </p>
                ) : null}

                <div className="mt-2.5">
                  {tukendi ? (
                    <button
                      type="button"
                      disabled
                      className="w-full cursor-not-allowed rounded-xl border border-white/10 bg-white/[0.03] py-2 text-[11px] font-extrabold text-white/35"
                    >
                      Tükendi
                    </button>
                  ) : mevcutAdet === 0 ? (
                    <button
                      type="button"
                      onClick={() => yaz(kart.anahtar, 1)}
                      className="w-full rounded-xl bg-blue-600 py-2 text-[11px] font-extrabold text-white transition hover:bg-blue-500 active:scale-[0.97]"
                    >
                      Sepete ekle
                    </button>
                  ) : (
                    <div>
                      <AdetSecici
                        adet={mevcutAdet}
                        maksAdet={kart.maksAdet}
                        onAzalt={() => yaz(kart.anahtar, mevcutAdet - 1)}
                        onArtir={() => yaz(kart.anahtar, mevcutAdet + 1)}
                        kompakt
                      />
                      <p
                        aria-live="polite"
                        className="mt-1 text-center text-[9px] font-bold text-emerald-300"
                      >
                        {mevcutAdet} adet sepette
                      </p>
                    </div>
                  )}
                </div>
              </div>
            </article>
          );
        })}
      </div>

      {pencere ? (
        <div
          className="fixed inset-0 z-[80] flex items-end justify-center bg-black/70 p-0 sm:items-center sm:p-4"
          onClick={() => setPencere(null)}
        >
          <div
            role="dialog"
            aria-label={`${pencere.ad} hızlı bakış`}
            className="max-h-[92vh] w-full max-w-md overflow-y-auto rounded-t-3xl border border-white/10 bg-[#0E1B2E] sm:rounded-3xl"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="sticky top-0 z-10 flex justify-center bg-[#0E1B2E] pt-2.5 pb-1">
              <span className="h-1 w-10 rounded-full bg-white/25" />
            </div>

            <div className="relative aspect-[4/3] w-full bg-slate-950">
              <PrototipGorsel
                src={pencere.gorseller[gorselIndex] ?? pencere.gorsel}
                alt={pencere.ad}
              />
              <button
                type="button"
                onClick={() => setPencere(null)}
                aria-label="Kapat"
                className="absolute right-3 top-3 flex h-9 w-9 items-center justify-center rounded-full bg-black/60 text-white backdrop-blur-md transition active:scale-95"
              >
                ✕
              </button>
              {pencere.fotoSayisi > 1 ? (
                <div className="absolute bottom-2.5 left-1/2 flex -translate-x-1/2 gap-1.5">
                  {pencere.gorseller.map((_, i) => (
                    <button
                      key={i}
                      type="button"
                      onClick={() => setGorselIndex(i)}
                      aria-label={`${i + 1}. görsel`}
                      className={`h-1.5 rounded-full transition-all ${
                        i === gorselIndex ? "w-5 bg-white" : "w-1.5 bg-white/40"
                      }`}
                    />
                  ))}
                </div>
              ) : null}
            </div>

            <div className="p-5">
              {pencere.marka ? (
                <p className="text-[10px] font-extrabold uppercase tracking-[0.14em] text-slate-500">
                  {pencere.marka}
                </p>
              ) : null}
              <h3 className="mt-1 text-lg font-black leading-tight text-white">{pencere.ad}</h3>

              <div className="mt-3">
                <FiyatBlogu kart={pencere} buyuk />
                <BirimFiyatSatiri kart={pencere} />
              </div>

              {pencere.stokMetni && !pencere.stokTuru ? null : pencere.stokMetni ? (
                <p
                  className={`mt-2 flex items-center gap-1.5 text-[11px] font-bold ${
                    stokRengi(pencere.stokTuru)?.metin ?? "text-slate-300"
                  }`}
                >
                  <span
                    className={`h-1.5 w-1.5 rounded-full ${
                      stokRengi(pencere.stokTuru)?.nokta ?? "bg-slate-400"
                    }`}
                  />
                  {pencere.stokMetni}
                </p>
              ) : null}

              {pencere.ozellikler ? (
                <div className="mt-3 flex flex-wrap gap-1.5">
                  {pencere.ozellikler
                    .split(" · ")
                    .filter(Boolean)
                    .map((ozellik) => (
                      <span
                        key={ozellik}
                        className="rounded-lg border border-white/10 bg-white/[0.04] px-2 py-1 text-[10px] font-bold text-slate-300"
                      >
                        {ozellik}
                      </span>
                    ))}
                </div>
              ) : null}

              {pencere.aciklama ? (
                <p className="mt-4 text-xs font-medium leading-6 text-slate-300">{pencere.aciklama}</p>
              ) : null}
            </div>

            <div className="sticky bottom-0 border-t border-white/10 bg-[#0E1B2E] p-4 pb-20">
              {pencere.stokTuru === "tukendi" ? (
                <button
                  type="button"
                  disabled
                  className="w-full cursor-not-allowed rounded-xl border border-white/10 bg-white/[0.03] py-3 text-sm font-extrabold text-white/35"
                >
                  Tükendi
                </button>
              ) : (
                <div>
                  {adet(pencere.anahtar) > 0 ? (
                    <div className="mb-2">
                      <AdetSecici
                        adet={adet(pencere.anahtar)}
                        maksAdet={pencere.maksAdet}
                        onAzalt={() => yaz(pencere.anahtar, adet(pencere.anahtar) - 1)}
                        onArtir={() => yaz(pencere.anahtar, adet(pencere.anahtar) + 1)}
                      />
                    </div>
                  ) : null}
                  <div className="flex gap-2">
                    <button
                      type="button"
                      onClick={() => yaz(pencere.anahtar, adet(pencere.anahtar) + 1)}
                      className="flex-1 rounded-xl bg-blue-600 py-3 text-sm font-extrabold text-white transition active:scale-[0.97]"
                    >
                      {adet(pencere.anahtar) > 0 && pencere.fiyatTutar != null
                        ? `Sepete ekle · ${tutarYazisi(pencere.fiyatTutar * adet(pencere.anahtar))}`
                        : "Sepete ekle"}
                    </button>
                    {whatsappSiparisUrl(
                      whatsappBaseUrl,
                      storeName,
                      pencere,
                      adet(pencere.anahtar) || 1,
                    ) ? (
                      <a
                        href={
                          whatsappSiparisUrl(
                            whatsappBaseUrl,
                            storeName,
                            pencere,
                            adet(pencere.anahtar) || 1,
                          ) || "#"
                        }
                        className="rounded-xl border border-emerald-500/40 bg-emerald-500/10 px-4 py-3 text-sm font-extrabold text-emerald-300"
                      >
                        WhatsApp
                      </a>
                    ) : null}
                  </div>
                  {adet(pencere.anahtar) > 0 ? (
                    <p aria-live="polite" className="mt-2 text-center text-[11px] font-bold text-emerald-300">
                      {adet(pencere.anahtar)} adet sepette
                    </p>
                  ) : null}
                </div>
              )}
            </div>
          </div>
        </div>
      ) : null}
    </section>
  );
}
