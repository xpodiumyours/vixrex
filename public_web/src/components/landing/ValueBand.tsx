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
    <section id="neden-vixrex" className="border-t border-white/5 lp-yan-bosluk py-lp-section">
      <div className="mx-auto w-full max-w-lp">
        <div className="lp-glass-panel flex flex-col gap-6 rounded-[32px] p-7 sm:p-10 md:flex-row md:items-center md:gap-12">
          <div className="md:flex-[5]">
            <h2 className="text-[30px] font-black leading-[1.2] text-lp-text">
              Müşterin ihtiyaç duyduğu her bilgiye tek linkten ulaşsın
            </h2>
            <p className="mt-3.5 text-[16px] leading-[1.55] text-lp-text-alt">
              Vitrin linkinizi WhatsApp, sosyal medya, Google İşletme, kartvizit,
              paket veya işletme içi QR kod üzerinden paylaşın.
            </p>
          </div>
          <ul className="flex flex-wrap justify-start gap-2.5 md:flex-[4] md:justify-end">
            {KANALLAR.map((kanal) => (
              <li
                key={kanal}
                className="rounded-full border border-sky-400/35 bg-[#147DFF]/18 px-4 py-2.5 text-[12.5px] font-black text-sky-200 backdrop-blur-md"
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
