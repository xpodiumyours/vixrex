"use client";

// V-14 (attack-vectors.md, 2026-08-18): şifre sıfırlama ölü uçtu.
// resetPasswordForEmail çağrısı e-postayı gönderiyordu ama link
// tıklanınca gidecek hiçbir sayfa yoktu (LegalConfig.publicSiteUrl
// köküne düşüyordu, orada işleyen bir şey yok). Bu sayfa Supabase'in
// e-postadaki linke eklediği kurtarma oturumunu (URL hash/PASSWORD_
// RECOVERY event'i, supabase-js kendisi otomatik algılıyor) yakalayıp
// yeni şifre belirleme formunu gösterir.

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

type Durum = "kontrol-ediliyor" | "hazir" | "gecersiz" | "basarili";

export default function SifreSifirlaPage() {
  const [durum, setDurum] = useState<Durum>("kontrol-ediliyor");
  const [sifre, setSifre] = useState("");
  const [sifreTekrar, setSifreTekrar] = useState("");
  const [hata, setHata] = useState("");
  const [gonderiliyor, setGonderiliyor] = useState(false);
  const [istemEmail, setIstemEmail] = useState("");
  const [istemHata, setIstemHata] = useState("");
  const [istemBasari, setIstemBasari] = useState(false);
  const [istemGonderiliyor, setIstemGonderiliyor] = useState(false);

  useEffect(() => {
    // Supabase, kurtarma linkindeki token'ı sayfa yüklenirken kendisi
    // işler ve PASSWORD_RECOVERY event'ini yayınlar. Link geçersiz/süresi
    // dolmuşsa event hiç gelmez — kısa bir süre bekleyip gelmezse
    // "geçersiz" durumuna düşülür.
    const { data: sub } = supabase.auth.onAuthStateChange((event) => {
      if (event === "PASSWORD_RECOVERY") {
        setDurum("hazir");
      }
    });

    const zamanAsimi = window.setTimeout(() => {
      setDurum((mevcut) => (mevcut === "kontrol-ediliyor" ? "gecersiz" : mevcut));
    }, 4000);

    return () => {
      sub.subscription.unsubscribe();
      window.clearTimeout(zamanAsimi);
    };
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setHata("");

    if (sifre.length < 6) {
      setHata("Şifre en az 6 karakter olmalı.");
      return;
    }
    if (sifre !== sifreTekrar) {
      setHata("Şifreler eşleşmiyor.");
      return;
    }

    setGonderiliyor(true);
    const { error } = await supabase.auth.updateUser({ password: sifre });
    setGonderiliyor(false);

    if (error) {
      setHata(error.message || "Şifre güncellenemedi. Lütfen tekrar dene.");
      return;
    }
    setDurum("basarili");
  }

  async function handleIstem(e: React.FormEvent) {
    e.preventDefault();
    setIstemHata("");
    const email = istemEmail.trim();
    if (!email || !/^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$/.test(email)) {
      setIstemHata("Şifre sıfırlamak için geçerli bir e-posta girin.");
      return;
    }
    setIstemGonderiliyor(true);
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/sifre-sifirla`,
    });
    setIstemGonderiliyor(false);
    if (error) {
      setIstemHata(error.message || "E-posta gönderilemedi. Lütfen tekrar dene.");
      return;
    }
    setIstemBasari(true);
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-[#0c0d10] px-4 py-10 text-[#f4f1ea]">
      <div className="w-full max-w-sm rounded-2xl border border-white/8 bg-[#15171c] p-6">
        <h1 className="mb-2 text-lg font-bold">Şifreni Sıfırla</h1>

        {durum === "kontrol-ediliyor" && (
          <p className="text-sm text-white/60">Bağlantı doğrulanıyor…</p>
        )}

        {durum === "gecersiz" && (
          <>
            {istemBasari ? (
              <p className="text-sm text-emerald-400">
                Şifre sıfırlama bağlantısı e-postana gönderildi. Gelen kutunu kontrol et.
              </p>
            ) : (
              <form onSubmit={handleIstem} className="flex flex-col gap-3">
                <p className="text-sm text-white/60">
                  E-posta adresini gir, şifre sıfırlama bağlantısını gönderelim.
                </p>
                <input
                  type="email"
                  placeholder="ornek@eposta.com"
                  value={istemEmail}
                  onChange={(e) => setIstemEmail(e.target.value)}
                  className="rounded-xl border border-white/10 bg-[#0c0d10] px-3 py-2.5 text-sm outline-none focus:border-blue-500"
                  autoComplete="email"
                  required
                />
                {istemHata && <p className="text-xs text-red-400">{istemHata}</p>}
                <button
                  type="submit"
                  disabled={istemGonderiliyor}
                  className="rounded-xl bg-gradient-to-r from-blue-600 to-blue-700 py-2.5 text-sm font-bold text-white shadow-md transition hover:shadow-blue-500/30 disabled:opacity-60"
                >
                  {istemGonderiliyor ? "Gönderiliyor…" : "Bağlantı Gönder"}
                </button>
              </form>
            )}
            <Link
              href="/"
              className="mt-4 inline-block text-sm font-semibold text-blue-400 hover:text-blue-300"
            >
              Ana sayfaya dön
            </Link>
          </>
        )}

        {durum === "hazir" && (
          <form onSubmit={handleSubmit} className="flex flex-col gap-3">
            <p className="mb-1 text-sm text-white/60">
              Hesabın için yeni bir şifre belirle.
            </p>
            <input
              type="password"
              placeholder="Yeni şifre"
              value={sifre}
              onChange={(e) => setSifre(e.target.value)}
              className="rounded-xl border border-white/10 bg-[#0c0d10] px-3 py-2.5 text-sm outline-none focus:border-blue-500"
              autoComplete="new-password"
            />
            <input
              type="password"
              placeholder="Yeni şifre (tekrar)"
              value={sifreTekrar}
              onChange={(e) => setSifreTekrar(e.target.value)}
              className="rounded-xl border border-white/10 bg-[#0c0d10] px-3 py-2.5 text-sm outline-none focus:border-blue-500"
              autoComplete="new-password"
            />
            {hata && <p className="text-xs text-red-400">{hata}</p>}
            <button
              type="submit"
              disabled={gonderiliyor}
              className="mt-1 rounded-xl bg-gradient-to-r from-blue-600 to-blue-700 py-2.5 text-sm font-bold text-white shadow-md transition hover:shadow-blue-500/30 disabled:opacity-60"
            >
              {gonderiliyor ? "Kaydediliyor…" : "Şifreyi Güncelle"}
            </button>
          </form>
        )}

        {durum === "basarili" && (
          <p className="text-sm text-emerald-400">
            Şifren güncellendi. Vixrex uygulamasına dönüp yeni şifrenle giriş
            yapabilirsin.
          </p>
        )}
      </div>
    </main>
  );
}
