"use client";

import { useCallback, useLayoutEffect, useState } from "react";
import type { VitrinField } from "@/lib/vitrinFieldSchema";
import { SECTION_LABELS } from "@/lib/vitrinFieldSchema";
import { alanOnemi, type EksikOnem } from "@/lib/vitrinReadiness";
import { VixrexAvatar } from "./VixrexAvatar";

// 2026-08-22: "esnaf tıkladığında yan panelde form açılmasın, oyunlardaki
// gibi ok/spot ışığıyla sayfada dolaşsın" isteği — sıralama mantığı
// (önce zorunlu, sonra kalite alanları) zaten vitrinReadiness.ts'te vardı
// (tumAlanlarSirali/sonrakiRehberAlanlar), alan seçme/vurgulama/kaydırma
// zaten useFieldSelection'da vardı. Burada yalnız eksik olan görsel katman
// eklendi: seçili alanın sayfadaki gerçek konumunu bulup etrafına spot
// ışığı + yanına ok/balon çizer. Hiçbir seçim/sıralama mantığı burada
// tekrar yazılmadı.

interface Rect {
  top: number;
  left: number;
  width: number;
  height: number;
}

const ONEM_METNI: Record<EksikOnem, { yazi: string; sinif: string; neden: string }> = {
  temel: {
    yazi: "Zorunlu",
    sinif: "bg-red-500/15 text-red-300 border-red-400/30",
    neden: "Bu alan dolmadan vitrinin yayınlanamaz.",
  },
  kalite: {
    yazi: "Kalite",
    sinif: "bg-sky-500/15 text-sky-300 border-sky-400/30",
    neden: "Zorunlu değil ama vitrinini daha güçlü gösterir.",
  },
  "istege-bagli": {
    yazi: "İsteğe bağlı",
    sinif: "bg-white/10 text-slate-400 border-white/15",
    neden: "İstersen boş bırakabilirsin.",
  },
};

interface Props {
  seciliAlan: VitrinField | null;
  girisRef: React.RefObject<HTMLTextAreaElement | null>;
  onSonrayaBirak?: () => void;
  onKapat: () => void;
}

/** Sayfada gezen spot ışığı + ok/balon rehberi — panel açıkken, bir alan
 * seçiliyken görünür. Panelin kendisinin yerine değil, üstüne çalışır. */
export function SpotlightGuide({
  seciliAlan,
  girisRef,
  onSonrayaBirak,
  onKapat,
}: Props) {
  const [rect, setRect] = useState<Rect | null>(null);
  const [viewport, setViewport] = useState<{ w: number; h: number } | null>(null);

  const konumuGuncelle = useCallback(() => {
    if (!seciliAlan) {
      setRect(null);
      return;
    }
    const hedef = document.querySelector(
      `[data-vixrex-editable="${seciliAlan.anahtar}"]`,
    );
    if (!hedef) {
      setRect(null);
      return;
    }
    const r = hedef.getBoundingClientRect();
    setRect({ top: r.top, left: r.left, width: r.width, height: r.height });
    setViewport({ w: window.innerWidth, h: window.innerHeight });
  }, [seciliAlan]);

  // useLayoutEffect: hedefin gerçek DOM konumunu ölçüp boyayamadan önce
  // state'e yazmak için. useOwnerDraft.ts'teki "render sırasında ayarla"
  // deseni burada UYGULANAMAZ — bu React prop'undan değil, gerçek DOM
  // layout'undan (getBoundingClientRect) türetilen bir değer; DOM önce
  // commit edilmeden ölçülemez. React'in kendi dokümanı useLayoutEffect'i
  // tam bu senaryo için önerir ("measure a DOM node before the browser
  // repaints"), bu yüzden kural burada bilerek atlanıyor.
  useLayoutEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    konumuGuncelle();
    window.addEventListener("scroll", konumuGuncelle, true);
    window.addEventListener("resize", konumuGuncelle);
    // scrollIntoView({behavior:"smooth"}) anlık bitmiyor — kayma sürerken
    // de balonun hedefi takip etmesi için kısa bir süre tekrar hesaplanır.
    const zamanlayici = window.setInterval(konumuGuncelle, 120);
    const durdur = window.setTimeout(
      () => window.clearInterval(zamanlayici),
      700,
    );
    return () => {
      window.removeEventListener("scroll", konumuGuncelle, true);
      window.removeEventListener("resize", konumuGuncelle);
      window.clearInterval(zamanlayici);
      window.clearTimeout(durdur);
    };
  }, [konumuGuncelle]);

  if (!seciliAlan || !rect || !viewport) return null;

  const onem = alanOnemi(seciliAlan);
  const bilgi = ONEM_METNI[onem];
  const balonGenislik = Math.min(320, viewport.w - 32);
  const asagidaYerVar = rect.top < viewport.h * 0.55;
  const balonSol = Math.min(
    Math.max(rect.left, 16),
    viewport.w - balonGenislik - 16,
  );

  return (
    <div className="pointer-events-none fixed inset-0 z-[80]" aria-hidden={false}>
      {/* Spot ışığı: hedefin dışı karartılır, kendisi delik gibi açık kalır. */}
      <div
        className="pointer-events-none absolute rounded-2xl ring-2 ring-blue-400/70 transition-all duration-300 ease-out"
        style={{
          top: rect.top - 8,
          left: rect.left - 8,
          width: rect.width + 16,
          height: rect.height + 16,
          boxShadow: "0 0 0 9999px rgba(3, 7, 18, 0.74)",
        }}
      />
      {/* Ok + balon */}
      <div
        className="pointer-events-auto absolute flex flex-col gap-3 rounded-2xl border border-blue-400/30 bg-[#0B1120] p-4 shadow-2xl transition-all duration-300 ease-out"
        style={{
          width: balonGenislik,
          left: balonSol,
          top: asagidaYerVar ? rect.top + rect.height + 18 : undefined,
          bottom: asagidaYerVar ? undefined : viewport.h - rect.top + 18,
        }}
      >
        {/* Hedefi gösteren ok */}
        <div
          className={`absolute h-3 w-3 rotate-45 border border-blue-400/30 bg-[#0B1120] ${
            asagidaYerVar ? "-top-1.5 border-b-0 border-r-0" : "-bottom-1.5 border-t-0 border-l-0"
          }`}
          style={{ left: Math.min(Math.max(rect.left - balonSol + rect.width / 2 - 6, 12), balonGenislik - 24) }}
        />

        <div className="flex items-start gap-2.5">
          <VixrexAvatar size={26} decorative />
          <div className="flex-1">
            <div className="mb-1 flex items-center gap-2">
              <span
                className={`rounded-full border px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide ${bilgi.sinif}`}
              >
                {bilgi.yazi}
              </span>
              <span className="text-[11px] text-slate-500">
                {SECTION_LABELS[seciliAlan.bolum]}
              </span>
            </div>
            <p className="text-[15px] font-extrabold text-white">
              {seciliAlan.etiket}
            </p>
            <p className="mt-1 text-[13px] leading-relaxed text-slate-400">
              {bilgi.neden}
              {seciliAlan.ipucu ? ` ${seciliAlan.ipucu}` : ""}
            </p>
          </div>
          <button
            type="button"
            onClick={onKapat}
            aria-label="Rehberi kapat"
            className="shrink-0 rounded-full p-1 text-slate-500 hover:bg-white/5 hover:text-slate-300"
          >
            ✕
          </button>
        </div>

        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => girisRef.current?.focus()}
            className="flex-1 rounded-xl bg-gradient-to-r from-blue-600 to-blue-700 px-3 py-2 text-[13px] font-bold text-white shadow shadow-blue-500/30"
          >
            Buraya yaz
          </button>
          {onem !== "temel" && onSonrayaBirak && (
            <button
              type="button"
              onClick={onSonrayaBirak}
              className="rounded-xl border border-white/10 px-3 py-2 text-[13px] font-semibold text-slate-400 hover:text-slate-200"
            >
              Sonra
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
