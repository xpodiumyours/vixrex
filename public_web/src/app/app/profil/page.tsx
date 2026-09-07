"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { VitrinQrSheet } from "@/components/app/VitrinQrSheet";
import { supabase } from "@/lib/supabase";
import type { User } from "@supabase/supabase-js";

export const dynamic = "force-dynamic";

type WorkspaceBootstrap = {
  store?: { slug?: string; name?: string; is_published?: boolean } | null;
};
type LegacyBootstrap = { has_store?: boolean; slug?: string; name?: string };

function KisiIkonu() {
  return <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><circle cx="12" cy="8" r="3.5" /><path d="M5 20c.6-4 3-6 7-6s6.4 2 7 6" /></svg>;
}
function BaglantiIkonu() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><path d="M10 13a5 5 0 0 0 7.1.1l2-2a5 5 0 0 0-7.1-7.1l-1.1 1.1" /><path d="M14 11a5 5 0 0 0-7.1-.1l-2 2A5 5 0 0 0 12 20l1.1-1.1" /></svg>;
}
function KopyalaIkonu() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><rect x="9" y="9" width="11" height="11" rx="2" /><path d="M15 9V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v7a2 2 0 0 0 2 2h3" /></svg>;
}
function QrIkonu() {
  return <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><rect x="3" y="3" width="7" height="7" rx="1.5" /><rect x="14" y="3" width="7" height="7" rx="1.5" /><rect x="3" y="14" width="7" height="7" rx="1.5" /><path d="M14 14h3v3h-3zM18 14h3v3h-3zM14 18h3v3h-3zM18 18h3v3h-3z" /></svg>;
}
function AyarIkonu() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1-2.8 2.8-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.6V21h-4v-.1A1.7 1.7 0 0 0 9 19.3a1.7 1.7 0 0 0-1.9.3l-.1.1L4.2 17l.1-.1a1.7 1.7 0 0 0 .3-1.9A1.7 1.7 0 0 0 3 14H3v-4h.1A1.7 1.7 0 0 0 4.7 9a1.7 1.7 0 0 0-.3-1.9L4.2 7 7 4.2l.1.1A1.7 1.7 0 0 0 9 4.7 1.7 1.7 0 0 0 10 3.1V3h4v.1A1.7 1.7 0 0 0 15 4.7a1.7 1.7 0 0 0 1.9-.3l.1-.1L19.8 7l-.1.1A1.7 1.7 0 0 0 19.3 9a1.7 1.7 0 0 0 1.6 1H21v4h-.1a1.7 1.7 0 0 0-1.5 1Z" /></svg>;
}
function YardimIkonu() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><circle cx="12" cy="12" r="9" /><path d="M9.8 9a2.4 2.4 0 1 1 3.8 1.9c-.9.6-1.6 1.1-1.6 2.3" /><path d="M12 17h.01" /></svg>;
}
function KalkanIkonu() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M12 3 5 6v5c0 4.6 2.8 8 7 10 4.2-2 7-5.4 7-10V6l-7-3Z" /></svg>;
}
function OkIkonu() {
  return <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><path d="m9 18 6-6-6-6" /></svg>;
}

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
      let { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        try {
          const { data: anonData } = await supabase.auth.signInAnonymously();
          if (anonData?.session) session = anonData.session;
          else { router.push("/giris"); return; }
        } catch { router.push("/giris"); return; }
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
        const { data: store } = await supabase.from("stores").select("is_published").eq("slug", sonuc.slug).maybeSingle();
        setStorePublished(store?.is_published === true);
      }
      setYukleniyor(false);
    }
    void init();
  }, [router]);

  const publicLink = storeSlug && storePublished ? `/v/${storeSlug}` : null;
  const kullaniciEtiketi = user?.email || storeName || "Vixrex Kullanıcısı";

  async function linkiKopyala() {
    if (!publicLink) { setMesaj("Link kopyalamak için önce vitrininizi yayınlayın."); return; }
    await navigator.clipboard.writeText(`${window.location.origin}${publicLink}`);
    setMesaj("Vitrin linki kopyalandı.");
  }
  function qrAc() {
    if (!publicLink) { setMesaj("QR kodu göstermek için önce vitrininizi yayınlayın."); return; }
    setQrAcik(true);
  }

  if (yukleniyor) {
    return <main className="flex min-h-full items-center justify-center bg-lp-bg-editor px-4"><div className="flex items-center gap-3 rounded-2xl border border-lp-border bg-lp-surface px-5 py-4" role="status" aria-live="polite"><span className="h-3 w-3 animate-pulse rounded-full bg-lp-primary" aria-hidden="true" /><span className="text-[12px] font-semibold text-lp-muted">Yükleniyor…</span></div></main>;
  }

  return (
    <main className="min-h-full bg-lp-bg-editor text-lp-text">
      <header className="flex h-14 items-center px-6"><h1 className="text-[18px] font-black">Profil</h1></header>
      <div className="w-full px-6 pb-8 pt-2">
        {mesaj ? <p className="mb-4 rounded-2xl border border-lp-border bg-lp-surface px-4 py-3 text-[12px] font-semibold text-lp-muted" role="status">{mesaj}</p> : null}

        <section className="rounded-2xl border border-lp-border bg-lp-surface p-4">
          <div className="flex items-center gap-3.5">
            <div className="flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-full bg-lp-surface-soft text-lp-primary"><KisiIkonu /></div>
            <div className="min-w-0"><p className="truncate text-[16px] font-extrabold text-lp-text">{kullaniciEtiketi}</p><p className="mt-0.5 text-[12px] font-semibold text-lp-muted">{publicLink ? "Vitrininiz yayında" : "Hesabınız aktif"}</p></div>
          </div>
        </section>

        <div className="h-4" />
        <button type="button" onClick={() => void linkiKopyala()} className="w-full rounded-2xl border border-lp-border bg-lp-surface p-4 text-left">
          <p className="text-[14px] font-bold text-lp-text">Vitrin Bağlantısı</p>
          <div className="mt-2 flex items-center gap-2 rounded-xl bg-lp-surface-soft px-3 py-2.5">
            <span className="shrink-0 text-lp-primary"><BaglantiIkonu /></span>
            <span className={`min-w-0 flex-1 truncate text-[12px] font-bold ${publicLink ? "text-lp-text" : "text-lp-muted"}`}>{publicLink ? (typeof window !== "undefined" ? `${window.location.host}${publicLink}` : publicLink) : "Henüz yayınlanmamış"}</span>
            {publicLink ? <span className="shrink-0 text-lp-muted"><KopyalaIkonu /></span> : null}
          </div>
        </button>

        <div className="h-3" />
        <button type="button" onClick={qrAc} className="flex w-full items-center gap-3.5 rounded-2xl border border-lp-border bg-lp-surface p-4 text-left">
          <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-lp-primary/10 text-lp-primary"><QrIkonu /></div>
          <div className="min-w-0 flex-1"><p className="text-[14px] font-bold text-lp-text">Hızlı QR Kod Paylaşımı</p><p className="mt-0.5 text-[12px] font-semibold text-lp-muted">Vitrin QR kodunuza hızlıca ulaşın.</p></div>
          <span className="shrink-0 text-lp-muted"><OkIkonu /></span>
        </button>

        <div className="h-5" />
        <Link href="/app/ayarlar" className="flex items-center gap-3.5 rounded-2xl border border-lp-border bg-lp-surface p-4 text-lp-muted hover:bg-lp-surface-soft"><AyarIkonu /><span className="flex-1 text-[14px] font-bold text-lp-text">Uygulama Ayarları</span><OkIkonu /></Link>
        <div className="h-2.5" />
        <Link href="/yardim" className="flex items-center gap-3.5 rounded-2xl border border-lp-border bg-lp-surface p-4 text-lp-muted hover:bg-lp-surface-soft"><YardimIkonu /><span className="flex-1 text-[14px] font-bold text-lp-text">Kullanım Bilgisi & Destek</span><OkIkonu /></Link>
        <div className="h-2.5" />
        <Link href="/legal/privacy" className="flex items-center gap-3.5 rounded-2xl border border-lp-border bg-lp-surface p-4 text-lp-muted hover:bg-lp-surface-soft"><KalkanIkonu /><span className="flex-1 text-[14px] font-bold text-lp-text">Gizlilik ve Güvenlik politikası</span><OkIkonu /></Link>
      </div>

      <VitrinQrSheet slug={publicLink ? storeSlug : null} acik={qrAcik} kapat={() => setQrAcik(false)} />
    </main>
  );
}
