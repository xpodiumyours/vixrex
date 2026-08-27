"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

export const dynamic = "force-dynamic";

export default function GirisPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [sifre, setSifre] = useState("");
  const [hata, setHata] = useState("");
  const [gonderiliyor, setGonderiliyor] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setHata("");

    if (!email.trim() || !sifre) {
      setHata("E-posta ve şifre zorunludur.");
      return;
    }

    setGonderiliyor(true);
    const { error } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password: sifre,
    });
    setGonderiliyor(false);

    if (error) {
      setHata(
        error.message === "Invalid login credentials"
          ? "E-posta veya şifre hatalı."
          : error.message || "Giriş yapılamadı. Lütfen tekrar dene."
      );
      return;
    }

    router.push("/app");
    router.refresh();
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-[#0c0d10] px-4 py-10 text-[#f4f1ea]">
      <div className="w-full max-w-sm rounded-2xl border border-white/8 bg-[#15171c] p-6">
        <h1 className="mb-1 text-lg font-bold">Giriş Yap</h1>
        <p className="mb-5 text-sm text-white/50">
          Vixrex hesabınla giriş yap.
        </p>

        <form onSubmit={handleSubmit} className="flex flex-col gap-3">
          <input
            type="email"
            placeholder="E-posta"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="rounded-xl border border-white/10 bg-[#0c0d10] px-3 py-2.5 text-sm outline-none focus:border-blue-500"
            autoComplete="email"
            required
          />
          <input
            type="password"
            placeholder="Şifre"
            value={sifre}
            onChange={(e) => setSifre(e.target.value)}
            className="rounded-xl border border-white/10 bg-[#0c0d10] px-3 py-2.5 text-sm outline-none focus:border-blue-500"
            autoComplete="current-password"
            required
          />

          {hata && <p className="text-xs text-red-400">{hata}</p>}

          <button
            type="submit"
            disabled={gonderiliyor}
            className="mt-1 rounded-xl bg-gradient-to-r from-blue-600 to-blue-700 py-2.5 text-sm font-bold text-white shadow-md transition hover:shadow-blue-500/30 disabled:opacity-60"
          >
            {gonderiliyor ? "Giriş yapılıyor…" : "Giriş Yap"}
          </button>
        </form>

        <div className="mt-4 flex items-center justify-between text-xs text-white/40">
          <Link href="/kayit" className="hover:text-white/70">
            Hesabın yok mu? Kayıt ol
          </Link>
          <Link href="/sifre-sifirla" className="hover:text-white/70">
            Şifremi unuttum
          </Link>
        </div>
      </div>
    </main>
  );
}
