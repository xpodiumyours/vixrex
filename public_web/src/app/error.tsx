"use client";

import { useEffect } from "react";

// Kök hata sınırı (W4 · madde 20): kendi error.tsx'i olmayan her segmentte
// Supabase/API/AI çökmesi beyaz ekran yerine bu profesyonel ekrana düşer.
// Kendi sınırı olanlar (kesfet, v/[slug]) kendi ekranını kullanır.
export default function RootError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("Sayfa yüklenemedi:", error);
  }, [error]);

  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-50 px-6 text-slate-900">
      <section className="w-full max-w-lg rounded-3xl border border-slate-200 bg-white p-8 text-center shadow-xl">
        <h1 className="text-2xl font-black">Bir şeyler ters gitti</h1>
        <p className="mt-3 text-sm font-semibold leading-6 text-slate-500">
          Sayfa şu anda yüklenemedi. Bağlantı geçici olarak kesilmiş olabilir —
          biraz sonra yeniden deneyin.
        </p>
        <button
          type="button"
          onClick={() => reset()}
          className="mt-6 rounded-2xl bg-blue-600 px-5 py-3 text-sm font-black text-white transition hover:bg-blue-700"
        >
          Tekrar dene
        </button>
      </section>
    </main>
  );
}
