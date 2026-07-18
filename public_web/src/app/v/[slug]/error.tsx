"use client";

import { useEffect } from "react";

export default function StoreError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("Public vitrin render failed:", error);
  }, [error]);

  return (
    <main className="flex min-h-screen items-center justify-center bg-[#071322] px-6 text-white">
      <section className="w-full max-w-lg rounded-3xl border border-[#25415F] bg-[#0E1B2E] p-8 text-center shadow-2xl">
        <h1 className="text-2xl font-black">Vitrin şu anda yüklenemedi</h1>
        <p className="mt-3 text-sm font-semibold leading-6 text-[#C4D1E3]">
          Bağlantı geçici olarak kurulamadı. Biraz sonra yeniden deneyin.
        </p>
        <button
          type="button"
          onClick={() => reset()}
          className="mt-6 rounded-2xl bg-[#38A0E4] px-5 py-3 text-sm font-black text-white transition hover:opacity-90"
        >
          Tekrar dene
        </button>
      </section>
    </main>
  );
}
