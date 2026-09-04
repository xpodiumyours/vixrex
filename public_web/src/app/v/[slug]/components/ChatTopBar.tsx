import { VixrexAvatar } from "./VixrexAvatar";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

interface Props {
  rapor: HazirlikRaporu;
  onKapat: () => void;
}

/**
 * MOD 2 başlığı (2026-09-04 doğrulanmış mockup):
 * - solda Vixrex avatar + düzenleme bağlamı,
 * - sağda korkutucu yüzde yerine "Aşama N/3",
 * - ham alan sayacı yalnız ikincil/küçük bilgi,
 * - kapatma X'i.
 *
 * Ağ/Supabase bağlantısı ayrıca doğrulanmadığı için "Çevrimiçi" gibi bir
 * durum uydurulmaz. Üç aşama mevcut şemadaki önem sınıflarından türetilir;
 * yeni bir sayaç veya ikinci doğruluk kaynağı oluşturulmaz:
 * 1 = temel alanlar, 2 = kalite alanları, 3 = isteğe bağlı/son düzenlemeler.
 */
export function ChatTopBar({ rapor, onKapat }: Props) {
  const kaliteEksigiVar = rapor.eksikler.some((e) => e.onem === "kalite");
  const asama = !rapor.temelTamam ? 1 : kaliteEksigiVar ? 2 : 3;

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
        <div className="shrink-0 text-right">
          <p className="text-[12px] font-black leading-none text-sky-300">
            Aşama {asama}/3
          </p>
          <p className="mt-1 text-[10px] font-semibold text-slate-500">
            {rapor.doluSayisi}/{rapor.toplamSayisi}
          </p>
        </div>
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
