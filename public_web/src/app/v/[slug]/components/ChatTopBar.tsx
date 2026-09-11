"use client";

import { useEffect, useRef, useState } from "react";
import { VixrexAvatar } from "./VixrexAvatar";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

interface Props {
  rapor: HazirlikRaporu;
  onKapat: () => void;
}

// Sahiplik sayfasındaki Vixrex Asistan kabuğunun tek başlığı.
// Mobil kural: asistan yalnız bilgi isterken alan kaplar. Kayıt gerçekten
// başladığında mevcut owner state'ini bozmadan sheet görsel olarak çekilir;
// canonical Vixrex düğmesi "Düzenleniyor" / "Düzenlendi" geri bildirimi
// verir. Kayıt hatasında sheet tekrar görünür. Mesaj geçmişi varsayılan olarak
// son iki mesaja daraltılır; "Geçmiş" ile tamamı açılır.
export function ChatTopBar({ rapor, onKapat }: Props) {
  const rootRef = useRef<HTMLDivElement>(null);
  const durumTimerRef = useRef<number | null>(null);
  const kayitSuruyorRef = useRef(false);
  const [gecmisAcik, setGecmisAcik] = useState(false);
  const asama = rapor.yuzde < 34 ? 1 : rapor.yuzde < 67 ? 2 : 3;

  useEffect(() => {
    const shell = rootRef.current?.parentElement;
    if (!shell) return;

    shell.classList.add("vixrex-owner-assistant-shell");
    let mesajSayisiBaslangic = 0;

    const canonicalTetik = () =>
      document.querySelector<HTMLButtonElement>('button[aria-label^="Vixrex Asistan"]');

    const tetikDurumunuTemizle = () => {
      const tetik = canonicalTetik();
      if (!tetik) return;
      tetik.removeAttribute("data-vixrex-status");
      tetik.setAttribute("aria-label", "Vixrex Asistan");
    };

    const yeniMesajlarinDurumu = (): "basarili" | "hata" | "belirsiz" => {
      const tumMesajlar = Array.from(
        shell.querySelectorAll<HTMLElement>(".vixrex-panel-kaydirici > *"),
      );
      const yeniMesajlar = tumMesajlar.slice(mesajSayisiBaslangic);
      const metin = yeniMesajlar
        .map((oge) => oge.textContent ?? "")
        .join("\n")
        .toLocaleLowerCase("tr-TR");

      // Hata/kararsızlık başarıdan önce değerlendirilir. Böylece aynı kayıt
      // turunda önceki bir başarı metni kalsa bile yanlış "Düzenlendi" denmez.
      if (
        /kaydedemedim|kaydedilemedi|bağlantı kurulamadı|tekrar dene|birden fazla bilgi|sadece onu yazar mısın/.test(
          metin,
        )
      ) {
        return "hata";
      }
      if (/güncellendi|kaydettim|kaydedildi|dolduruldu/.test(metin)) {
        return "basarili";
      }
      return "belirsiz";
    };

    const kayitDurumunuSenkronla = () => {
      if (window.matchMedia("(min-width: 640px)").matches) return;
      const kaydediliyor = document.body.classList.contains("vixrex-kaydediliyor");

      if (kaydediliyor && !kayitSuruyorRef.current) {
        kayitSuruyorRef.current = true;
        mesajSayisiBaslangic = shell.querySelectorAll(
          ".vixrex-panel-kaydirici > *",
        ).length;
        shell.classList.add("vixrex-assistant-compact");
        const tetik = canonicalTetik();
        if (tetik) {
          tetik.dataset.vixrexStatus = "saving";
          tetik.setAttribute("aria-label", "Vixrex Asistan — düzenleniyor");
        }
        return;
      }

      if (!kaydediliyor && kayitSuruyorRef.current) {
        kayitSuruyorRef.current = false;
        // React mesaj state'i ve vitrin taslağı aynı turda güncelleniyor.
        // Yalnız bu kayıt turunda eklenen balonları okumadan önce DOM'un o
        // turu tamamlamasına izin ver.
        window.setTimeout(() => {
          const sonuc = yeniMesajlarinDurumu();
          const tetik = canonicalTetik();

          // Emin olmadığımız veya hata olan durumda başarı uydurmayız;
          // asistan açılır ve gerçek son mesajı kullanıcı görür.
          if (sonuc !== "basarili") {
            shell.classList.remove("vixrex-assistant-compact");
            tetikDurumunuTemizle();
            return;
          }

          if (tetik) {
            tetik.dataset.vixrexStatus = "saved";
            tetik.setAttribute("aria-label", "Vixrex Asistan — düzenlendi");
          }

          if (durumTimerRef.current !== null) {
            window.clearTimeout(durumTimerRef.current);
          }
          durumTimerRef.current = window.setTimeout(() => {
            // Canonical toggle üzerinden gerçekten kapat: ikinci bir açık/kapalı
            // state üretmeyelim. Sonraki dokunuş aynı konuşmayı geri açar.
            const guncelTetik = canonicalTetik();
            if (guncelTetik?.getAttribute("aria-expanded") === "true") {
              guncelTetik.click();
            }
            tetikDurumunuTemizle();
          }, 1400);
        }, 120);
      }
    };

    const observer = new MutationObserver(kayitDurumunuSenkronla);
    observer.observe(document.body, { attributes: true, attributeFilter: ["class"] });
    kayitDurumunuSenkronla();

    return () => {
      observer.disconnect();
      shell.classList.remove(
        "vixrex-owner-assistant-shell",
        "vixrex-assistant-compact",
        "vixrex-gecmis-acik",
      );
      tetikDurumunuTemizle();
      if (durumTimerRef.current !== null) {
        window.clearTimeout(durumTimerRef.current);
      }
    };
  }, []);

  useEffect(() => {
    const shell = rootRef.current?.parentElement;
    if (!shell) return;
    shell.classList.toggle("vixrex-gecmis-acik", gecmisAcik);
    return () => shell.classList.remove("vixrex-gecmis-acik");
  }, [gecmisAcik]);

  const kapat = () => {
    onKapat();

    if (
      typeof window !== "undefined" &&
      !window.matchMedia("(min-width: 640px)").matches
    ) {
      window.requestAnimationFrame(() => {
        const tetik = document.querySelector<HTMLButtonElement>(
          'button[aria-label^="Vixrex Asistan"][aria-expanded="true"]',
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
              <span className="hidden shrink-0 rounded-full border border-emerald-400/20 bg-emerald-400/10 px-2 py-0.5 text-[9px] font-bold text-emerald-300 sm:inline lg:hidden">
                Sahiplik modu
              </span>
            </div>
            <div className="mt-0.5 flex items-center gap-2">
              <p className="min-w-0 truncate text-[11px] font-medium text-slate-400">
                Yeni müşterilere ulaşman konusunda sana yardımcı olur.
              </p>
              <button
                type="button"
                onClick={() => setGecmisAcik((v) => !v)}
                className="shrink-0 text-[10px] font-bold text-sky-300 underline decoration-dotted underline-offset-2 sm:hidden"
                aria-pressed={gecmisAcik}
              >
                {gecmisAcik ? "Son mesajlar" : "Geçmiş"}
              </button>
            </div>
          </div>

          <div className="shrink-0 rounded-xl border border-white/10 bg-white/[0.045] px-2.5 py-1.5 text-right lg:hidden">
            <p className="text-[12px] font-black leading-none text-sky-300">Aşama {asama}/3</p>
            <p className="mt-1 text-[9px] font-semibold leading-none text-slate-500">
              {rapor.doluSayisi}/{rapor.toplamSayisi} alan
            </p>
          </div>

          <button
            type="button"
            onClick={kapat}
            className="grid h-9 w-9 shrink-0 place-items-center rounded-full border border-white/10 bg-white/[0.045] text-slate-300 transition hover:bg-white/10 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sky-400/70 lg:hidden"
            aria-label="Asistanı kapat"
          >
            <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
              <path d="M6 6l12 12M18 6L6 18" strokeLinecap="round" />
            </svg>
          </button>
        </div>

        <div className="mt-3 flex items-center gap-2 lg:hidden">
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

        body.vixrex-asistan-acik
          button[aria-label^="Vixrex Asistan"][aria-expanded="true"]:not([data-vixrex-status]) {
          opacity: 0;
          pointer-events: none;
          transform: translateY(6px) scale(0.92);
        }

        body.vixrex-asistan-acik button[data-vixrex-status] {
          opacity: 1 !important;
          transform: none !important;
          min-width: 9.5rem;
          justify-content: center;
        }

        body.vixrex-asistan-acik button[data-vixrex-status] > * {
          display: none !important;
        }

        body.vixrex-asistan-acik button[data-vixrex-status]::before,
        body.vixrex-asistan-acik button[data-vixrex-status]::after {
          display: inline-block;
        }

        body.vixrex-asistan-acik button[data-vixrex-status="saving"] {
          pointer-events: none;
        }

        body.vixrex-asistan-acik button[data-vixrex-status="saving"]::before {
          content: "";
          width: 0.9rem;
          height: 0.9rem;
          margin-right: 0.5rem;
          border: 2px solid rgba(255, 255, 255, 0.35);
          border-top-color: white;
          border-radius: 999px;
          animation: vixrex-assistant-spin 700ms linear infinite;
        }

        body.vixrex-asistan-acik button[data-vixrex-status="saving"]::after {
          content: "Düzenleniyor…";
          font-size: 0.78rem;
          font-weight: 800;
        }

        body.vixrex-asistan-acik button[data-vixrex-status="saved"]::before {
          content: "✓";
          margin-right: 0.45rem;
          font-size: 0.9rem;
          font-weight: 900;
        }

        body.vixrex-asistan-acik button[data-vixrex-status="saved"]::after {
          content: "Düzenlendi";
          font-size: 0.78rem;
          font-weight: 800;
        }

        @keyframes vixrex-assistant-spin {
          to { transform: rotate(360deg); }
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

          .vixrex-owner-assistant-shell.vixrex-assistant-compact {
            opacity: 0 !important;
            pointer-events: none !important;
            transform: translateY(18px) scale(0.96) !important;
          }

          /* Varsayılan mobil konuşma yalnız bağlam için gereken son iki
           * mesajı gösterir. Kalıcı konuşma silinmez; Geçmiş düğmesi aynı
           * DOM'daki tüm mesajları tekrar görünür yapar. */
          .vixrex-owner-assistant-shell:not(.vixrex-gecmis-acik)
            > .vixrex-panel-kaydirici {
            min-height: 0 !important;
            max-height: 9rem !important;
            flex: 0 1 auto !important;
          }

          .vixrex-owner-assistant-shell:not(.vixrex-gecmis-acik)
            > .vixrex-panel-kaydirici
            > *:not(:nth-last-child(-n + 2)) {
            display: none !important;
          }

          .vixrex-owner-assistant-shell.vixrex-gecmis-acik
            > .vixrex-panel-kaydirici {
            min-height: 8.5rem !important;
            max-height: 38dvh !important;
            flex: 1 1 8.5rem !important;
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
