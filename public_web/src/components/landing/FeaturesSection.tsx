import type { JSX } from "react";
import {
  DuzenleIkonu,
  IletisimIkonu,
  PaylasIkonu,
  SimsekIkonu,
} from "@/components/site/icons";

/** Özellik kartları — envanter §2.5. */
type Kart = {
  ikon: JSX.Element;
  renk: string;
  baslik: string;
  aciklama: string;
};

const KARTLAR: Kart[] = [
  {
    ikon: <SimsekIkonu />,
    renk: "text-lp-primary",
    baslik: "Dakikalar içinde yayına alın",
    aciklama: "Temel bilgilerini ekle, vitrinini oluştur.",
  },
  {
    ikon: <IletisimIkonu />,
    renk: "text-lp-mint",
    baslik: "Müşteriler size doğrudan ulaşsın",
    aciklama:
      "WhatsApp, adres ve yol tarifi seçeneklerini tek yerde sunun.",
  },
  {
    ikon: <PaylasIkonu />,
    renk: "text-lp-pink",
    baslik: "Her kanalda aynı vitrini paylaşın",
    aciklama:
      "Linkinizi sosyal medyada, QR kodunuzu işletmenizde kullanın.",
  },
  {
    ikon: <DuzenleIkonu />,
    renk: "text-lp-secondary",
    baslik: "Bilgilerini panelden güncelle",
    aciklama:
      "Fotoğraf, ürün, hizmet ve iletişim bilgilerini istediğin zaman düzenle.",
  },
];

export function FeaturesSection() {
  return (
    <section className="bg-lp-bg-light px-6 pb-[72px] pt-12">
      <div className="mx-auto w-full max-w-[1200px]">
        <h2 className="text-center text-[38px] font-black leading-[1.1] text-lp-text">
          Dijital vitrinini kolayca hazırla
        </h2>
        <p className="mx-auto mt-5 max-w-[720px] text-center text-[18px] leading-[1.5] text-lp-text-alt">
          Müşterinin ihtiyaç duyduğu bilgileri tek vitrinde topla, panelden
          yönet, istediğin yerde paylaş.
        </p>

        <div className="mt-12 flex flex-wrap justify-center gap-[18px]">
          {KARTLAR.map((kart) => (
            <article
              key={kart.baslik}
              className="flex w-full items-start gap-[15px] rounded-[28px] border-[1.2px] border-lp-border/85 bg-lp-surface p-6 shadow-lp-card min-[729px]:block min-[729px]:w-[calc(50%-9px)] min-[1089px]:w-[calc(25%-14px)] min-[1089px]:transition-transform min-[1089px]:duration-[220ms] min-[1089px]:ease-out min-[1089px]:hover:-translate-y-[6px] min-[1089px]:hover:scale-[1.01] motion-reduce:transform-none motion-reduce:transition-none"
            >
              <span
                className={`flex h-[54px] w-[54px] shrink-0 items-center justify-center rounded-[18px] bg-current/15 ${kart.renk}`}
              >
                {kart.ikon}
              </span>
              <div className="min-w-0 flex-1">
                <h3 className="text-[22px] font-black leading-[1.15] tracking-[-0.6px] text-lp-text min-[729px]:mt-[18px]">
                  {kart.baslik}
                </h3>
                <p className="mt-2.5 text-[16px] font-semibold leading-[1.6] text-lp-text-alt">
                  {kart.aciklama}
                </p>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
