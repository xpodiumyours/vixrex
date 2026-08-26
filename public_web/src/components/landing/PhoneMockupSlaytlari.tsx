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
    <div>
      <div className="relative h-[180px] w-full bg-lp-surface">
        {profil.kapakUrl ? (
          /* next/image bu projede kapalı (images.unoptimized: true,
             next.config.ts), düz <img> ile aynı çıktıyı verir. */
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
        <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-lp-bg-editor to-transparent p-3">
          <p className="text-[10px] font-extrabold tracking-[1.5px] text-lp-secondary">
            {profil.kategoriSeridi}
          </p>
          <p className="text-[16px] font-black text-white">{profil.ad}</p>
        </div>
      </div>

      <div className="flex gap-1.5 p-3">
        {profil.galeriUrlleri.length > 0 ? (
          profil.galeriUrlleri.map((url) => (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              key={url}
              src={url}
              alt=""
              className="h-14 flex-1 rounded-lg object-cover"
              loading="lazy"
            />
          ))
        ) : (
          <div className="h-14 flex-1 rounded-lg bg-lp-surface" />
        )}
      </div>

      <div className="flex justify-center gap-1.5 pb-3">
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
