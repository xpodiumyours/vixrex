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

  const [qrAcik, setQrAcik] = useState(false);

  async function linkiKopyala() {
    if (!storeSlug) {
      setSifreHata("Link kopyalamak için önce vitrininizi yayınlayın.");
      return;
    }
    const link = `${window.location.origin}/v/${storeSlug}`;
    await navigator.clipboard.writeText(link);
    setSifreMesaj("Vitrin linki kopyalandı!");
  }

  function qrAc() {
    if (!storeSlug) {
      setSifreHata("QR kodu göstermek için önce vitrininizi yayınlayın.");
      return;
    }
    setQrAcik(true);
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
        <section className="owner-card p-5 sm:p-6">
          <h2 className="text-lg font-bold text-[var(--owner-text)]">Vitrin Bağlantısı</h2>
          {publicLink ? (
            <>
              <p className="mt-1 text-sm text-[var(--owner-muted)]">Vitrinini paylaşmak için bu bağlantıyı kopyala.</p>
              <div className="mt-3 flex items-center gap-2">
                <div className="flex-1 truncate rounded-xl border border-[var(--owner-border)] bg-[var(--owner-bg-soft)] px-3 py-2 text-sm text-[var(--owner-text)]">
                  {typeof window !== "undefined" ? `${window.location.origin}${publicLink}` : publicLink}
                </div>
                <button type="button" className="owner-button-primary shrink-0 px-4 py-2 text-xs" onClick={linkiKopyala}>📋 Kopyala</button>
              </div>
              <div className="mt-3 flex gap-2">
                <a href={publicLink} target="_blank" rel="noopener noreferrer" className="owner-button-secondary px-4 py-2 text-xs">🔗 Vitrini Gör</a>
              </div>
            </>
          ) : (
            <p className="mt-3 rounded-xl bg-[var(--owner-bg-soft)] px-3 py-3 text-sm font-bold text-[var(--owner-muted)]">Henüz yayınlanmamış</p>
          )}
        </section>

        {/* Hızlı QR Kod Paylaşımı — Flutter lib/screens/profile_screen.dart:204 _qrCard */}
        <section className="owner-card p-5 sm:p-6 cursor-pointer hover:border-[var(--owner-primary)]/40" onClick={qrAc} role="button" tabIndex={0} onKeyDown={(e) => e.key === "Enter" && qrAc()}>
          <div className="flex items-center gap-4">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-[var(--owner-primary)]/10 text-[var(--owner-primary)]">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><path d="M14 14h7v7h-7z"/><path d="M6 6h1v1H6zM17 6h1v1h-1zM6 17h1v1H6zM14 17h1v1h-1zM18 14v1h1v-1zM14 18h1v1h-1zM18 18h1v1h-1z"/></svg>
            </div>
            <div className="flex-1">
              <p className="font-bold text-[var(--owner-text)]">Hızlı QR Kod Paylaşımı</p>
              <p className="text-xs text-[var(--owner-muted)]">Vitrin QR kodunuza hızlıca ulaşın.</p>
            </div>
            <span className="text-[var(--owner-muted)]">›</span>
          </div>
        </section>

        {/* QR Modal */}
        {qrAcik && publicLink && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4" onClick={() => setQrAcik(false)}>
            <div className="w-full max-w-sm rounded-2xl bg-white p-6 text-center" onClick={(e) => e.stopPropagation()}>
              <h3 className="font-black text-gray-900">Vitrin QR Kodu</h3>
              <p className="mt-1 text-xs text-gray-500">{typeof window !== "undefined" ? `${window.location.origin}${publicLink}` : publicLink}</p>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={`https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=${encodeURIComponent(typeof window !== "undefined" ? `${window.location.origin}${publicLink}` : publicLink)}`} alt="QR" className="mx-auto mt-4 h-60 w-60 rounded-xl border" />
              <button type="button" onClick={() => setQrAcik(false)} className="owner-button-secondary mt-4 w-full">Kapat</button>
            </div>
          </div>
        )}

        {/* Seçenekler — Flutter lib/screens/profile_screen.dart:245 _option */}
        <Link href="/app/ayarlar" className="owner-card flex items-center gap-4 p-4 hover:border-[var(--owner-primary)]/40">
          <span className="text-[var(--owner-muted)]" aria-hidden="true"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="3.2" /><path d="M4.5 12a7.5 7.5 0 0 1 .2-1.6l-1.6-1.2 1.8-3.1 1.9.7A7.5 7.5 0 0 1 9.5 4.3l.3-2h4.4l.3 2c.9.3 1.8.8 2.5 1.5l1.9-.7 1.8 3.1-1.6 1.2c.1.5.2 1 .2 1.6s-.1 1.1-.2 1.6l1.6 1.2-1.8 3.1-1.9-.7c-.7.7-1.6 1.2-2.5 1.5l-.3 2H9.8l-.3-2a7.5 7.5 0 0 1-2.5-1.5l-1.9.7-1.8-3.1 1.6-1.2A7.5 7.5 0 0 1 4.5 12z" /></svg></span><span className="flex-1 font-bold text-[var(--owner-text)]">Uygulama Ayarları</span><span className="text-[var(--owner-muted)]">›</span>
        </Link>
        <Link href="/yardim" className="owner-card flex items-center gap-4 p-4 hover:border-[var(--owner-primary)]/40">
          <span className="text-[var(--owner-muted)]">❓</span><span className="flex-1 font-bold text-[var(--owner-text)]">Kullanım Bilgisi & Destek</span><span className="text-[var(--owner-muted)]">›</span>
        </Link>
        <Link href="/legal/privacy" className="owner-card flex items-center gap-4 p-4 hover:border-[var(--owner-primary)]/40">
          <span className="text-[var(--owner-muted)]">🛡️</span><span className="flex-1 font-bold text-[var(--owner-text)]">Gizlilik ve Güvenlik politikası</span><span className="text-[var(--owner-muted)]">›</span>
        </Link>

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
