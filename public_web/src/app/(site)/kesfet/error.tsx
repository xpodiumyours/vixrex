"use client";

import { useEffect } from "react";

export default function KesfetHata({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("[kesfet] sayfa yüklenemedi:", error);
  }, [error]);

  return (
    <div className="px-6 py-12">
      <div className="mx-auto w-full max-w-[1200px] rounded-2xl border border-red-400/40 bg-red-400/10 px-5 py-8 text-center">
        <h1 className="text-[20px] font-black text-lp-text">
          Vitrinler yüklenemedi
        </h1>
        <p className="mt-2 text-[13px] font-semibold text-lp-muted">
          Bağlantınızı kontrol edip tekrar deneyin.
        </p>
        <button
          type="button"
          onClick={reset}
          className="mt-4 rounded-xl border border-lp-border bg-lp-surface px-4 py-2 text-[12px] font-black text-lp-text-alt"
        >
          Tekrar dene
        </button>
      </div>
    </div>
  );
}
