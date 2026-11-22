"use client";

import { useRef, type PointerEvent as ReactPointerEvent } from "react";
import { VixrexAvatar } from "./VixrexAvatar";
import { PublishBar } from "./PublishBar";
import { GoogleOlcumKarti } from "./GoogleOlcumKarti";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

export interface YayinDegerleri {
  yayinlaniyor: boolean;
  yayinla: () => Promise<void>;
  yasalOnayli: boolean;
  onayVeriliyor: boolean;
  onayVer: (beyanlar: { privacyAcknowledged: boolean; termsAccepted: boolean; publicationConsent: boolean }) => Promise<boolean>;
  temelTamam: boolean;
  eksikTemelSayisi: number;
  kiralikVitrinMi: boolean;
  premiumAktifMi: boolean;
  silmeOnayi: boolean;
  sil: () => Promise<void>;
  silmeOnayla: () => void;
  setSilmeOnayi: (v: boolean) => void;
  durumMetni?: string;
}

interface Props {
  rapor: HazirlikRaporu;
  onKapat: () => void;
  yayin?: YayinDegerleri;
}

// Sahiplik sayfasındaki Vixrex Asistan kabuğunun tek başlığı.
// Mobilde bu başlık yalnız çekmece yukarı açıldığında görünür; günlük
// kullanım yüzeyi alttaki compact composer'dır. Maskot telefonda ve
// masaüstü sağ sütunda SAĞDA kalır; tabletin mevcut yüzen paneli korunur.
export function ChatTopBar({ rapor, onKapat, yayin }: Props) {
  const mobilTutamakRef = useRef<number | null>(null);

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
      <div className="relative shrink-0 border-b border-white/10 bg-[linear-gradient(180deg,rgba(20,32,54,0.98),rgba(10,17,30,0.98))] px-3.5 py-2.5">
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
          className="mx-auto mb-1.5 flex h-2 w-12 touch-none select-none items-center justify-center sm:hidden"
        >
          <span className="h-0.5 w-8 rounded-full bg-white/20" />
        </div>

        <div className="flex items-center justify-between gap-2">
          {/* Sol: Maskot & Başlık */}
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="order-4 relative shrink-0 sm:order-1 lg:order-4">
              <VixrexAvatar size={38} halo decorative />
              <span
                className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full border-2 border-[#0b111e] bg-emerald-400"
                aria-hidden="true"
              />
            </div>

            <div className="order-1 min-w-0 flex-1 sm:order-2 lg:order-1">
              <div className="flex items-center gap-1.5">
                <p className="shrink-0 text-xs font-black tracking-[-0.01em] text-white">
                  Vixrex Asistan
                </p>
              </div>
              <p className="truncate text-[10px] text-slate-400 flex items-center gap-1 mt-0.5">
                <span className="inline-block h-1.5 w-1.5 shrink-0 rounded-full bg-emerald-400" />
                <span className="truncate">{yayin?.durumMetni || "Vitrinin yayındaki hâliyle aynı."}</span>
              </p>
            </div>
          </div>

          {/* Sağ: Kompakt Yayın Barı & Kapat */}
          <div className="flex items-center gap-1.5 shrink-0">
            <GoogleOlcumKarti />
            {yayin ? <PublishBar {...yayin} yuzde={rapor.yuzde} /> : null}

            <button
              type="button"
              onClick={onKapat}
              className="grid h-7 w-7 place-items-center rounded-lg border border-white/10 bg-white/[0.045] text-slate-400 transition hover:bg-white/10 hover:text-white focus-visible:outline-none lg:hidden"
              aria-label="Asistanı küçült"
            >
              <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                <path d="M6 6l12 12M18 6L6 18" strokeLinecap="round" />
              </svg>
            </button>
          </div>
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

        @media (min-width: 640px) and (max-width: 1023px) {
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
