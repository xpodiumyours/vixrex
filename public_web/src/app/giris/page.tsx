"use client";

import { useState, useSyncExternalStore } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { guvenliDonusYolu } from "@/lib/guvenliDonus";

export const dynamic = "force-dynamic";

const donusYoluDegisikligiYok = () => () => {};
const varsayilanDonusYolu = () => "/app";

function mevcutDonusYolu() {
  const aday = new URLSearchParams(window.location.search).get("next");
  return guvenliDonusYolu(aday);
}

/** Flutter auth_screen.dart — Giriş sekmesi */
export default function GirisPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [sifre, setSifre] = useState("");
  const [sifreGoster, setSifreGoster] = useState(false);
  const [hata, setHata] = useState("");
  const [gonderiliyor, setGonderiliyor] = useState(false);
  const sonrakiYol = useSyncExternalStore(
    donusYoluDegisikligiYok,
    mevcutDonusYolu,
    varsayilanDonusYolu,
  );

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
          : error.message || "Giriş yapılamadı. Lütfen tekrar dene.",
      );
      return;
    }
    router.push(sonrakiYol);
    router.refresh();
  }

  async function googleIleGiris() {
    setHata("");
    setGonderiliyor(true);
    const { error } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}${sonrakiYol}` },
    });
    setGonderiliyor(false);
    if (error) setHata(error.message || "Google ile giriş başarısız.");
  }

  return (
    /* Flutter: AppScreenScaffold + AppCard maxWidth:400 + padding:32 */
    <main className="owner-shell flex min-h-screen items-center justify-center px-4 py-10">
      <div className="w-full max-w-[400px]">
        <div className="owner-card p-8">

          {/* Flutter: Row → logo daire + "Vixrex" 24px w900 */}
          <div className="mb-8 flex items-center justify-center gap-2.5">
            <span className="flex h-11 w-11 items-center justify-center rounded-full bg-[var(--owner-primary)]/15">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="var(--owner-primary)" strokeWidth="2" aria-hidden="true">
                <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
                <polyline points="9 22 9 12 15 12 15 22" />
              </svg>
            </span>
            <span className="text-[24px] font-black tracking-[-0.5px] text-[var(--owner-text)]">
              Vixrex
            </span>
          </div>

          {/* Flutter: başlık 18px bold + açıklama 13px mutedText */}
          <h1 className="text-center text-[18px] font-bold text-[var(--owner-text)]">
            Hesabınıza Giriş Yapın
          </h1>
          <p className="mt-2 text-center text-[13px] text-[var(--owner-muted)]">
            Vitrinlerinizi yönetmek için bilgilerinizi girin.
          </p>

          <form
            onSubmit={handleSubmit}
            aria-busy={gonderiliyor}
            className="mt-6 flex flex-col gap-4"
          >
            {/* E-posta */}
            <div className="flex flex-col gap-1.5">
              <label htmlFor="giris-email" className="owner-label">
                E-posta Adresi
              </label>
              <input
                id="giris-email"
                type="email"
                autoComplete="email"
                placeholder="ornek@eposta.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="owner-input"
                required
              />
            </div>

            {/* Şifre — Flutter: suffixIcon göster/gizle toggle */}
            <div className="flex flex-col gap-1.5">
              <label htmlFor="giris-sifre" className="owner-label">
                Şifre
              </label>
              <div className="relative">
                <input
                  id="giris-sifre"
                  type={sifreGoster ? "text" : "password"}
                  autoComplete="current-password"
                  placeholder="••••••••"
                  value={sifre}
                  onChange={(e) => setSifre(e.target.value)}
                  className="owner-input pr-12"
                  required
                />
                <button
                  type="button"
                  aria-label={sifreGoster ? "Şifreyi gizle" : "Şifreyi göster"}
                  onClick={() => setSifreGoster((v) => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-[var(--owner-muted)] hover:text-[var(--owner-text)]"
                >
                  {sifreGoster ? (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94" />
                      <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19" />
                      <line x1="1" y1="1" x2="23" y2="23" />
                    </svg>
                  ) : (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                      <circle cx="12" cy="12" r="3" />
                    </svg>
                  )}
                </button>
              </div>
            </div>

            {/* Hata — Flutter: SnackBar kırmızı */}
            {hata ? (
              <p role="alert" className="rounded-xl border border-[var(--owner-error)]/40 bg-[var(--owner-error)]/10 px-3 py-2.5 text-[13px] font-semibold text-[#FCA5A5]">
                {hata}
              </p>
            ) : null}

            {/* Giriş butonu */}
            <button
              type="submit"
              disabled={gonderiliyor}
              className="owner-button-primary mt-1 w-full"
            >
              {gonderiliyor ? "Giriş yapılıyor…" : "Giriş Yap"}
            </button>
          </form>

          {/* Ayırıcı */}
          <div className="my-5 flex items-center gap-3">
            <div className="h-px flex-1 bg-[var(--owner-border)]" />
            <span className="text-[12px] font-semibold text-[var(--owner-muted)]">veya</span>
            <div className="h-px flex-1 bg-[var(--owner-border)]" />
          </div>

          {/* Google — Flutter: signInWithGoogle + Google logosu */}
          <button
            type="button"
            disabled={gonderiliyor}
            onClick={googleIleGiris}
            className="owner-button-secondary flex w-full items-center justify-center gap-2.5"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4" />
              <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
              <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" />
              <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" />
            </svg>
            Google ile Giriş Yap
          </button>

          {/* Alt linkler */}
          <div className="mt-6 flex flex-col items-center gap-3 text-[13px]">
            <Link href="/sifre-sifirla" className="owner-link">
              Şifremi unuttum
            </Link>
            <p className="text-[var(--owner-muted)]">
              Hesabın yok mu?{" "}
              <Link
                href={sonrakiYol === "/app" ? "/kayit" : `/kayit?next=${encodeURIComponent(sonrakiYol)}`}
                className="owner-link font-bold"
              >
                Kayıt ol
              </Link>
            </p>
          </div>
        </div>
      </div>
    </main>
  );
}
