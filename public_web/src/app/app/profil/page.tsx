"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import type { User } from "@supabase/supabase-js";

export const dynamic = "force-dynamic";

type WorkspaceBootstrap = {
  store?: {
    slug?: string;
    name?: string;
    is_published?: boolean;
  } | null;
};

type LegacyBootstrap = {
  has_store?: boolean;
  slug?: string;
  name?: string;
};

export default function ProfilPage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [storeSlug, setStoreSlug] = useState<string | null>(null);
  const [storeName, setStoreName] = useState("");
  const [storePublished, setStorePublished] = useState(false);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [mesaj, setMesaj] = useState("");
  const [qrAcik, setQrAcik] = useState(false);

  useEffect(() => {
    async function init() {
      let {
        data: { session },
      } = await supabase.auth.getSession();

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

      const workspace = await supabase.rpc("get_owner_workspace_bootstrap");
      if (!workspace.error) {
        const store = ((workspace.data ?? {}) as WorkspaceBootstrap).store;
        if (store?.slug) {
          setStoreSlug(store.slug);
          setStoreName(store.name ?? "");
          setStorePublished(store.is_published === true);
          setYukleniyor(false);
          return;
        }
      }

      const legacy = await supabase.rpc("bootstrap_owner_state");
      const sonuc = (legacy.data ?? {}) as LegacyBootstrap;
      if (sonuc.has_store && sonuc.slug) {
        setStoreSlug(sonuc.slug);
        setStoreName(sonuc.name ?? "");
      }
      setYukleniyor(false);
    }

    void init();
  }, [router]);

  const publicLink = storeSlug && storePublished ? `/v/${storeSlug}` : null;
  const kullaniciEtiketi = user?.email || storeName || "Vixrex Kullanıcısı";

  async function linkiKopyala() {
    if (!publicLink) {
      setMesaj("Link kopyalamak için önce vitrininizi yayınlayın.");
      return;
    }
    const link = `${window.location.origin}${publicLink}`;
    await navigator.clipboard.writeText(link);
    setMesaj("Vitrin linki kopyalandı.");
  }

  function qrAc() {
    if (!publicLink) {
      setMesaj("QR kodu göstermek için önce vitrininizi yayınlayın.");
      return;
    }
    setQrAcik(true);
  }

  if (yukleniyor) {
    return (
      <main className="owner-shell flex items-center justify-center px-4">
        <div className="owner-card flex items-center gap-3 px-5 py-4" role="status" aria-live="polite">
          <span className="h-3 w-3 animate-pulse rounded-full bg-[var(--owner-primary)]" aria-hidden="true" />
          <span className="text-sm text-[var(--owner-muted)]">Yükleniyor…</span>
        </div>
      </main>
    );
  }

  return (
    <main className="owner-shell">
      <header className="border-b border-[var(--owner-border)] bg-[var(--owner-bg)]/90 px-4 py-4 sm:px-6">
        <div className="mx-auto max-w-3xl">
          <h1 className="text-xl font-bold text-[var(--owner-text)]">Profil</h1>
        </div>
      </header>

      <div className="mx-auto max-w-3xl space-y-4 px-4 py-8 sm:px-6">
        {mesaj ? (
          <p className="owner-card px-4 py-3 text-sm text-[var(--owner-muted)]" role="status">
            {mesaj}
          </p>
        ) : null}

        <section className="owner-card p-5 sm:p-6">
          <h2 className="text-lg font-bold text-[var(--owner-text)]">Hesap</h2>
          <div className="mt-4 flex items-center gap-4">
            <div className="flex h-12 w-12 items-center justify-center rounded-full bg-[var(--owner-primary)]/10">
              <span className="text-lg font-bold text-[var(--owner-primary)]">
                {kullaniciEtiketi[0]?.toUpperCase() || "V"}
              </span>
            </div>
            <div className="min-w-0">
              <p className="truncate font-bold text-[var(--owner-text)]">{kullaniciEtiketi}</p>
              <p className="text-xs text-[var(--owner-muted)]">
                {publicLink ? "Vitrininiz yayında" : "Hesabınız aktif"}
              </p>
            </div>
          </div>
        </section>

        <section className="owner-card p-5 sm:p-6">
          <h2 className="text-lg font-bold text-[var(--owner-text)]">Vitrin Bağlantısı</h2>
          <button
            type="button"
            onClick={() => void linkiKopyala()}
            className="mt-3 flex w-full items-center gap-2 rounded-xl bg-[var(--owner-bg-soft)] px-3 py-3 text-left"
          >
            <span aria-hidden="true">🔗</span>
            <span className="min-w-0 flex-1 truncate text-sm font-bold text-[var(--owner-text)]">
              {publicLink
                ? typeof window !== "undefined"
                  ? `${window.location.host}${publicLink}`
                  : publicLink
                : "Henüz yayınlanmamış"}
            </span>
            {publicLink ? <span className="text-[var(--owner-muted)]" aria-hidden="true">📋</span> : null}
          </button>
        </section>

        <button
          type="button"
          onClick={qrAc}
          className="owner-card flex w-full items-center gap-4 p-5 text-left sm:p-6"
        >
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-[var(--owner-primary)]/10 text-[var(--owner-primary)]">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
              <rect x="3" y="3" width="7" height="7" rx="1.5" />
              <rect x="14" y="3" width="7" height="7" rx="1.5" />
              <rect x="3" y="14" width="7" height="7" rx="1.5" />
              <path d="M14 14h7v7h-7z" />
            </svg>
          </div>
          <div className="flex-1">
            <p className="font-bold text-[var(--owner-text)]">Hızlı QR Kod Paylaşımı</p>
            <p className="text-xs text-[var(--owner-muted)]">Vitrin QR kodunuza hızlıca ulaşın.</p>
          </div>
          <span className="text-[var(--owner-muted)]">›</span>
        </button>

        <Link href="/app/ayarlar" className="owner-card flex items-center gap-4 p-4 hover:border-[var(--owner-primary)]/40">
          <span className="text-[var(--owner-muted)]" aria-hidden="true">⚙️</span>
          <span className="flex-1 font-bold text-[var(--owner-text)]">Uygulama Ayarları</span>
          <span className="text-[var(--owner-muted)]">›</span>
        </Link>
        <Link href="/yardim" className="owner-card flex items-center gap-4 p-4 hover:border-[var(--owner-primary)]/40">
          <span className="text-[var(--owner-muted)]" aria-hidden="true">❓</span>
          <span className="flex-1 font-bold text-[var(--owner-text)]">Kullanım Bilgisi & Destek</span>
          <span className="text-[var(--owner-muted)]">›</span>
        </Link>
        <Link href="/legal/privacy" className="owner-card flex items-center gap-4 p-4 hover:border-[var(--owner-primary)]/40">
          <span className="text-[var(--owner-muted)]" aria-hidden="true">🛡️</span>
          <span className="flex-1 font-bold text-[var(--owner-text)]">Gizlilik ve Güvenlik politikası</span>
          <span className="text-[var(--owner-muted)]">›</span>
        </Link>
      </div>

      {qrAcik && publicLink ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4" onClick={() => setQrAcik(false)}>
          <div className="w-full max-w-sm rounded-2xl bg-white p-6 text-center" onClick={(e) => e.stopPropagation()}>
            <h3 className="font-black text-gray-900">Vitrin QR Kodu</h3>
            <p className="mt-1 text-xs text-gray-500">
              {typeof window !== "undefined" ? `${window.location.origin}${publicLink}` : publicLink}
            </p>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={`https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=${encodeURIComponent(
                typeof window !== "undefined" ? `${window.location.origin}${publicLink}` : publicLink,
              )}`}
              alt="QR"
              className="mx-auto mt-4 h-60 w-60 rounded-xl border"
            />
            <button type="button" onClick={() => setQrAcik(false)} className="owner-button-secondary mt-4 w-full">
              Kapat
            </button>
          </div>
        </div>
      ) : null}
    </main>
  );
}
