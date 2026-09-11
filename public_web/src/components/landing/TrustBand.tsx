import { OnayIkonu } from "@/components/site/icons";

/** Güven bandı — envanter §2.7. */
const ROZETLER = [
  "Kredi kartı gerekmez",
  "Satıştan komisyon alınmaz",
  "Kodsuz kurulum",
  "Link ve QR kod hazırdır",
  "WhatsApp ile doğrudan iletişim",
] as const;

export function TrustBand() {
  return (
    <section className="bg-lp-bg-light lp-yan-bosluk py-lp-section">
      <div className="mx-auto w-full max-w-lp text-center">
        <h2 className="text-[30px] font-black text-lp-text">
          Başlarken sürpriz yok
        </h2>
        <ul className="mt-7 flex flex-wrap justify-center gap-3">
          {ROZETLER.map((rozet) => (
            <li
              key={rozet}
              className="flex items-center gap-2 rounded-full border border-lp-border bg-lp-surface px-4 py-3 text-[13px] font-extrabold text-lp-text"
            >
              <span className="text-lp-primary">
                <OnayIkonu boyut={18} />
              </span>
              {rozet}
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
