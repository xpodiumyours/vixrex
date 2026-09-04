import { sonrakiRehberAlanlar } from "@/lib/vitrinReadiness";

interface Props {
  yerelTaslak: Record<string, unknown>;
  suankiAnahtar: string | null;
  atlanmisAlanlar: ReadonlySet<string>;
  alanSec: (anahtar: string) => void;
  /** Bir alanı sıradan çıkarır (mevcut "sonra" akışı). */
  alanAtla?: (anahtar: string) => void;
}

// "SIRADA" — sonraki üç alan. Sıra ŞEMADAN gelir, elle tutulmaz
// (`sonrakiRehberAlanlar`).
//
// MOD 2 (2026-09-04): karar noktaları düz metin gibi kaybolmamalı. İlk iş
// büyük, tek dokunuşlu bir karar kartı; diğer iki iş ikincil satırlar olarak
// kalır. Süre tahmini için şemada doğrulanmış veri olmadığı için uydurma
// "~N dakika" gösterilmez.
export function UpNextList({
  yerelTaslak,
  suankiAnahtar,
  atlanmisAlanlar,
  alanSec,
  alanAtla,
}: Props) {
  const sonrakiler = sonrakiRehberAlanlar(
    yerelTaslak,
    suankiAnahtar,
    atlanmisAlanlar,
    3,
  );

  if (sonrakiler.length === 0) return null;

  const [simdi, ...sonra] = sonrakiler;

  return (
    <div className="border-b border-white/10 px-4 py-3">
      <p className="mb-2 text-[11px] font-black uppercase tracking-[0.14em] text-slate-400">
        Sırada
      </p>

      <button
        type="button"
        onClick={() => alanSec(simdi.anahtar)}
        className="group flex w-full items-center gap-3 rounded-xl border border-blue-400/50 bg-blue-500/10 px-3.5 py-3 text-left transition hover:border-blue-300/70 hover:bg-blue-500/15"
      >
        <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-blue-500/20 text-sm font-black text-sky-300">
          1
        </span>
        <span className="min-w-0 flex-1">
          <span className="block truncate text-[13px] font-black text-white">
            {simdi.etiket}
          </span>
          <span className="mt-0.5 block text-[10px] font-bold uppercase tracking-[0.1em] text-sky-400">
            Şimdi düzenle
          </span>
        </span>
        <span className="text-lg leading-none text-sky-300 transition group-hover:translate-x-0.5" aria-hidden="true">
          ›
        </span>
      </button>

      {sonra.length > 0 ? (
        <div className="mt-1.5 flex flex-col gap-1">
          {sonra.map((alan, index) => (
            <div
              key={alan.anahtar}
              className="flex items-center gap-3 rounded-lg bg-white/[0.035] px-3 py-2"
            >
              <span className="w-5 shrink-0 text-center text-[10px] font-black text-slate-600">
                {index + 2}
              </span>
              <button
                type="button"
                onClick={() => alanSec(alan.anahtar)}
                className="min-w-0 flex-1 truncate text-left text-[12px] font-bold text-slate-300 hover:text-white"
              >
                {alan.etiket}
              </button>
              {alanAtla ? (
                <button
                  type="button"
                  onClick={() => alanAtla(alan.anahtar)}
                  className="shrink-0 text-[10px] font-bold text-slate-500 hover:text-slate-300"
                >
                  atla
                </button>
              ) : null}
            </div>
          ))}
        </div>
      ) : null}
    </div>
  );
}
