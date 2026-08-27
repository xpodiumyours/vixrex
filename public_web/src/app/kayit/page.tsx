"use client";

import { useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { OwnerAuthLayout } from "@/components/owner/OwnerAuthLayout";

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
            href="/giris"
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

      <div className="mt-5 text-center text-sm">
        <Link href="/giris" className="owner-link">
          Zaten hesabın var mı? Giriş yap
        </Link>
      </div>
    </OwnerAuthLayout>
  );
}
