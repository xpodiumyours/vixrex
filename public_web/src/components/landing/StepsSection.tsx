/** Üç adım — envanter §2.8. */
const ADIMLAR = [
  {
    baslik: "Vitrininizi kurun",
    aciklama:
      "İşletme bilgilerini, görsellerini, ürün ve hizmetlerini ekle.",
  },
  {
    baslik: "Yayınla",
    aciklama:
      "Bilgilerinizi kontrol edin; vitrin linkinizi ve QR kodunuzu hazır edin.",
  },
  {
    baslik: "Müşterilerinize duyurun",
    aciklama:
      "Linkinizi WhatsApp, sosyal medya veya işletmenizdeki QR kod ile paylaşın.",
  },
] as const;

export function StepsSection() {
  return (
    <section className="bg-lp-bg-light lp-yan-bosluk py-lp-section">
      <div className="mx-auto w-full max-w-lp">
        <h2 className="text-center text-[36px] font-black text-lp-text">
          Üç adımda dijital vitrinin hazır
        </h2>
        <ol className="mt-14 grid gap-10 md:grid-cols-3">
          {ADIMLAR.map((adim, sira) => (
            <li key={adim.baslik} className="flex flex-col items-center text-center">
              <span
                aria-hidden
                className="flex h-[60px] w-[60px] items-center justify-center rounded-full border-2 border-lp-primary/30 bg-lp-primary/10 text-[24px] font-black text-lp-primary"
              >
                {sira + 1}
              </span>
              <h3 className="mt-5 text-[18px] font-bold text-lp-text">
                {adim.baslik}
              </h3>
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
