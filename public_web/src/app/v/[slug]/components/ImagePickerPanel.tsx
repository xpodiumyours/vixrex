import type { HazirGorsel } from "../hooks/useOwnerActions";

interface Props {
  hazirGorseller: HazirGorsel[];
  hazirYukleniyor: boolean;
  kaydediliyor: boolean;
  hazirGorselleriAc: () => Promise<void>;
  hazirGorselSec: (url: string) => Promise<void>;
}

export function ImagePickerPanel({
  hazirGorseller,
  hazirYukleniyor,
  kaydediliyor,
  hazirGorselleriAc,
  hazirGorselSec,
}: Props) {
  return (
    <>
      {/* HAZIR GÖRSELLER — kütüphane BURADA açılır.
          Eskiden "hazır şablon seç" denince kütüphane Flutter
          manuel panelinde açılıyordu; esnaf o sırada yayındaki
          vitrinini düzenliyordu, yani yanlış taraftaydı. */}
      <button
        type="button"
        onClick={() => void hazirGorselleriAc()}
        disabled={kaydediliyor}
        className="mt-2 w-full rounded-lg border border-white/10 bg-white/[0.04] px-4 py-2.5 text-xs font-semibold text-slate-200 transition hover:bg-white/[0.08] disabled:opacity-50"
      >
        🖼️ {hazirYukleniyor ? "Getiriliyor…" : "Hazır görsellerden seç"}
      </button>

      {hazirGorseller.length > 0 && (
        <div className="mt-2 grid max-h-44 grid-cols-3 gap-2 overflow-y-auto rounded-lg border border-white/10 bg-black/20 p-2">
          {hazirGorseller.map((g) => (
            <button
              key={g.image_url}
              type="button"
              disabled={kaydediliyor}
              onClick={() => void hazirGorselSec(g.image_url)}
              title={g.title ?? ""}
              className="group relative aspect-square overflow-hidden rounded-md border border-white/10 transition hover:border-blue-500/60 disabled:opacity-50"
            >
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={g.image_url}
                alt={g.title ?? "Hazır görsel"}
                className="h-full w-full object-cover transition group-hover:scale-105"
              />
            </button>
          ))}
        </div>
      )}
    </>
  );
}
