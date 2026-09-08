import { MaterialRoundIcon } from "./MaterialRoundIcon";

const ROZETLER = [
  ["credit_card_off", "Kredi kartı gerekmez"],
  ["percent", "Satıştan komisyon alınmaz"],
  ["code_off", "Kodsuz kurulum"],
  ["qr_code_2", "Link ve QR kod hazırdır"],
  ["chat_bubble", "WhatsApp ile doğrudan iletişim"],
] as const;

/** Flutter `landing_trust_band.dart` karşılığı. */
export function TrustBand() {
  return (
    <section className="bg-lp-bg-light px-6 py-14">
      <div className="mx-auto w-full max-w-[1100px] text-center">
        <h2 className="text-[30px] font-black text-lp-text">Başlarken sürpriz yok</h2>
        <ul className="mt-7 flex flex-wrap justify-center gap-3">
          {ROZETLER.map(([ikon, rozet]) => (
            <li
              key={rozet}
              className="flex items-center gap-2 rounded-full border border-lp-border bg-lp-surface px-4 py-3 text-[13px] font-extrabold text-lp-text"
            >
              <span className="text-lp-primary">
                <MaterialRoundIcon name={ikon} size={18} />
              </span>
              {rozet}
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
