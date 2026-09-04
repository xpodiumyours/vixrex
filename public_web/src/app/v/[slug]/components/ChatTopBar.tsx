import { VixrexAvatar } from "./VixrexAvatar";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

interface Props {
  rapor: HazirlikRaporu;
  onKapat: () => void;
}

// Yalnız sahiplik asistanının görsel kabuğu.
// Motor, kayıt, alan seçimi ve veri akışı değişmez.
export function ChatTopBar({ rapor, onKapat }: Props) {
  return (
    <>
      <div className="vixrex-owner-drawer-header border-b border-white/10 px-4 py-3">
        <div className="flex items-center gap-3">
          <VixrexAvatar size={32} halo decorative />

          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-bold text-white">Vixrex Asistan</p>
            <p className="vixrex-drawer-subtitle truncate text-[11px] font-medium text-slate-400">
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
        /* Asistan açıkken sağ-alt açma düğmesi kaybolur; panel kapanınca bu
           style da unmount olur ve düğme otomatik geri gelir. */
        body.vixrex-asistan-acik button[aria-label="Vixrex Asistan"] {
          opacity: 0 !important;
          pointer-events: none !important;
        }

        /* MASAÜSTÜ: vitrin yerinden oynamaz; asistan sağdan üstüne açılır. */
        @media (min-width: 640px) {
          body.vixrex-asistan-acik {
            padding-right: 0 !important;
          }

          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) {
            top: 36px !important;
            right: 0 !important;
            bottom: 0 !important;
            left: auto !important;
            width: min(400px, 36vw) !important;
            max-height: none !important;
            border-radius: 18px 0 0 18px !important;
            border-right: 0 !important;
            box-shadow: -16px 0 44px rgba(2, 6, 23, 0.26) !important;
            animation: vixrexDrawerIn 180ms ease-out both;
          }
        }

        /* MOBİL: yalnız mini sohbet. Vitrin ekranın büyük bölümünde kalır. */
        @media (max-width: 639px) {
          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) {
            top: auto !important;
            right: 8px !important;
            bottom: 8px !important;
            left: 8px !important;
            width: auto !important;
            max-height: min(32svh, 280px) !important;
            border-radius: 16px !important;
            box-shadow: 0 14px 38px rgba(2, 6, 23, 0.30) !important;
            animation: vixrexMiniChatIn 160ms ease-out both;
          }

          /* İkincil yönetim bloklarını mobil mini sohbette göstermiyoruz. */
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

          .vixrex-owner-drawer-header {
            padding: 8px 10px !important;
          }

          .vixrex-drawer-subtitle,
          .vixrex-drawer-count {
            display: none !important;
          }

          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) > .vixrex-panel-kaydirici {
            min-height: 44px !important;
            max-height: 14svh !important;
            flex: 0 1 auto !important;
            padding: 8px 10px !important;
          }
        }

        /* Mevcut kayıt durumunu yeni iş mantığı üretmeden görünür yapar. */
        body.vixrex-kaydediliyor .vixrex-drawer-count {
          display: none !important;
        }
        body.vixrex-kaydediliyor .vixrex-drawer-saving {
          display: inline-flex !important;
        }

        @keyframes vixrexDrawerIn {
          from { transform: translateX(18px); opacity: 0; }
          to { transform: translateX(0); opacity: 1; }
        }

        @keyframes vixrexMiniChatIn {
          from { transform: translateY(10px); opacity: 0; }
          to { transform: translateY(0); opacity: 1; }
        }

        @media (prefers-reduced-motion: reduce) {
          button[aria-label="Vixrex Asistan"] + div:has(> .vixrex-owner-drawer-header) {
            animation: none !important;
          }
        }
      `}</style>
    </>
  );
}
