import { useState } from "react";
import {
  SECTION_LABELS,
  SECTION_ORDER,
  VITRIN_FIELDS,
  type VitrinField,
} from "@/lib/vitrinFieldSchema";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

interface Props {
  yerelTaslak: Record<string, unknown>;
  rapor: HazirlikRaporu;
  seciliAlan: VitrinField | null;
  alanSec: (anahtar: string) => void;
}

export function FieldChipList({ yerelTaslak, rapor, seciliAlan, alanSec }: Props) {
  const [tumAlanlarAcik, setTumAlanlarAcik] = useState(false);

  if (seciliAlan) return null;

  return (
    <>
      {/* TÜM ALANLAR (bulgu 5).
       *
       * Panel yalnız "eksik" saydığı 12 alanı listeliyordu; şemadaki
       * 44 alanın 32'si "isteğe bağlı" olduğu için ne yüzdeye ne de
       * listeye giriyordu. Bir alana ulaşmanın iki yolu vardı:
       * vitrinde o yazıya tıklamak (alan BOŞSA vitrinde çizilmiyor,
       * tıklanacak bir şey yok) ya da eksikler listesinden seçmek
       * (orada değil). Sonuç: 32 alan hiçbir yoldan erişilemiyordu.
       *
       * Casper 2026-08-06'da fark etti: "41 alana çıkarmıştık ama
       * asistan hiçbir şeyi düzenleyemiyor gibi görünüyor."
       *
       * Yüzde hesabı 12 üzerinden kalıyor — o hazırlık ölçüsü.
       * Değişen tek şey ERİŞİM: artık 44'ünün hepsi tıklanabilir.
       */}
      <div className="border-t border-white/10 px-4 py-3">
        <button
          type="button"
          onClick={() => setTumAlanlarAcik((a) => !a)}
          className="flex w-full items-center justify-between text-[11px] font-semibold uppercase tracking-wider text-slate-400 transition hover:text-slate-200"
        >
          <span>Tüm alanlar ({VITRIN_FIELDS.length})</span>
          <span aria-hidden>{tumAlanlarAcik ? "−" : "+"}</span>
        </button>

        {tumAlanlarAcik && (
          <div className="mt-3 max-h-64 space-y-3 overflow-y-auto pr-1">
            {SECTION_ORDER.map((bolum) => {
              const alanlar = VITRIN_FIELDS.filter((a) => a.bolum === bolum);
              if (alanlar.length === 0) return null;
              return (
                <div key={bolum}>
                  <p className="mb-1.5 text-[10px] font-bold uppercase tracking-wider text-slate-500">
                    {SECTION_LABELS[bolum]}
                  </p>
                  <div className="flex flex-wrap gap-1.5">
                    {alanlar.map((alan) => {
                      const deger = yerelTaslak[alan.kolon];
                      const dolu =
                        deger !== null &&
                        deger !== undefined &&
                        String(deger).trim() !== "";
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
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Eksik alanlar — şemadan üretilir, elle sayılmaz */}
      {rapor.eksikler.length > 0 && (
        <div className="border-t border-white/10 px-4 py-3">
          <p className="mb-2 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
            Eksik alanlar
          </p>
          <div className="flex flex-wrap gap-1.5">
            {rapor.eksikler.slice(0, 6).map((e) => (
              <button
                key={e.anahtar}
                type="button"
                onClick={() => alanSec(e.anahtar)}
                className={`rounded-full px-2.5 py-1 text-[11px] font-medium transition ${
                  e.onem === "temel"
                    ? "bg-amber-500/15 text-amber-300 hover:bg-amber-500/25"
                    : "bg-white/[0.06] text-slate-300 hover:bg-white/10"
                }`}
              >
                {e.etiket}
              </button>
            ))}
          </div>
        </div>
      )}
    </>
  );
}
