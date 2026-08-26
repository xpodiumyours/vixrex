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
    <section className="bg-lp-bg-light px-6 py-16">
      <div className="mx-auto w-full max-w-[1200px]">
        <h2 className="max-w-[760px] text-[30px] font-black leading-[1.2] text-lp-text">
          Müşterin ihtiyaç duyduğu her bilgiye tek linkten ulaşsın
        </h2>
        <p className="mt-4 max-w-[760px] text-[16px] leading-[1.55] text-lp-text-alt">
          Vitrin linkinizi WhatsApp, sosyal medya, Google İşletme, kartvizit,
          paket veya işletme içi QR kod üzerinden paylaşın.
        </p>
        <ul className="mt-7 flex flex-wrap gap-2.5">
          {KANALLAR.map((kanal) => (
            <li
              key={kanal}
              className="rounded-full border border-lp-border bg-lp-surface-soft px-3.5 py-2.5 text-[12px] font-black text-lp-text-alt"
            >
              {kanal}
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
