"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import type { User } from "@supabase/supabase-js";

export const dynamic = "force-dynamic";

export default function ProfilPage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [storeSlug, setStoreSlug] = useState<string | null>(null);
  const [storeName, setStoreName] = useState<string>("");
  const [yukleniyor, setYukleniyor] = useState(true);

  // Şifre değiştirme
  const [yeniSifre, setYeniSifre] = useState("");
  const [yeniSifreTekrar, setYeniSifreTekrar] = useState("");
  const [sifreBusy, setSifreBusy] = useState(false);
  const [sifreMesaj, setSifreMesaj] = useState("");
  const [sifreHata, setSifreHata] = useState("");

  // Çıkış
  const [cikisBusy, setCikisBusy] = useState(false);

  useEffect(() => {
    async function init() {
      let { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        try {
          const { data: anonData } = await supabase.auth.signInAnonymously();
          if (anonData?.session) session = anonData.session;
          else {
            router.push("/giris");
            return;
          }
        } catch {
          router.push("/giris");
          return;
        }
      }
      setUser(session.user);

      // Vitrin bilgisi
      const { data: durum } = await supabase.rpc("bootstrap_owner_state");
      const sonuc = (durum ?? {}) as { has_store?: boolean; slug?: string; name?: string };
      if (sonuc.has_store && sonuc.slug) {
        setStoreSlug(sonuc.slug);
        setStoreName(sonuc.name || "");
      }

      setYukleniyor(false);
    }
    init();
  }, [router]);

  async function sifreDegistir(e: React.FormEvent) {
    e.preventDefault();
    setSifreHata("");
    setSifreMesaj("");

    if (!yeniSifre || !yeniSifreTekrar) {
      setSifreHata("Her iki alan da doldurulmalıdır.");
      return;
    }
    if (yeniSifre.length < 6) {
      setSifreHata("Yeni şifre en az 6 karakter olmalıdır.");
      return;
    }
    if (yeniSifre !== yeniSifreTekrar) {
      setSifreHata("Şifreler eşleşmiyor.");
      return;
    }

    setSifreBusy(true);
    try {
      const { error } = await supabase.auth.updateUser({ password: yeniSifre });
      if (error) {
        setSifreHata(error.message || "Şifre değiştirilemedi.");
      } else {
        setSifreMesaj("Şifre başarıyla değiştirildi.");
        setYeniSifre("");
        setYeniSifreTekrar("");
      }
    } catch {
      setSifreHata("Bir hata oluştu. Lütfen tekrar deneyin.");
    } finally {
      setSifreBusy(false);
    }
  }

  async function cikisYap() {
    setCikisBusy(true);
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  }

  async function linkiKopyala() {
    if (!storeSlug) return;
    const link = `${window.location.origin}/v/${storeSlug}`;
    await navigator.clipboard.writeText(link);
    setSifreMesaj("Vitrin linki panoya kopyalandı!");
  }

  if (yukleniyor) {
    return (
      <main className="owner-shell flex items-center justify-center px-4">
        <div className="owner-card flex items-center gap-3 px-5 py-4">
          <span className="h-3 w-3 animate-pulse rounded-full bg-[var(--owner-primary)]" />
          <span className="text-sm text-[var(--owner-muted)]">Yükleniyor…</span>
        </div>
      </main>
    );
  }

  const publicLink = storeSlug ? `/v/${storeSlug}` : null;

  return (
    <main className="owner-shell">
      <header className="border-b border-[var(--owner-border)] bg-[var(--owner-bg)]/90 px-4 py-4 sm:px-6">
        <div className="mx-auto flex max-w-3xl items-center gap-3">
          <Link href="/app" className="owner-button-secondary px-3 py-2 text-xs">
            ← Geri
          </Link>
          <h1 className="text-xl font-bold text-[var(--owner-text)]">Profil</h1>
        </div>
      </header>

      <div className="mx-auto max-w-3xl space-y-6 px-4 py-8 sm:px-6">
        {/* Hesap Bilgisi */}
        <section className="owner-card p-5 sm:p-6">
          <h2 className="text-lg font-bold text-[var(--owner-text)]">Hesap</h2>
          <div className="mt-4 flex items-center gap-4">
            <div className="flex h-12 w-12 items-center justify-center rounded-full bg-[var(--owner-primary)]/10">
              <span className="text-lg font-bold text-[var(--owner-primary)]">
                {user?.email?.[0]?.toUpperCase() || "V"}
              </span>
            </div>
            <div>
              <p className="font-bold text-[var(--owner-text)]">{user?.email}</p>
              <p className="text-xs text-[var(--owner-muted)]">
                {storeName ? `${storeName} — Hesabınız aktif` : "Hesabınız aktif"}
              </p>
            </div>
          </div>
        </section>

        {/* Vitrin Bağlantısı */}
        {publicLink && (
          <section className="owner-card p-5 sm:p-6">
            <h2 className="text-lg font-bold text-[var(--owner-text)]">Vitrin Bağlantısı</h2>
            <p className="mt-1 text-sm text-[var(--owner-muted)]">
              Vitrinini paylaşmak için bu bağlantıyı kopyala.
            </p>
            <div className="mt-3 flex items-center gap-2">
              <div className="flex-1 truncate rounded-xl border border-[var(--owner-border)] bg-[var(--owner-bg-soft)] px-3 py-2 text-sm text-[var(--owner-text)]">
                {typeof window !== "undefined" ? `${window.location.origin}${publicLink}` : publicLink}
              </div>
              <button
                type="button"
                className="owner-button-primary shrink-0 px-4 py-2 text-xs"
                onClick={linkiKopyala}
              >
                📋 Kopyala
              </button>
            </div>
            <div className="mt-3 flex gap-2">
              <a
                href={publicLink}
                target="_blank"
                rel="noopener noreferrer"
                className="owner-button-secondary px-4 py-2 text-xs"
              >
                🔗 Vitrini Gör
              </a>
            </div>
          </section>
        )}

        {/* Şifre Değiştirme */}
        <section className="owner-card p-5 sm:p-6">
          <h2 className="text-lg font-bold text-[var(--owner-text)]">Şifre Değiştir</h2>
          <p className="mt-1 text-sm text-[var(--owner-muted)]">
            Hesap güvenliğin için şifreni güncelle.
          </p>

          {sifreMesaj && (
            <p className="mt-3 rounded-xl border border-[var(--owner-success)]/40 bg-[var(--owner-success)]/10 p-3 text-sm text-[var(--owner-success)]">
              {sifreMesaj}
            </p>
          )}
          {sifreHata && (
            <p className="mt-3 rounded-xl border border-red-400/40 bg-red-400/10 p-3 text-sm text-red-600" role="alert">
              {sifreHata}
            </p>
          )}

          <form onSubmit={sifreDegistir} className="mt-4 space-y-4">
            <div>
              <label htmlFor="yeni-sifre" className="owner-label">Yeni Şifre</label>
              <input
                id="yeni-sifre"
                type="password"
                className="owner-input w-full"
                value={yeniSifre}
                onChange={(e) => setYeniSifre(e.target.value)}
                placeholder="En az 6 karakter"
                minLength={6}
                autoComplete="new-password"
                disabled={sifreBusy}
              />
            </div>
            <div>
              <label htmlFor="yeni-sifre-tekrar" className="owner-label">Yeni Şifre (Tekrar)</label>
              <input
                id="yeni-sifre-tekrar"
                type="password"
                className="owner-input w-full"
                value={yeniSifreTekrar}
                onChange={(e) => setYeniSifreTekrar(e.target.value)}
                placeholder="Şifreni tekrar gir"
                minLength={6}
                autoComplete="new-password"
                disabled={sifreBusy}
              />
            </div>
            <button
              type="submit"
              className="owner-button-primary w-full sm:w-auto"
              disabled={sifreBusy || !yeniSifre || !yeniSifreTekrar}
            >
              {sifreBusy ? "Değiştiriliyor…" : "Şifreyi Değiştir"}
            </button>
          </form>
        </section>

        {/* Çıkış Yap */}
        <section className="owner-card p-5 sm:p-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-bold text-[var(--owner-text)]">Oturum</h2>
              <p className="text-sm text-[var(--owner-muted)]">
                Hesabından çıkış yap.
              </p>
            </div>
            <button
              type="button"
              className="owner-button-danger px-4 py-2 text-xs"
              onClick={cikisYap}
              disabled={cikisBusy}
            >
              {cikisBusy ? "Çıkılıyor…" : "Çıkış Yap"}
            </button>
          </div>
        </section>

        {/* Hesap Silme */}
        <section className="owner-card border-red-400/30 p-5 sm:p-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-bold text-red-600">Tehlikeli Bölge</h2>
              <p className="text-sm text-[var(--owner-muted)]">
                Hesabını ve vitrinini silmek için.
              </p>
            </div>
            <Link
              href="/app/hesap"
              className="owner-button-danger px-4 py-2 text-xs"
            >
              Hesap Yönetimi
            </Link>
          </div>
        </section>
      </div>
    </main>
  );
}
