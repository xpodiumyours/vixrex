import { useState } from "react";
import {
  SECTION_LABELS,
  SECTION_ORDER,
  VITRIN_FIELDS,
} from "@/lib/vitrinFieldSchema";

interface Props {
  yerelTaslak: Record<string, unknown>;
  alanSec: (anahtar: string) => void;
}

function doluMu(deger: unknown): boolean {
  return deger !== null && deger !== undefined && String(deger).trim() !== "";
}

// Faz G3 (Tek Asistan planı, G3.1) — `FieldChipList`'in yerini alır: tek
// hap yığını yerine bölüm bölüm doluluk (9 satır), her satırda mini
// ilerleme çubuğu + n/m. 43 alanın hepsine iki tıkla erişim korunur
// (bölümü aç, alana tıkla) — yalnız görünüm katlanır, erişim kaybolmaz.
//
// "Tüm alanlar" ve şemadan üretim sözleşmesi `FieldChipList`'ten devralındı
// (bkz. tests/tum-alanlar-erisim.test.ts) — yalnız kaynağı bu dosyaya taşındı.
export function SectionProgressList({ yerelTaslak, alanSec }: Props) {
  const [acikBolum, setAcikBolum] = useState<string | null>(null);

  return (
    <div className="border-b border-white/10 px-4 py-3">
      <p className="mb-2 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
        Tüm alanlar ({VITRIN_FIELDS.length})
      </p>
      <div className="space-y-1.5">
        {SECTION_ORDER.map((bolum) => {
          const alanlar = VITRIN_FIELDS.filter((a) => a.bolum === bolum);
          if (alanlar.length === 0) return null;
          const doluSayisi = alanlar.filter((a) =>
            doluMu(yerelTaslak[a.kolon]),
          ).length;
          const acik = acikBolum === bolum;

          return (
            <div key={bolum} className="rounded-lg border border-white/10">
              <button
                type="button"
                onClick={() => setAcikBolum(acik ? null : bolum)}
                className="flex w-full items-center gap-3 px-3 py-2 text-left"
              >
                <span className="flex-1 truncate text-xs font-semibold text-slate-200">
                  {SECTION_LABELS[bolum]}
                </span>
                <span className="h-1 w-16 shrink-0 overflow-hidden rounded-full bg-white/10">
                  <span
                    className="block h-full rounded-full bg-emerald-400/80"
                    style={{
                      width: `${Math.round((doluSayisi / alanlar.length) * 100)}%`,
                    }}
                  />
                </span>
                <span className="shrink-0 text-[10px] font-mono text-slate-500">
                  {doluSayisi}/{alanlar.length}
                </span>
                <span aria-hidden className="shrink-0 text-slate-500">
                  {acik ? "−" : "+"}
                </span>
              </button>

              {acik && (
                <div className="flex flex-wrap gap-1.5 border-t border-white/10 px-3 py-2">
                  {alanlar.map((alan) => {
                    const dolu = doluMu(yerelTaslak[alan.kolon]);
                    return (
                      <button
                        key={alan.anahtar}
                        type="button"
                        onClick={() => alanSec(alan.anahtar)}
                        className={`rounded-full px-2.5 py-1 text-[11px] font-medium transition ${
                          dolu
                            ? "bg-emerald-500/10 text-emerald-300 hover:bg-emerald-500/20"
                            : "bg-white/[0.06] text-slate-400 hover:bg-white/10"
                        }`}
                      >
                        {alan.etiket}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
