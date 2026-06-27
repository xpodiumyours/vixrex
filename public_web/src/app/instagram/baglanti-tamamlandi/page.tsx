"use client";

import { useEffect } from "react";

export default function InstagramConnectionCompletePage() {
  useEffect(() => {
    const timeout = window.setTimeout(() => window.close(), 1200);
    return () => window.clearTimeout(timeout);
  }, []);

  return (
    <main className="flex min-h-screen items-center justify-center bg-[#071525] px-5 text-white">
      <section className="w-full max-w-sm text-center">
        <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-[#0ea8b0] text-2xl font-bold">
          ✓
        </div>
        <h1 className="mt-5 text-2xl font-bold">Instagram bağlandı</h1>
        <p className="mt-2 text-sm leading-6 text-[#b9c7d6]">
          VitrinX uygulamasına dönerek fotoğraflarınızı seçebilirsiniz.
        </p>
        <button
          type="button"
          onClick={() => window.close()}
          className="mt-6 inline-flex h-11 items-center justify-center rounded-lg border border-[#29435a] px-5 text-sm font-semibold text-white"
        >
          Pencereyi kapat
        </button>
      </section>
    </main>
  );
}
