"use client";

import {
  VITRIN_CONCEPTS,
  fieldsOfConcept,
  type VitrinConcept,
} from "@/lib/vitrinFieldSchema";
import { doluMu } from "@/lib/vitrinReadiness";

interface Props {
  yerelTaslak: Record<string, unknown>;
  alanSec: (anahtar: string) => void;
  acikKavram: VitrinConcept | null;
  kavramDegistir: (kavram: VitrinConcept | null) => void;
}

export function ConceptProgressList({
  yerelTaslak,
  alanSec,
  acikKavram,
  kavramDegistir,
}: Props) {

  return (
    <div className="border-b border-white/10 px-4 py-3">
      <p className="mb-2 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
        İşletme konuları
      </p>
      <div className="space-y-1.5">
        {VITRIN_CONCEPTS.map((kavram) => {
          const alanlar = fieldsOfConcept(kavram.id);
          const doluSayisi = alanlar.filter((alan) =>
            doluMu(yerelTaslak[alan.kolon], alan.bosDegerler),
          ).length;
          const eksikZorunlu = alanlar.filter(
            (alan) =>
              alan.zorunlu &&
              !doluMu(yerelTaslak[alan.kolon], alan.bosDegerler),
          ).length;
          const eksikKalite = alanlar.filter(
            (alan) =>
              alan.kalite &&
              !doluMu(yerelTaslak[alan.kolon], alan.bosDegerler),
          ).length;
          const acik = acikKavram === kavram.id;
          const durum =
            eksikZorunlu > 0
              ? `${eksikZorunlu} zorunlu eksik`
              : eksikKalite > 0
                ? `${eksikKalite} kalite önerisi`
                : doluSayisi > 0
                  ? "Hazır"
                  : "İsteğe bağlı";

          return (
            <div key={kavram.id} className="rounded-lg border border-white/10">
              <button
                type="button"
                onClick={() => kavramDegistir(acik ? null : kavram.id)}
                className="flex w-full items-center gap-3 px-3 py-2 text-left"
              >
                <span className="min-w-0 flex-1">
                  <span className="block truncate text-xs font-semibold text-slate-200">
                    {kavram.etiket}
                  </span>
                  <span className="block truncate text-[10px] text-slate-500">
                    {kavram.aciklama}
                  </span>
                </span>
                <span className="shrink-0 text-[10px] font-medium text-slate-500">
                  {durum}
                </span>
                <span aria-hidden className="shrink-0 text-slate-500">
                  {acik ? "−" : "+"}
                </span>
              </button>

              {acik && (
                <div className="flex flex-wrap gap-1.5 border-t border-white/10 px-3 py-2">
                  {alanlar.map((alan) => {
                    const dolu = doluMu(
                      yerelTaslak[alan.kolon],
                      alan.bosDegerler,
                    );
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
