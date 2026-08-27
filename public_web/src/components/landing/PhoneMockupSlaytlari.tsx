"use client";

import { useEffect, useState } from "react";
import type { MockupProfili } from "./mockupProfilleri";

/**
 * Mockup slayt döngüsü — envanter §2.3, Flutter'da 16 saniyelik denetleyici
 * dört profili 4'er saniye gösteriyor.
 *
 * Bu, ana sayfadaki iki istemci adasından biri. Sunucu tarafı ilk slaytı
 * zaten çizmiş durumda; burada yalnız sıra ilerletiliyor.
 *
 * `prefers-reduced-motion` açıksa döngü HİÇ başlamaz. Bu yalnız
 * erişilebilirlik değil, aynı zamanda görsel regresyon testlerinin
 * çalışabilmesinin ön koşulu: sürekli dönen bir karusel karşısında ekran
 * görüntüsü karşılaştırması hiçbir zaman kararlı olmaz.
 */
export function PhoneMockupSlaytlari({
  profiller,
}: {
  profiller: MockupProfili[];
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

  return (
    <div className="flex h-full flex-col">
      {/* Kapak + isim/kategori (Flutter: 156px kapak) */}
      <div className="relative h-[196px] w-full shrink-0 bg-lp-surface">
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
        {/* Üst rozet */}
        <div className="absolute right-2 top-2 flex items-center gap-1 rounded-full bg-lp-bg-editor/90 px-2 py-1">
          <span className="text-[10px]">{profil.uStRozet.simge}</span>
          <span className="text-[9px] font-extrabold text-white">{profil.uStRozet.renk === "#FF5A1F" ? "Galeri" : profil.uStRozet.renk === "#EA580C" ? "Menü" : profil.uStRozet.renk === "#DB2777" ? "Randevu" : "WhatsApp"}</span>
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

      {/* Vitrin hazır */}
      <div className="mx-3 mt-auto flex items-center justify-between rounded-xl border border-lp-primary/20 bg-lp-primary/[0.08] px-3 py-3">
        <div>
          <p className="text-[10px] font-bold text-white">Vitrin hazır</p>
          <p className="text-[9px] text-white/50">2 bağlantı</p>
        </div>
        <span className="text-[16px]">📱</span>
      </div>

      {/* Slayt gösterge noktaları */}
      <div className="flex justify-center gap-1.5 pb-2 pt-2">
        {profiller.map((aday, sira) => (
          <span
            key={aday.ad}
            aria-hidden
            className={`h-1.5 rounded-full transition-all ${
              sira === aktif ? "w-4 bg-lp-primary" : "w-1.5 bg-lp-border"
            }`}
          />
        ))}
      </div>
    </div>
  );
}
