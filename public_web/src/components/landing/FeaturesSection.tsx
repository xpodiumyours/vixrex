import { MaterialRoundIcon } from "./MaterialRoundIcon";

type Kart = {
  ikon: "bolt" | "contact_phone" | "share" | "edit_note";
  renk: string;
  baslik: string;
  aciklama: string;
};

const KARTLAR: Kart[] = [
  {
    ikon: "bolt",
    renk: "#147DFF",
    baslik: "Dakikalar içinde yayına alın",
    aciklama: "Temel bilgilerini ekle, vitrinini oluştur.",
  },
  {
    ikon: "contact_phone",
    renk: "#10B981",
    baslik: "Müşteriler size doğrudan ulaşsın",
    aciklama: "WhatsApp, adres ve yol tarifi seçeneklerini tek yerde sunun.",
  },
  {
    ikon: "share",
    renk: "#8B5CF6",
    baslik: "Her kanalda aynı vitrini paylaşın",
    aciklama: "Linkinizi sosyal medyada, QR kodunuzu işletmenizde kullanın.",
  },
  {
    ikon: "edit_note",
    renk: "#57B7FF",
    baslik: "Bilgilerini panelden güncelle",
    aciklama: "Fotoğraf, ürün, hizmet ve iletişim bilgilerini istediğin zaman düzenle.",
  },
];

/** Flutter `landing_features_section.dart` + `landing_value_card.dart` karşılığı. */
export function FeaturesSection() {
  return (
    <section className="bg-lp-bg-light px-6 pb-[72px] pt-12">
      <div className="mx-auto w-full max-w-[1200px]">
        <h2 className="text-center text-[38px] font-black leading-normal tracking-normal text-lp-text">
          Dijital vitrinini kolayca hazırla
        </h2>
        <p className="mt-5 text-center text-[18px] leading-[1.5] text-lp-text-alt">
          Müşterinin ihtiyaç duyduğu bilgileri tek vitrinde topla, panelden yönet,
          istediğin yerde paylaş.
        </p>

        <div className="mt-12 flex flex-wrap justify-center gap-[18px]">
          {KARTLAR.map((kart) => (
            <article
              key={kart.baslik}
              className="flex w-full items-start rounded-[28px] border-[1.2px] border-lp-border/85 bg-lp-surface p-6 shadow-[0_14px_24px_rgba(0,0,0,0.06)] transition-transform duration-[220ms] ease-out min-[729px]:block min-[729px]:w-[calc(50%_-_9px)] min-[1089px]:w-[calc(25%_-_13.5px)] min-[1089px]:hover:-translate-y-1.5 min-[1089px]:hover:scale-[1.01]"
            >
              <span
                className="flex h-[54px] w-[54px] shrink-0 items-center justify-center rounded-[18px]"
                style={{ color: kart.renk, backgroundColor: `color-mix(in srgb, ${kart.renk} 14%, transparent)` }}
              >
                <MaterialRoundIcon name={kart.ikon} size={26} />
              </span>

              <div className="ml-[15px] min-w-0 flex-1 text-left min-[729px]:ml-0 min-[729px]:mt-[18px]">
                <h3 className="text-[22px] font-black leading-[1.15] tracking-[-0.6px] text-lp-text">
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
