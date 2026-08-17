import { alanOnemi, sonrakiRehberAlanlar, type EksikOnem } from "@/lib/vitrinReadiness";

const ONEM_RENGI: Record<EksikOnem, string> = {
  temel: "border-red-300/40 bg-red-500/10 text-red-200 hover:bg-red-500/20",
  kalite: "border-sky-400/40 bg-sky-500/10 text-sky-200 hover:bg-sky-500/20",
  "istege-bagli": "border-white/10 bg-white/[0.04] text-slate-400 hover:bg-white/10",
};

interface Props {
  yerelTaslak: Record<string, unknown>;
  suankiAnahtar: string | null;
  atlanmisAlanlar: ReadonlySet<string>;
  alanSec: (anahtar: string) => void;
}

// Faz G3 (Tek Asistan planı, G3.1) — "Sırada": sonraki üç alan, önem
// rengiyle, tıklanabilir. `sonrakiRehberAlan`'ın (tekil) çoğulu üstüne
// kurulu; sıra ŞEMADAN, elle tutulmaz.
export function UpNextList({
  yerelTaslak,
  suankiAnahtar,
  atlanmisAlanlar,
  alanSec,
}: Props) {
  const sonrakiler = sonrakiRehberAlanlar(
    yerelTaslak,
    suankiAnahtar,
    atlanmisAlanlar,
    3,
  );

  if (sonrakiler.length === 0) return null;

  return (
    <div className="border-b border-white/10 px-4 py-3">
      <p className="mb-2 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
        Sırada
      </p>
      <div className="flex flex-wrap gap-1.5">
        {sonrakiler.map((alan) => {
          const onem = alanOnemi(alan);
          return (
            <button
              key={alan.anahtar}
              type="button"
              onClick={() => alanSec(alan.anahtar)}
              className={`rounded-full border px-2.5 py-1 text-[11px] font-medium transition ${ONEM_RENGI[onem]}`}
            >
              {alan.etiket}
            </button>
          );
        })}
      </div>
    </div>
  );
}
