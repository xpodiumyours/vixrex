"use client";

import Image from "next/image";
import type { MockupProfili } from "./mockupProfilleri";
import { MaterialRoundIcon } from "./MaterialRoundIcon";

/** Flutter `lib/widgets/landing/phone_mockup.dart` iç yapısının web karşılığı. */
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
    <div className="flex h-full flex-col bg-lp-surface">
      <div className="h-[22px] shrink-0 bg-lp-bg-editor" aria-hidden="true" />

      <div className="relative h-[156px] w-full shrink-0 overflow-hidden bg-lp-bg-light">
        {profil.kapakUrl ? (
          <Image
            src={profil.kapakUrl}
            alt=""
            fill
            sizes="309px"
            className="object-cover"
            priority
          />
        ) : (
          <div className="absolute inset-0 bg-lp-bg-light" />
        )}
        <div className="absolute inset-0 bg-gradient-to-b from-black/15 to-black/50" />

        <div className="absolute inset-0 flex flex-col px-[14px] pb-[14px] pt-3">
          <div className="flex items-start">
            <span
              className="flex h-10 w-10 items-center justify-center rounded-2xl border"
              style={{
                color: profil.vurguRengi,
                backgroundColor: `${profil.vurguRengi}29`,
                borderColor: `${profil.vurguRengi}4D`,
              }}
            >
              <MaterialRoundIcon name={profil.anaSimge} size={22} />
            </span>
            <span className="flex-1" />
            <span className="flex items-center rounded-full border border-white/15 bg-black/30 px-3 py-2">
              <MaterialRoundIcon
                name={profil.uStRozet.simge}
                size={14}
                className="shrink-0"
              />
              <span className="ml-1.5 text-[12px] font-extrabold text-white">
                {profil.uStRozet.metin}
              </span>
            </span>
          </div>

          <div className="mt-1.5 truncate text-[24px] font-black leading-none tracking-[-0.8px] text-white">
            {profil.ad}
          </div>
          <div className="mt-1.5 flex min-w-0 items-center">
            <span
              className="min-w-0 truncate text-[12px] font-extrabold"
              style={{ color: profil.vurguRengi }}
            >
              {profil.kategoriSeridi}
            </span>
            <span
              className="mx-2.5 h-1.5 w-1.5 shrink-0 rounded-full"
              style={{ backgroundColor: profil.altRozet.renk }}
              aria-hidden="true"
            />
            <span className="min-w-0 truncate text-[11px] font-semibold text-white/70">
              {profil.altRozet.metin}
            </span>
          </div>
        </div>
      </div>

      <div className="flex min-h-0 flex-1 flex-col bg-lp-surface p-[14px]">
        <p className="text-[13px] font-black text-lp-text">Hakkında</p>
        <p className="mt-1.5 line-clamp-2 text-[12px] leading-[1.5] text-lp-text-alt">
          {profil.aciklama}
        </p>

        <div className="mt-1.5 flex flex-wrap gap-2">
          {profil.eylemler.map((eylem, index) => (
            <span
              key={`${eylem.simge}-${index}`}
              className="flex items-center rounded-xl p-2"
              style={{
                color: eylem.renk,
                backgroundColor: `${eylem.renk}1A`,
              }}
            >
              <MaterialRoundIcon name={eylem.simge} size={16} />
            </span>
          ))}
        </div>

        <div className="mt-1.5 space-y-1.5">
          {profil.eylemSatirlari.slice(0, 2).map((satir) => (
            <div
              key={satir.baslik}
              className="flex w-full items-center rounded-[14px] border border-lp-border bg-lp-bg-light px-2.5 py-1.5"
            >
              <span
                className="flex h-[30px] w-[30px] shrink-0 items-center justify-center rounded-[10px]"
                style={{
                  color: satir.renk,
                  backgroundColor: `${satir.renk}24`,
                }}
              >
                <MaterialRoundIcon name={satir.simge} size={16} />
              </span>
              <span className="ml-2.5 min-w-0 flex-1">
                <span className="block truncate text-[12px] font-extrabold text-lp-text">
                  {satir.baslik}
                </span>
                <span className="mt-0.5 block truncate text-[11px] font-semibold text-lp-muted">
                  {satir.altBaslik}
                </span>
              </span>
              <span className="ml-2 text-[12px] text-lp-muted" aria-hidden="true">›</span>
            </div>
          ))}
        </div>

        {profil.galeriUrlleri.length > 0 ? (
          <div className="mt-1.5">
            <div className="flex items-center">
              <p className="flex-1 text-[13px] font-black text-lp-text">Vitrin galerisi</p>
              <span
                className="rounded-full px-2.5 py-1 text-[10px] font-extrabold"
                style={{
                  color: profil.vurguRengi,
                  backgroundColor: `${profil.vurguRengi}24`,
                }}
              >
                {profil.galeriUrlleri.length} fotoğraf
              </span>
            </div>
            <div className="mt-1 flex h-[52px] gap-2">
              {profil.galeriUrlleri.slice(0, 3).map((url) => (
                <span key={url} className="relative min-w-0 flex-1 overflow-hidden rounded-xl bg-lp-bg-light">
                  <Image src={url} alt="" fill sizes="90px" className="object-cover" />
                </span>
              ))}
            </div>
          </div>
        ) : null}

        <span className="flex-1" />

        <div className="flex w-full items-center rounded-[14px] border border-lp-border bg-lp-bg-light px-3 py-2">
          <span className="min-w-0 flex-1">
            <span className="block text-[12px] font-black text-lp-text">Vitrin hazır</span>
            <span className="mt-0.5 block text-[11px] font-semibold text-lp-muted">
              {profil.eylemSatirlari.length} bağlantı
            </span>
          </span>
          <span
            className="flex h-8 w-8 items-center justify-center rounded-[10px]"
            style={{
              color: profil.vurguRengi,
              backgroundColor: `${profil.vurguRengi}24`,
            }}
          >
            <MaterialRoundIcon name="qr_code_2" size={18} />
          </span>
        </div>
      </div>
    </div>
  );
}
