const KANALLAR = [
  "WhatsApp",
  "Sosyal medya",
  "Google İşletme",
  "QR kod",
  "Vitrin linki",
] as const;

/** Flutter `landing_value_band.dart` karşılığı. */
export function ValueBand() {
  return (
    <section className="bg-lp-bg-light px-6 py-16">
      <div className="mx-auto w-full max-w-[1200px]">
        <div className="flex flex-col items-center min-[869px]:flex-row min-[869px]:items-center">
          <div className="w-full text-center min-[869px]:basis-5/9 min-[869px]:text-left">
            <h2 className="text-[30px] font-black leading-[1.2] text-lp-text">
              Müşterin ihtiyaç duyduğu her bilgiye tek linkten ulaşsın
            </h2>
            <p className="mt-3.5 text-[16px] leading-[1.55] text-lp-text-alt">
              Vitrin linkinizi WhatsApp, sosyal medya, Google İşletme, kartvizit,
              paket veya işletme içi QR kod üzerinden paylaşın.
            </p>
          </div>

          <div className="h-6 w-full min-[869px]:h-auto min-[869px]:w-12" aria-hidden="true" />

          <ul className="flex w-full flex-wrap justify-center gap-2.5 min-[869px]:basis-4/9 min-[869px]:justify-end">
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
