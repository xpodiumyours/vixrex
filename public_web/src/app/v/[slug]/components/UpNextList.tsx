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
// Mobilde üç görevi aynı anda göstermek asistanı bir form listesine
// çeviriyordu. Esnafın o anda tek karar vermesi yeter: ilk görev görünür,
// kalan iki görev masaüstünde korunur. Sıralama/atlama iş mantığı değişmez.
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

  return (
    <div className="border-b border-white/10 px-4 py-2.5 sm:py-3">
      <p className="mb-2 text-[11px] font-black uppercase tracking-[0.14em] text-slate-400">
        <span className="sm:hidden">Şimdi</span>
        <span className="hidden sm:inline">Sırada</span>
      </p>
      <div className="flex flex-col gap-1.5">
        {sonrakiler.map((alan, sira) => {
          const simdi = sira === 0;
          return (
            <div
              key={alan.anahtar}
              className={`${sira > 0 ? "hidden sm:flex" : "flex"} items-center gap-3 rounded-xl px-3 py-2.5 transition ${
                simdi
                  ? "border border-blue-500/60 bg-blue-500/10"
                  : "bg-white/[0.04]"
              }`}
            >
              <button
                type="button"
                onClick={() => alanSec(alan.anahtar)}
                className={`min-w-0 flex-1 truncate text-left text-[13px] font-bold ${
                  simdi ? "text-sky-300" : "text-slate-300 hover:text-white"
                }`}
              >
                {alan.etiket}
              </button>
              {simdi ? (
                <span className="shrink-0 text-[10px] font-black tracking-wider text-sky-400">
                  ŞİMDİ
                </span>
              ) : alanAtla ? (
                <button
                  type="button"
                  onClick={() => alanAtla(alan.anahtar)}
                  className="shrink-0 text-[11px] font-bold text-slate-500 hover:text-slate-300"
                >
                  atla
                </button>
              ) : null}
            </div>
          );
        })}
      </div>
    </div>
  );
}
