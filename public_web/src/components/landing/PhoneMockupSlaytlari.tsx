"use client";

import type { MockupProfili } from "./mockupProfilleri";

/**
 * Mockup slayt içeriği — envanter §2.3, Flutter phone_mockup.dart iç yapısı.
 *
 * Slayt SIRASI PhoneMockup'ta tutulur (2026-09-08 canlı karşılaştırma
 * düzeltmesi): yüzen rozetler aktif slaydı izlediği için state iki
 * bileşenin ortak atasında yaşar. Burada yalnız çizim var.
 *
 * Flutter ölçüleri (phone_mockup.dart:63-67): çentik için 22px üst boşluk,
 * ardından 156px kapak. Next'te kapak 196px idi ve boşluk yoktu — telefon
 * içeriği Flutter'dan uzundu, alttaki "Vitrin hazır" kartı taşiyordu.
 */
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
    <div className="flex h-full flex-col">
      {/* Kapak + isim/kategori (Flutter: 22px çentik boşluğu + 156px kapak) */}
      <div className="relative mt-[22px] h-[156px] w-full shrink-0 bg-lp-surface">
        {profil.kapakUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={profil.kapakUrl}
            alt=""
            className="h-full w-full object-cover"
            loading="eager"
          />
        ) : (
          <div className="h-full w-full bg-gradient-to-br from-lp-surface to-lp-turquoise-surface" />
        )}
        {/* Üst rozet — etiket Flutter landing_screen.dart rozet metinlerinden,
            mockupProfilleri'nde tek kaynak olarak tutulur */}
        <div className="absolute right-2 top-2 flex items-center gap-1 rounded-full bg-lp-bg-editor/90 px-2 py-1">
          <span className="text-[10px]">{profil.uStRozet.simge}</span>
          <span className="text-[9px] font-extrabold text-white">
            {profil.uStRozet.metin}
          </span>
        </div>
        <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-lp-bg-editor to-transparent p-3">
          <p className="text-[10px] font-extrabold tracking-[1.5px] text-lp-secondary">
            {profil.kategoriSeridi}
          </p>
          <p className="text-[16px] font-black text-white">{profil.ad}</p>
        </div>
      </div>

      {/* Hakkında bölümü */}
      <div className="px-3 pt-4">
        <p className="text-[12px] font-black text-white">Hakkında</p>
        <p className="mt-1 text-[11px] leading-snug text-white/60">{profil.aciklama}</p>
      </div>

      {/* Eylem simgeleri */}
      <div className="flex gap-2 px-3 pt-3">
        {profil.eylemler.map((eylem, i) => (
          <div
            key={i}
            className="flex h-7 w-7 items-center justify-center rounded-full"
            style={{ backgroundColor: eylem.renk }}
          >
            <span className="text-[11px]">{eylem.simge}</span>
          </div>
        ))}
      </div>

      {/* Eylem satırları */}
      <div className="flex flex-col gap-2 px-3 pt-3">
        {profil.eylemSatirlari.map((satir, i) => (
          <div
            key={i}
            className="flex items-center gap-2 rounded-xl border border-white/[0.08] bg-white/[0.04] px-2.5 py-2.5"
          >
            <div
              className="flex h-6 w-6 items-center justify-center rounded-lg"
              style={{ backgroundColor: satir.renk }}
            >
              <span className="text-[10px]">{i === 0 ? profil.uStRozet.simge : profil.altRozet.simge}</span>
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-[11px] font-bold text-white">{satir.baslik}</p>
              <p className="text-[10px] text-white/50">{satir.altBaslik}</p>
            </div>
            <span className="text-[10px] text-white/40">›</span>
          </div>
        ))}
      </div>

      {/* Vitrin galerisi + fotoğraf şeridi */}
      <div className="px-3 pt-3">
        <div className="flex items-center justify-between">
          <p className="text-[11px] font-black text-white">Vitrin galerisi</p>
          <span className="rounded-full bg-lp-primary/20 px-2 py-0.5 text-[9px] font-bold text-lp-primary">
            {profil.galeriUrlleri.length} fotoğraf
          </span>
        </div>
        <div className="mt-1.5 flex gap-1.5">
          {profil.galeriUrlleri.length > 0 ? (
            profil.galeriUrlleri.map((url) => (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                key={url}
                src={url}
                alt=""
                className="h-[72px] flex-1 rounded-lg object-cover"
                loading="lazy"
              />
            ))
          ) : (
            <div className="h-[72px] flex-1 rounded-lg bg-lp-surface" />
          )}
        </div>
      </div>

      {/* Vitrin hazır — Flutter phone_mockup.dart:520-580: bgLight zemin,
          lp-border kenarlık, radius 14, 12×8 padding; sağda 32×32, %14 alfa
          accent zeminde QR ikonu. "N bağlantı" sayısı profil verisinden
          gelir (Flutter: profile.links.length) — sabit "2" değil. */}
      <div className="mx-3 mt-auto flex items-center justify-between rounded-[14px] border border-lp-border bg-lp-bg-light px-3 py-2">
        <div>
          <p className="text-[12px] font-black text-lp-text">Vitrin hazır</p>
          <p className="mt-0.5 text-[11px] font-semibold text-lp-muted">
            {profil.eylemSatirlari.length} bağlantı
          </p>
        </div>
        <span
          className="flex h-8 w-8 items-center justify-center rounded-[10px] text-[16px]"
          style={{ backgroundColor: `${profil.uStRozet.renk}24` }}
        >
          🔳
        </span>
      </div>

    </div>
  );
}
