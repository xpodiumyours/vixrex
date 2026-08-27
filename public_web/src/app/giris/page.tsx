"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { OwnerAuthLayout } from "@/components/owner/OwnerAuthLayout";

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
    <OwnerAuthLayout
      title="Giriş Yap"
      description="Vitrinini yönetmek için Vixrex hesabınla giriş yap."
    >
      <form onSubmit={handleSubmit} className="flex flex-col gap-4" aria-busy={gonderiliyor}>
        <div className="space-y-2">
          <label htmlFor="email" className="owner-label">
            E-posta
          </label>
          <input
            id="email"
            type="email"
            placeholder="ornek@eposta.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="owner-input text-sm"
            autoComplete="email"
            required
          />
        </div>
        <div className="space-y-2">
          <label htmlFor="sifre" className="owner-label">
            Şifre
          </label>
          <input
            id="sifre"
            type="password"
            placeholder="Şifren"
            value={sifre}
            onChange={(e) => setSifre(e.target.value)}
            className="owner-input text-sm"
            autoComplete="current-password"
            required
          />
        </div>

        {hata ? <p className="owner-error text-sm" role="alert">{hata}</p> : null}

        <button
          type="submit"
          disabled={gonderiliyor}
          className="owner-button-primary mt-1"
        >
          {gonderiliyor ? "Giriş yapılıyor…" : "Giriş Yap"}
        </button>
      </form>

      <div className="mt-5 flex flex-col gap-3 text-sm sm:flex-row sm:items-center sm:justify-between">
        <Link href="/kayit" className="owner-link">
          Hesabın yok mu? Kayıt ol
        </Link>
        <Link href="/sifre-sifirla" className="owner-link">
          Şifremi unuttum
        </Link>
      </div>
    </OwnerAuthLayout>
  );
}
