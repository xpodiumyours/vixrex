import { VixrexAvatar } from "./VixrexAvatar";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

interface Props {
  rapor: HazirlikRaporu;
  onKapat: () => void;
}

// Sahiplik görünümü için yalnız görsel kabuk:
// - masaüstünde asistan vitrinin üstüne sağdan açılan çekmece gibi biner,
// - mobilde yalnız başlık + sohbet + mevcut giriş alanı görünür,
// - mevcut motor/veri akışına dokunulmaz.
export function ChatTopBar({ rapor, onKapat }: Props) {
  return (
    <>
      <div className="vixrex-owner-drawer-header border-b border-white/10 px-4 py-3">
        <div className="flex items-center gap-3">
          <VixrexAvatar size={32} halo decorative />
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-bold text-white">Vixrex Asistan</p>
            <p className="truncate text-[11px] font-medium text-slate-400">
              Vitrinini düzenle
            </p>
          </div>

          <span className="vixrex-drawer-count shrink-0 rounded-full border border-white/10 bg-white/[0.06] px-2.5 py-1 text-[10px] font-bold text-slate-300">
            {rapor.doluSayisi}/{rapor.toplamSayisi}
          </span>
          <span className="vixrex-drawer-saving hidden shrink-0 items-center gap-1.5 rounded-full border border-blue-400/20 bg-blue-500/10 px-2.5 py-1 text-[10px] font-bold text-blue-300">
            <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-blue-400" />
            Kaydediliyor…
          </span>

          <button
            type="button"
            onClick={onKapat}
            className="ml-1 flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-lg leading-none text-slate-400 transition hover:bg-white/[0.06] hover:text-white"
            aria-label="Kapat"
          >
            ×
          </button>
        </div>
      </div>

      <style>{`
        /* Bu stil yalnız ChatTopBar render edildiğinde vardır; yani yalnız
           sahiplik asistanı açıkken devreye girer. Global layout değiştirmez. */
        @media (min-width: 640px) {
          body.vixrex-asistan-acik {
            padding-right: 0 !important;
          }

          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) {
            top: 36px !important;
            right: 0 !important;
            bottom: 0 !important;
            left: auto !important;
            width: min(420px, 38vw) !important;
            max-height: none !important;
            border-radius: 20px 0 0 20px !important;
            border-right: 0 !important;
            box-shadow: -18px 0 48px rgba(2, 6, 23, 0.24) !important;
          }
        }

        @media (max-width: 639px) {
          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) {
            top: auto !important;
            right: 10px !important;
            bottom: 10px !important;
            left: 10px !important;
            width: auto !important;
            max-height: min(44vh, 380px) !important;
            border-radius: 18px !important;
            box-shadow: 0 14px 42px rgba(2, 6, 23, 0.32) !important;
          }

          /* Mobilde minimum alan: yalnız başlık, sohbet ve mevcut tek giriş
             bileşeni görünür. SIRADA, yayınla ve ikincil yönetim blokları
             masaüstü çekmecesinde kalır. */
          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) > * {
            display: none !important;
          }

          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) > .vixrex-owner-drawer-header,
          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) > .vixrex-panel-kaydirici,
          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) > div:has(textarea),
          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) > div:has(select),
          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) > div:has(input[type="file"]) {
            display: block !important;
          }

          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) > .vixrex-panel-kaydirici {
            min-height: 56px !important;
            max-height: 20vh !important;
            flex: 0 1 auto !important;
            padding: 10px 12px !important;
          }

          .vixrex-owner-drawer-header {
            padding: 9px 10px !important;
          }
        }

        /* Mevcut kaydetme durumunu yeni state üretmeden görünür yapar. */
        body.vixrex-kaydediliyor .vixrex-drawer-count {
          display: none !important;
        }
        body.vixrex-kaydediliyor .vixrex-drawer-saving {
          display: inline-flex !important;
        }
      `}</style>
    </>
  );
}
