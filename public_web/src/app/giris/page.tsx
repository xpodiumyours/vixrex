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

      <div className="my-4 flex items-center gap-3">
        <div className="h-px flex-1 bg-[var(--owner-border)]" />
        <span className="text-xs font-semibold text-[var(--owner-muted)]">veya</span>
        <div className="h-px flex-1 bg-[var(--owner-border)]" />
      </div>

      <button
        type="button"
        disabled={gonderiliyor}
        onClick={async () => {
          setHata("");
          setGonderiliyor(true);
          const { error } = await supabase.auth.signInWithOAuth({
            provider: "google",
            options: {
              redirectTo: `${window.location.origin}/app`,
            },
          });
          setGonderiliyor(false);
          if (error) {
            setHata(error.message || "Google ile giriş başarısız.");
          }
        }}
        className="owner-button-secondary flex items-center justify-center gap-2"
      >
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
          <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/>
          <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
          <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
          <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
        </svg>
        Google ile Giriş Yap
      </button>

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
