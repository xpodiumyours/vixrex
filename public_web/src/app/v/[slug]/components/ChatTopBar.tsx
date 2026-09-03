import { VixrexAvatar } from "./VixrexAvatar";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

interface Props {
  rapor: HazirlikRaporu;
  onKapat: () => void;
}

// Panel başlığı — ekrandaki TEK doluluk göstergesi.
//
// 2026-09-03 (Çalışma masası / Yön C): doluluk iki yerde birden
// gösteriliyordu ve sayılar tutmuyordu; "Sahip Çalışma Alanı" çekmecesi
// kalktı, tek kaynak burası oldu. Simge canonical kristal maskot
// (VixrexAvatar) — Flutter tarafıyla aynı görsel, ikiye ayrılmasın.
export function ChatTopBar({ rapor, onKapat }: Props) {
  return (
    <div className="border-b border-white/10 px-4 py-3">
      <div className="flex items-center gap-3">
        <VixrexAvatar size={36} halo decorative />
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-bold text-white">Vixrex Asistan</p>
          <p className="truncate text-[11px] font-semibold text-slate-400">
            {rapor.doluSayisi}/{rapor.toplamSayisi} alan dolu
          </p>
        </div>
        <div className="shrink-0 text-right">
          <p className="text-[17px] font-black leading-none text-sky-400">
            %{rapor.yuzde}
          </p>
          <p className="mt-0.5 text-[10px] font-semibold text-slate-500">hazır</p>
        </div>
        <button
          type="button"
          onClick={onKapat}
          className="ml-1 shrink-0 text-lg leading-none text-slate-400 hover:text-white"
          aria-label="Kapat"
        >
          ×
        </button>
      </div>
      <div className="mt-2.5 h-1.5 overflow-hidden rounded-full bg-white/10">
        <div
          className="h-full rounded-full bg-blue-500 transition-all duration-500"
          style={{ width: `${rapor.yuzde}%` }}
        />
      </div>
    </div>
  );
}
