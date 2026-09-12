"use client";

import { useState } from "react";

export function BlogPaylas({ baslik }: { baslik: string }) {
  const [durum, setDurum] = useState("");

  async function baglantiyiKopyala() {
    try {
      await navigator.clipboard.writeText(window.location.href);
      setDurum("Bağlantı kopyalandı.");
    } catch {
      setDurum("Bağlantı kopyalanamadı.");
    }
  }

  async function paylas() {
    if (!navigator.share) {
      await baglantiyiKopyala();
      return;
    }

    try {
      await navigator.share({ title: baslik, url: window.location.href });
      setDurum("");
    } catch (hata) {
      if (hata instanceof DOMException && hata.name === "AbortError") return;
      setDurum("Paylaşım açılamadı.");
    }
  }

  return (
    <div className="mt-6 flex flex-wrap items-center gap-2" aria-label="Yazıyı paylaş">
      <button
        type="button"
        onClick={paylas}
        className="inline-flex min-h-11 items-center rounded-full border border-lp-border bg-lp-surface px-4 text-sm font-bold text-lp-text outline-none hover:border-lp-secondary hover:text-lp-secondary focus-visible:ring-2 focus-visible:ring-lp-secondary"
      >
        Paylaş
      </button>
      <button
        type="button"
        onClick={baglantiyiKopyala}
        className="inline-flex min-h-11 items-center rounded-full px-4 text-sm font-bold text-lp-secondary outline-none hover:text-lp-text focus-visible:ring-2 focus-visible:ring-lp-secondary"
      >
        Bağlantıyı kopyala
      </button>
      <span className="text-xs font-semibold text-lp-muted" role="status" aria-live="polite">
        {durum}
      </span>
    </div>
  );
}
