import { VixrexAvatar } from "./VixrexAvatar";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

interface Props {
  rapor: HazirlikRaporu;
  onKapat: () => void;
}

/**
 * Sahiplik ekranındaki Vixrex Asistan başlığı.
 * Yalnız doğrulanmış mevcut bilgiler gösterilir; yeni aşama/bağlantı durumu
 * gibi ikinci bir iş kuralı üretilmez.
 */
export function ChatTopBar({ rapor, onKapat }: Props) {
  return (
    <div className="border-b border-white/10 px-4 pb-3 pt-2">
      <div className="flex items-center gap-3">
        <VixrexAvatar size={36} halo decorative />
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-bold text-white">Vixrex Asistan</p>
          <p className="mt-0.5 truncate text-[11px] font-semibold text-slate-400">
            Vitrin düzenleme
          </p>
        </div>
        <p className="shrink-0 text-[10px] font-semibold text-slate-500">
          {rapor.doluSayisi}/{rapor.toplamSayisi} alan
        </p>
        <button
          type="button"
          onClick={onKapat}
          className="ml-1 grid h-8 w-8 shrink-0 place-items-center rounded-full text-lg leading-none text-slate-400 transition hover:bg-white/5 hover:text-white"
          aria-label="Kapat"
        >
          ×
        </button>
      </div>
    </div>
  );
}
