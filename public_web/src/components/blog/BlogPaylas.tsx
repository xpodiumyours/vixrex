"use client";

import { useState } from "react";

export function BlogPaylas({ baslik }: { baslik: string }) {
  const [durum, setDurum] = useState("");
  async function kopyala() {
    try {
      await navigator.clipboard.writeText(window.location.href.split("#")[0]);
      setDurum("Bağlantı kopyalandı.");
    } catch {
      setDurum(
        "Bağlantı kopyalanamadı. Tarayıcının adres çubuğundan kopyalayabilirsin.",
      );
    }
  }
  async function paylas() {
    if (!navigator.share) {
      await kopyala();
      return;
    }
    try {
      await navigator.share({
        title: baslik,
        url: window.location.href.split("#")[0],
      });
    } catch (hata) {
      if (!(hata instanceof Error && hata.name === "AbortError"))
        setDurum("Paylaşım açılamadı. Bağlantıyı kopyalayabilirsin.");
    }
  }
  return (
    <div className="mt-6 flex flex-wrap items-center gap-x-5 gap-y-2 text-sm text-lp-secondary">
      <button
        type="button"
        onClick={paylas}
        className="min-h-11 rounded font-semibold outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary"
      >
        Paylaş ↗
      </button>
      <button
        type="button"
        onClick={kopyala}
        className="min-h-11 rounded font-semibold outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary"
      >
        Bağlantıyı kopyala
      </button>
      <span role="status" className="text-lp-muted">
        {durum}
      </span>
    </div>
  );
}
