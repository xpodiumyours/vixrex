/** Değer bandı — envanter §2.4. */
const KANALLAR = [
  "WhatsApp",
  "Sosyal medya",
  "Google İşletme",
  "QR kod",
  "Vitrin linki",
] as const;

export function ValueBand() {
  return (
    <section className="bg-lp-bg-light px-6 py-lp-section">
      <div className="mx-auto w-full max-w-lp">
        <div className="flex flex-col gap-6 md:flex-row md:items-center md:gap-12">
          <div className="md:flex-[5]">
            <h2 className="text-[30px] font-black leading-[1.2] text-lp-text">
              Müşterin ihtiyaç duyduğu her bilgiye tek linkten ulaşsın
            </h2>
            <p className="mt-3.5 text-[16px] leading-[1.55] text-lp-text-alt">
              Vitrin linkinizi WhatsApp, sosyal medya, Google İşletme, kartvizit,
              paket veya işletme içi QR kod üzerinden paylaşın.
            </p>
          </div>
          <ul className="flex flex-wrap justify-center gap-2.5 md:flex-[4] md:justify-end">
            {KANALLAR.map((kanal) => (
              <li
                key={kanal}
                className="rounded-full border border-lp-border bg-lp-surface-soft px-3.5 py-[11px] text-[12px] font-black text-lp-text-alt"
              >
                {kanal}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
