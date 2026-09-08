const ADIMLAR = [
  {
    baslik: "Vitrininizi kurun",
    aciklama: "İşletme bilgilerini, görsellerini, ürün ve hizmetlerini ekle.",
  },
  {
    baslik: "Yayınla",
    aciklama: "Bilgilerinizi kontrol edin; vitrin linkinizi ve QR kodunuzu hazır edin.",
  },
  {
    baslik: "Müşterilerinize duyurun",
    aciklama: "Linkinizi WhatsApp, sosyal medya veya işletmenizdeki QR kod ile paylaşın.",
  },
] as const;

/** Flutter `landing_steps_section.dart` karşılığı. */
export function StepsSection() {
  return (
    <section className="bg-lp-bg-light px-6 py-[76px]">
      <div className="mx-auto w-full max-w-[1200px]">
        <h2 className="text-center text-[36px] font-black tracking-normal text-lp-text">
          Üç adımda dijital vitrinin hazır
        </h2>

        <ol className="mt-14 flex flex-col min-[849px]:flex-row min-[849px]:items-start">
          {ADIMLAR.map((adim, sira) => (
            <li
              key={adim.baslik}
              className="mb-7 flex w-full flex-col items-center text-center last:mb-0 min-[849px]:mb-0 min-[849px]:flex-1"
            >
              <span className="flex h-[60px] w-[60px] items-center justify-center rounded-full border-2 border-lp-primary/30 bg-lp-primary/10 text-[24px] font-black text-lp-primary">
                {sira + 1}
              </span>
              <h3 className="mt-5 text-[18px] font-bold text-lp-text">{adim.baslik}</h3>
              <p className="mt-2.5 px-5 text-[14px] font-semibold leading-[1.45] text-lp-muted">
                {adim.aciklama}
              </p>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
