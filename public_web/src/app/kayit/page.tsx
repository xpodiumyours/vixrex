"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { OwnerAuthLayout } from "@/components/owner/OwnerAuthLayout";
import { guvenliDonusYolu } from "@/lib/guvenliDonus";
import { vixRexHizliSecenekler } from "@/lib/vixrexMesajlari";

export const dynamic = "force-dynamic";

type Durum = "form" | "gonderildi" | "hata";

export default function KayitPage() {
  const router = useRouter();
  const [durum, setDurum] = useState<Durum>("form");
  const [email, setEmail] = useState("");
  const [sifre, setSifre] = useState("");
  const [sifreTekrar, setSifreTekrar] = useState("");
  const [hata, setHata] = useState("");
  const [gonderiliyor, setGonderiliyor] = useState(false);
  const [sonrakiYol, setSonrakiYol] = useState("/app");
  const [showLogin, setShowLogin] = useState(true);
  const [hizliSecenekGorunur, setHizliSecenekGorunur] = useState(true);

  useEffect(() => {
    // SSR'da window yok — sunucu her zaman "/app" render eder (useState
    // başlangıcı), hydration mismatch olmasın diye bilerek lazy init değil
    // effect kullanılıyor; mount sonrası gerçek "next" değeri buradan gelir.
    const aday = new URLSearchParams(window.location.search).get("next");
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setSonrakiYol(guvenliDonusYolu(aday));
  }, []);

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
      options: {
        emailRedirectTo: `${window.location.origin}${sonrakiYol}`,
      },
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
      <OwnerAuthLayout
        title="E-posta Gönderildi"
        description="Hesabını doğruladıktan sonra vitrin yönetimine devam edebilirsin."
      >
        <div className="text-center" role="status" aria-live="polite">
          <p className="mb-5 text-sm leading-6 text-[var(--owner-text-alt)]">
            <strong>{email}</strong> adresine doğrulama bağlantısı gönderdik.
            E-postanı kontrol et.
          </p>
          <Link
            href={sonrakiYol === "/app" ? "/giris" : `/giris?next=${encodeURIComponent(sonrakiYol)}`}
            className="owner-button-primary inline-flex items-center justify-center"
          >
            Giriş Sayfasına Dön
          </Link>
        </div>
      </OwnerAuthLayout>
    );
  }

  return (
    <OwnerAuthLayout
      title="Kayıt Ol"
      description="Vitrinini oluşturmak ve yönetmek için Vixrex hesabını aç."
    >
      {/* Flutter uyumlu: Hızlı Seçenekler (bkz. vixRexOnboardingController
          chooseReadyTemplate/chooseScratch/declineWelcome) — üç düğmenin de
          kendi eylemi var, "Sıfırdan Oluştur" ve "Bakınıyorum" aynı toggle'ı
          paylaşmıyor. Etiketler shared/vixrex_mesajlar.json'dan geliyor. */}
      {hizliSecenekGorunur ? (
        <div className="my-4 flex flex-col items-center gap-2">
          <div className="text-xs font-medium text-[var(--owner-muted)]">Hızlı Seçenekler</div>
          <div className="flex gap-2 flex-wrap justify-center">
            <button
              type="button"
              className="owner-button-primary flex-1 sm:w-48 text-sm font-medium"
              onClick={() => router.push("/kesfet?yalniz_kiralik=1")}
            >
              {vixRexHizliSecenekler.find((secenek) => secenek.id === "hazir_vitrin_sec")?.etiket}
            </button>
            <button
              type="button"
              className="owner-button-primary flex-1 sm:w-48 text-sm font-medium"
              onClick={() => setShowLogin(true)}
            >
              {vixRexHizliSecenekler.find((secenek) => secenek.id === "sifirdan_olustur")?.etiket}
            </button>
            <button
              type="button"
              className="owner-button-secondary flex-1 sm:w-48 text-sm font-medium"
              onClick={() => setHizliSecenekGorunur(false)}
            >
              {vixRexHizliSecenekler.find((secenek) => secenek.id === "bakiniyorum")?.etiket}
            </button>
          </div>
        </div>
      ) : null}

      {showLogin ? (
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
              placeholder="En az 6 karakter"
              value={sifre}
              onChange={(e) => setSifre(e.target.value)}
              className="owner-input text-sm"
              autoComplete="new-password"
              minLength={6}
              required
            />
          </div>
          <div className="space-y-2">
            <label htmlFor="sifre-tekrar" className="owner-label">
              Şifre Tekrar
            </label>
            <input
              id="sifre-tekrar"
              type="password"
              placeholder="Şifreni yeniden yaz"
              value={sifreTekrar}
              onChange={(e) => setSifreTekrar(e.target.value)}
              className="owner-input text-sm"
              autoComplete="new-password"
              required
            />
          </div>

          {hata ? <p className="owner-error text-sm" role="alert">{hata}</p> : null}

          <button
            type="submit"
            disabled={gonderiliyor}
            className="owner-button-primary mt-1"
          >
            {gonderiliyor ? "Kayıt yapılıyor…" : "Kayıt Ol"}
          </button>
        </form>
      ) : null}

      <div className="mt-4 flex items-center gap-3">
        <button
          type="button"
          disabled={gonderiliyor}
          onClick={async () => {
            setHata("");
            setGonderiliyor(true);
            const { error } = await supabase.auth.signInWithOAuth({
              provider: "google",
              options: {
                redirectTo: `${window.location.origin}${sonrakiYol}`,
              },
            });
            setGonderiliyor(false);
            if (error) {
              setHata(error.message || "Google ile giriş başarısız.");
            }
          }}
          className="owner-button-secondary w-full flex items-center justify-center gap-2"
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/>
            <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
            <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
            <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
          </svg>
          Google ile Giriş Yap
        </button>
      </div>

      {showLogin ? (
        <div className="mt-4 text-center text-sm">
          <Link
            href={sonrakiYol === "/app" ? "/giris" : `/giris?next=${encodeURIComponent(sonrakiYol)}`}
            className="owner-link"
          >
            Zaten hesabın var mı? Giriş yap
          </Link>
        </div>
      ) : null}
    </OwnerAuthLayout>
  );
}