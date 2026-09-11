"use client";

import { useEffect, useRef, useState } from "react";

export interface OwnerEditorBarProps {
  kaydediliyor: boolean;
  panelAcik: boolean;
  yayinlaniyor: boolean;
  yasalOnayli: boolean;
  onOnizleme: () => void;
  onAyarlar: () => void;
  onYayinla: () => void;
  onYasalOnayGerek: () => void;
}

export default function OwnerEditorBar({
  kaydediliyor,
  panelAcik,
  yayinlaniyor,
  yasalOnayli,
  onOnizleme,
  onAyarlar,
  onYayinla,
  onYasalOnayGerek,
}: OwnerEditorBarProps) {
  const [sonKayit, setSonKayit] = useState<string | null>(null);
  const oncekiKaydediliyor = useRef(kaydediliyor);

  useEffect(() => {
    if (oncekiKaydediliyor.current && !kaydediliyor) {
      const simdi = new Date();
      setSonKayit(
        `${String(simdi.getHours()).padStart(2, "0")}:${String(
          simdi.getMinutes()
        ).padStart(2, "0")}`
      );
    }
    oncekiKaydediliyor.current = kaydediliyor;
  }, [kaydediliyor]);

  const durumMetni = kaydediliyor
    ? "Kaydediliyor…"
    : sonKayit
      ? `Taslak kaydedildi ${sonKayit}`
      : "Taslak hazır";

  return (
    <header
      data-vixrex-editor-bar
      className="fixed inset-x-0 top-0 z-[80] hidden h-[var(--owner-bar-h)] items-center gap-4 border-b border-white/10 bg-[#0B1120] px-5 lg:flex"
    >
      <div className="flex min-w-0 items-center gap-3">
        <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-blue-500/15 text-blue-400">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M20.2 5.6 19 3.4a1 1 0 0 0-.9-.5H5.9a1 1 0 0 0-.9.5L3.8 5.6A3.4 3.4 0 0 0 3.4 7v.6A2.9 2.9 0 0 0 4.6 10v9a1.5 1.5 0 0 0 1.5 1.5h11.8A1.5 1.5 0 0 0 19.4 19v-9a2.9 2.9 0 0 0 1.2-2.4V7a3.4 3.4 0 0 0-.4-1.4Zm-2.8 12.9H6.6V10.4h10.8Z" />
          </svg>
        </span>
        <div className="min-w-0">
          <p className="truncate text-[14px] font-black leading-tight text-white">
            Mağaza Editörü
          </p>
          <p className="truncate text-[11px] font-semibold leading-tight text-slate-400">
            Mağazanı kolayca düzenle, değişikliklerini yayınla.
          </p>
        </div>
      </div>

      <div className="ml-auto flex items-center gap-2">
        <span className="flex items-center gap-2 rounded-full border border-white/10 px-3 py-1.5 text-[11px] font-semibold text-slate-300">
          <span
            className={`h-2 w-2 rounded-full ${
              kaydediliyor ? "bg-amber-400" : "bg-emerald-400"
            }`}
          />
          {durumMetni}
        </span>

        <button
          type="button"
          onClick={onOnizleme}
          className="rounded-xl border border-white/15 px-4 py-2 text-[12px] font-bold text-slate-100 transition-colors hover:bg-white/5"
        >
          {panelAcik ? "Önizleme" : "Düzenlemeye dön"}
        </button>

        <button
          type="button"
          onClick={yasalOnayli ? onYayinla : onYasalOnayGerek}
          disabled={yayinlaniyor}
          className="rounded-xl bg-blue-600 px-4 py-2 text-[12px] font-black text-white transition-colors hover:bg-blue-500 disabled:opacity-60"
        >
          {yayinlaniyor ? "Yayınlanıyor…" : "Yayınla"}
        </button>

        <button
          type="button"
          onClick={onAyarlar}
          aria-label="Tüm alanlar"
          className="flex h-9 w-9 items-center justify-center rounded-xl border border-white/15 text-slate-300 transition-colors hover:bg-white/5"
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8Zm0 6a2 2 0 1 1 0-4 2 2 0 0 1 0 4Zm8.4-1.1.1-.9-.1-.9 1.7-1.3a.5.5 0 0 0 .1-.6l-1.6-2.8a.5.5 0 0 0-.6-.2l-2 .8a6.7 6.7 0 0 0-1.5-.9l-.3-2.1a.5.5 0 0 0-.5-.4h-3.2a.5.5 0 0 0-.5.4l-.3 2.1c-.5.2-1 .5-1.5.9l-2-.8a.5.5 0 0 0-.6.2L5.4 9.2a.5.5 0 0 0 .1.6l1.7 1.3-.1.9.1.9-1.7 1.3a.5.5 0 0 0-.1.6l1.6 2.8c.1.2.4.3.6.2l2-.8c.5.4 1 .7 1.5.9l.3 2.1c0 .2.2.4.5.4h3.2c.3 0 .5-.2.5-.4l.3-2.1c.5-.2 1-.5 1.5-.9l2 .8c.2.1.5 0 .6-.2l1.6-2.8a.5.5 0 0 0-.1-.6l-1.7-1.3Z" />
          </svg>
        </button>
      </div>
    </header>
  );
}
