"use client";

import { useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

export const dynamic = "force-dynamic";

type Durum = "form" | "gonderildi" | "hata";

export default function KayitPage() {
  const [durum, setDurum] = useState<Durum>("form");
  const [email, setEmail] = useState("");
  const [sifre, setSifre] = useState("");
  const [sifreTekrar, setSifreTekrar] = useState("");
  const [hata, setHata] = useState("");
  const [gonderiliyor, setGonderiliyor] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setHata("");

    if (!email.trim()) {
      setHata("E-posta adresi zorunludur.");
      return;
    }
    if (sifre.length < 6) {
      setHata("Şifre en az 6 karakter olmalı.");
      return;
    }
    if (sifre !== sifreTekrar) {
      setHata("Şifreler eşleşmiyor.");
      return;
    }

    setGonderiliyor(true);
    const { error } = await supabase.auth.signUp({
      email: email.trim(),
      password: sifre,
    });
    setGonderiliyor(false);

    if (error) {
      setHata(error.message || "Kayıt oluşturulamadı. Lütfen tekrar dene.");
      return;
    }

    setDurum("gonderildi");
  }

  if (durum === "gonderildi") {
    return (
      <main className="flex min-h-screen items-center justify-center bg-[#0c0d10] px-4 py-10 text-[#f4f1ea]">
        <div className="w-full max-w-sm rounded-2xl border border-white/8 bg-[#15171c] p-6 text-center">
          <h1 className="mb-2 text-lg font-bold">E-posta Gönderildi</h1>
          <p className="mb-4 text-sm text-white/60">
            <strong>{email}</strong> adresine doğrulama bağlantısı gönderdik.
            E-postanı kontrol et.
          </p>
          <Link
            href="/giris"
            className="inline-block rounded-xl bg-gradient-to-r from-blue-600 to-blue-700 px-6 py-2.5 text-sm font-bold text-white shadow-md transition hover:shadow-blue-500/30"
          >
            Giriş sayfasına dön
          </Link>
        </div>
      </main>
    );
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-[#0c0d10] px-4 py-10 text-[#f4f1ea]">
      <div className="w-full max-w-sm rounded-2xl border border-white/8 bg-[#15171c] p-6">
        <h1 className="mb-1 text-lg font-bold">Kayıt Ol</h1>
        <p className="mb-5 text-sm text-white/50">
          Yeni bir Vixrex hesabı oluştur.
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
            placeholder="Şifre (en az 6 karakter)"
            value={sifre}
            onChange={(e) => setSifre(e.target.value)}
            className="rounded-xl border border-white/10 bg-[#0c0d10] px-3 py-2.5 text-sm outline-none focus:border-blue-500"
            autoComplete="new-password"
            required
          />
          <input
            type="password"
            placeholder="Şifre (tekrar)"
            value={sifreTekrar}
            onChange={(e) => setSifreTekrar(e.target.value)}
            className="rounded-xl border border-white/10 bg-[#0c0d10] px-3 py-2.5 text-sm outline-none focus:border-blue-500"
            autoComplete="new-password"
            required
          />

          {hata && <p className="text-xs text-red-400">{hata}</p>}

          <button
            type="submit"
            disabled={gonderiliyor}
            className="mt-1 rounded-xl bg-gradient-to-r from-blue-600 to-blue-700 py-2.5 text-sm font-bold text-white shadow-md transition hover:shadow-blue-500/30 disabled:opacity-60"
          >
            {gonderiliyor ? "Kayıt yapılıyor…" : "Kayıt Ol"}
          </button>
        </form>

        <div className="mt-4 text-center text-xs text-white/40">
          <Link href="/giris" className="hover:text-white/70">
            Zaten hesabın var mı? Giriş yap
          </Link>
        </div>
      </div>
    </main>
  );
}
