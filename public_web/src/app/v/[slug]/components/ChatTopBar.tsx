import { VixrexAvatar } from "./VixrexAvatar";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

interface Props {
  rapor: HazirlikRaporu;
  onKapat: () => void;
}

// Faz G3 (Tek Asistan planı): panel içi başlık, Faz A'nın Flutter
// `ChatTopBar`'ıyla aynı ölçülerde ayrı bir bileşene çıkarıldı — avatar 36,
// başlık `subTitle` karşılığı (text-sm/w800), alt satır 11px/w700.
export function ChatTopBar({ rapor, onKapat }: Props) {
  return (
    <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
      <div className="flex min-w-0 items-center gap-3">
        <VixrexAvatar size={36} halo decorative />
        <div className="min-w-0">
          <p className="truncate text-sm font-bold text-white">Vixrex Asistan</p>
          <p className="truncate text-[11px] font-bold text-sky-400">
            Doluluk %{rapor.yuzde} · {rapor.doluSayisi}/{rapor.toplamSayisi} alan
          </p>
        </div>
      </div>
      <button
        type="button"
        onClick={onKapat}
        className="ml-3 shrink-0 text-lg leading-none text-slate-400 hover:text-white"
        aria-label="Kapat"
      >
        ×
      </button>
    </div>
  );
}
