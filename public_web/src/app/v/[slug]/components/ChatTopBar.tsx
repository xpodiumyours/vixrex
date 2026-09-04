"use client";

import { useEffect, useRef } from "react";
import { VixrexAvatar } from "./VixrexAvatar";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

interface Props {
  rapor: HazirlikRaporu;
  onKapat: () => void;
}

// Sahiplik sayfasındaki Vixrex Asistan kabuğunun tek başlığı.
// Bu bileşen yalnız OwnerAssistantPanel içinde kullanılır. Parent kabuğa
// yerel bir class ekleyerek masaüstünde sağ çekmece, mobilde bottom-sheet
// görünümü verir; Keşfet/public vitrin/global layout davranışına dokunmaz.
export function ChatTopBar({ rapor, onKapat }: Props) {
  const rootRef = useRef<HTMLDivElement>(null);
  const asama = rapor.yuzde < 34 ? 1 : rapor.yuzde < 67 ? 2 : 3;

  useEffect(() => {
    const shell = rootRef.current?.parentElement;
    if (!shell) return;

    shell.classList.add("vixrex-owner-assistant-shell");
    return () => shell.classList.remove("vixrex-owner-assistant-shell");
  }, []);

  const kapat = () => {
    onKapat();

    // OwnerAssistantPanel'ın eski mobil davranışında başlıktaki X yalnız
    // `haritaAcik` state'ini kapatıyor, `acik` state'ini kapatmıyordu. Bu
    // nedenle X ekranda hiçbir şey yapmıyormuş gibi kalıyordu. Parent iş
    // akışını değiştirmeden, yalnız mobilde mevcut canonical Vixrex
    // tetikleyicisini programatik olarak kapalı duruma geçiriyoruz. Böylece
    // aynı toggle yolu kullanılır; ikinci bir açık/kapalı state üretilmez.
    if (
      typeof window !== "undefined" &&
      !window.matchMedia("(min-width: 640px)").matches
    ) {
      window.requestAnimationFrame(() => {
        const tetik = document.querySelector<HTMLButtonElement>(
          'button[aria-label="Vixrex Asistan"][aria-expanded="true"]',
        );
        tetik?.click();
      });
    }
  };

  return (
    <>
      <div
        ref={rootRef}
        className="relative shrink-0 border-b border-white/10 bg-[linear-gradient(180deg,rgba(24,37,63,0.96),rgba(11,17,32,0.96))] px-4 pb-3 pt-2.5 sm:pt-3"
      >
        <div className="mx-auto mb-2 h-1 w-10 rounded-full bg-white/25 sm:hidden" aria-hidden="true" />

        <div className="flex items-center gap-3">
          <div className="relative shrink-0">
            <VixrexAvatar size={38} halo decorative />
            <span
              className="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-[#111b2d] bg-emerald-400"
              aria-hidden="true"
            />
          </div>

          <div className="min-w-0 flex-1">
            <div className="flex min-w-0 items-center gap-2">
              <p className="truncate text-[15px] font-black tracking-[-0.01em] text-white">
                Vixrex Asistan
              </p>
              <span className="hidden shrink-0 rounded-full border border-emerald-400/20 bg-emerald-400/10 px-2 py-0.5 text-[9px] font-bold text-emerald-300 sm:inline">
                Sahiplik modu
              </span>
            </div>
            <p className="mt-0.5 truncate text-[11px] font-medium text-slate-400">
              Vitrin düzenleme
              <span className="mx-1.5 text-slate-600">·</span>
              <span className="text-emerald-300">Çevrimiçi</span>
            </p>
          </div>

          <div className="shrink-0 rounded-xl border border-white/10 bg-white/[0.045] px-2.5 py-1.5 text-right">
            <p className="text-[12px] font-black leading-none text-sky-300">Aşama {asama}/3</p>
            <p className="mt-1 text-[9px] font-semibold leading-none text-slate-500">
              {rapor.doluSayisi}/{rapor.toplamSayisi} alan
            </p>
          </div>

          <button
            type="button"
            onClick={kapat}
            className="grid h-9 w-9 shrink-0 place-items-center rounded-full border border-white/10 bg-white/[0.045] text-slate-300 transition hover:bg-white/10 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sky-400/70"
            aria-label="Asistanı kapat"
          >
            <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
              <path d="M6 6l12 12M18 6L6 18" strokeLinecap="round" />
            </svg>
          </button>
        </div>

        <div className="mt-3 flex items-center gap-2">
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
        }

        body.vixrex-asistan-acik
          button[aria-label="Vixrex Asistan"][aria-expanded="true"] {
          opacity: 0;
          pointer-events: none;
          transform: translateY(6px) scale(0.92);
        }

        @media (max-width: 639px) {
          .vixrex-owner-assistant-shell {
            left: 0.75rem !important;
            right: 0.75rem !important;
            top: auto !important;
            bottom: max(0.75rem, env(safe-area-inset-bottom)) !important;
            width: auto !important;
            max-height: min(82dvh, 760px) !important;
            border-radius: 1.5rem 1.5rem 1.25rem 1.25rem !important;
          }

          /* Mobilde sohbet alanı sabit başlık/Sırada/composer arasında sıfıra
           * kadar eziliyordu. Mesaj state'i doğru çalışsa bile kullanıcı
           * gönderdiğini göremiyordu. Sohbete gerçek bir minimum görünür alan
           * ayırıyoruz; taşan mesajlar kendi mevcut scroll alanında kalır. */
          .vixrex-owner-assistant-shell > .vixrex-panel-kaydirici {
            min-height: 8.5rem !important;
            flex: 1 1 8.5rem !important;
          }

          /* Mobilde eski dolaşan SpotlightGuide ile yeni bottom-sheet aynı
           * anda çizilince kullanıcı iki ayrı düzenleme yüzeyi görüyordu.
           * Sheet artık mobilde TEK düzenleme yüzeyi; eski halka/balon yalnız
           * masaüstünde kalır. Bu selector SpotlightGuide'ın mevcut kökünü
           * hedefler ve sahiplik dışı hiçbir ekranı etkilemez. */
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
