"use client";

import { useRef, type PointerEvent as ReactPointerEvent } from "react";
import { VixrexAvatar } from "./VixrexAvatar";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

interface Props {
  rapor: HazirlikRaporu;
  onKapat: () => void;
}

// Sahiplik sayfasındaki Vixrex Asistan kabuğunun tek başlığı.
// Mobilde bu başlık yalnız çekmece yukarı açıldığında görünür; günlük
// kullanım yüzeyi alttaki compact composer'dır. Maskot mobilde SAĞDA,
// masaüstünde mevcut soldaki konumunda kalır.
export function ChatTopBar({ rapor, onKapat }: Props) {
  const mobilTutamakRef = useRef<number | null>(null);
  const asama = rapor.yuzde < 34 ? 1 : rapor.yuzde < 67 ? 2 : 3;

  const tutamakBasla = (olay: ReactPointerEvent<HTMLDivElement>) => {
    if (window.matchMedia("(min-width: 640px)").matches) return;
    mobilTutamakRef.current = olay.clientY;
    olay.currentTarget.setPointerCapture?.(olay.pointerId);
  };

  const tutamakBitir = (olay: ReactPointerEvent<HTMLDivElement>) => {
    const baslangic = mobilTutamakRef.current;
    mobilTutamakRef.current = null;
    if (baslangic === null) return;
    // Geçmiş çekmecesini aşağı sürüklemek compact composer'a döndürür.
    if (olay.clientY - baslangic > 28) onKapat();
    if (olay.currentTarget.hasPointerCapture?.(olay.pointerId)) {
      olay.currentTarget.releasePointerCapture?.(olay.pointerId);
    }
  };

  return (
    <>
      <div className="relative shrink-0 border-b border-white/10 bg-[linear-gradient(180deg,rgba(24,37,63,0.96),rgba(11,17,32,0.96))] px-4 pb-3 pt-2.5 sm:pt-3">
        <div
          role="separator"
          aria-orientation="horizontal"
          aria-label="Sohbet geçmişini küçültmek için aşağı çek"
          onPointerDown={tutamakBasla}
          onPointerUp={tutamakBitir}
          onPointerCancel={() => {
            mobilTutamakRef.current = null;
          }}
          onDoubleClick={onKapat}
          className="mx-auto mb-2 flex h-3 w-14 touch-none select-none items-center justify-center sm:hidden"
        >
          <span className="h-1 w-10 rounded-full bg-white/25" />
        </div>

        <div className="flex items-center gap-3">
          <div className="order-4 relative shrink-0 sm:order-1">
            <VixrexAvatar size={38} halo decorative />
            <span
              className="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-[#111b2d] bg-emerald-400"
              aria-hidden="true"
            />
          </div>

          <div className="order-1 min-w-0 flex-1 sm:order-2">
            <div className="flex min-w-0 items-center gap-2">
              <p className="truncate text-[15px] font-black tracking-[-0.01em] text-white">
                Vixrex Asistan
              </p>
              <span className="hidden shrink-0 rounded-full border border-emerald-400/20 bg-emerald-400/10 px-2 py-0.5 text-[9px] font-bold text-emerald-300 sm:inline lg:hidden">
                Sahiplik modu
              </span>
            </div>
            <p className="mt-0.5 min-w-0 truncate text-[11px] font-medium text-slate-400">
              Sohbet geçmişi
            </p>
          </div>

          <div className="order-2 shrink-0 rounded-xl border border-white/10 bg-white/[0.045] px-2.5 py-1.5 text-right sm:order-3 lg:hidden">
            <p className="text-[12px] font-black leading-none text-sky-300">Aşama {asama}/3</p>
            <p className="mt-1 text-[9px] font-semibold leading-none text-slate-500">
              {rapor.doluSayisi}/{rapor.toplamSayisi} alan
            </p>
          </div>

          <button
            type="button"
            onClick={onKapat}
            className="order-3 grid h-9 w-9 shrink-0 place-items-center rounded-full border border-white/10 bg-white/[0.045] text-slate-300 transition hover:bg-white/10 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sky-400/70 sm:order-4 lg:hidden"
            aria-label="Asistanı küçült"
          >
            <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
              <path d="M6 6l12 12M18 6L6 18" strokeLinecap="round" />
            </svg>
          </button>
        </div>

        <div className="mt-3 hidden items-center gap-2 sm:flex lg:hidden">
          <div className="h-1.5 min-w-0 flex-1 overflow-hidden rounded-full bg-white/10">
            <div
              className="h-full rounded-full bg-gradient-to-r from-sky-500 to-blue-500 transition-all duration-500"
              style={{ width: `${rapor.yuzde}%` }}
            />
          </div>
          <span className="shrink-0 text-[10px] font-semibold text-slate-500">%{rapor.yuzde} hazır</span>
        </div>
      </div>

      <style jsx global>{`
        .vixrex-owner-assistant-shell {
          isolation: isolate;
          border-color: rgba(148, 163, 184, 0.18) !important;
          background: rgba(8, 15, 28, 0.975) !important;
          box-shadow:
            0 28px 80px rgba(2, 6, 23, 0.5),
            0 0 0 1px rgba(255, 255, 255, 0.025) inset !important;
          backdrop-filter: blur(20px);
          -webkit-backdrop-filter: blur(20px);
          transition: opacity 180ms ease, transform 180ms ease;
        }

        @media (max-width: 639px) {
          .vixrex-owner-assistant-shell {
            left: 0.75rem !important;
            right: 0.75rem !important;
            top: auto !important;
            bottom: calc(5.75rem + env(safe-area-inset-bottom)) !important;
            width: auto !important;
            max-height: calc(82dvh - 5rem) !important;
            border-radius: 1.5rem 1.5rem 1.25rem 1.25rem !important;
          }

          .vixrex-owner-assistant-shell[data-vixrex-mobile-details="true"] {
            bottom: max(0.75rem, env(safe-area-inset-bottom)) !important;
            max-height: min(82dvh, 760px) !important;
          }

          body.vixrex-asistan-acik
            div[aria-hidden="false"].pointer-events-none.fixed.inset-0[class~="z-[80]"] {
            display: none !important;
          }
        }

        @media (min-width: 640px) {
          .vixrex-owner-assistant-shell {
            left: auto !important;
            right: 1rem !important;
            top: 3.25rem !important;
            bottom: 1rem !important;
            width: min(420px, calc(100vw - 2rem)) !important;
            max-height: none !important;
            border-radius: 1.5rem !important;
          }
        }
      `}</style>
    </>
  );
}
