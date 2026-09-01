"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";

interface VitrinDurumu {
  slug: string;
  name: string;
  is_published: boolean;
}

interface BootstrapOwnerState {
  has_store?: boolean;
  slug?: string;
}

export default function HesapPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [vitrin, setVitrin] = useState<VitrinDurumu | null>(null);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [islem, setIslem] = useState<"unpublish" | "store" | "account" | null>(null);
  const [vitrinOnayi, setVitrinOnayi] = useState("");
  const [hesapOnayi, setHesapOnayi] = useState("");
  const [hata, setHata] = useState("");
  const [bilgi, setBilgi] = useState("");

  useEffect(() => {
    async function init() {
      let { data: sessionData } = await supabase.auth.getSession();
      let session = sessionData.session;
      if (!session) {
        try {
          const { data: anonData } = await supabase.auth.signInAnonymously();
          if (anonData?.session) session = anonData.session;
          else {
            router.replace("/giris");
            return;
          }
        } catch {
          router.replace("/giris");
          return;
        }
      }
      setEmail(session.user.email ?? "");

      const { data: durum, error: durumHatasi } = await supabase.rpc(
        "bootstrap_owner_state"
      );
      const sonuc = (durum ?? {}) as BootstrapOwnerState;
      if (durumHatasi) {
        setHata("Vitrin bilgileri yüklenemedi.");
      } else if (sonuc.has_store && sonuc.slug) {
        const { data, error } = await supabase
          .from("stores")
          .select("slug, name, is_published")
          .eq("slug", sonuc.slug)
          .maybeSingle();
        if (error) setHata("Vitrin bilgileri yüklenemedi.");
        else setVitrin(data as VitrinDurumu | null);
      }
      setYukleniyor(false);
    }
    void init();
  }, [router]);

  async function tokenGetir() {
    const { data } = await supabase.auth.getSession();
    return data.session?.access_token ?? "";
  }

  async function yayindanKaldir() {
    if (!vitrin) return;
    setIslem("unpublish");
    setHata("");
    setBilgi("");
    const token = await tokenGetir();
    const response = await fetch("/api/account", {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ slug: vitrin.slug }),
    });
    const sonuc = await response.json();
    if (response.ok) {
      setVitrin({ ...vitrin, is_published: false });
      setBilgi("Vitrinin yayından kaldırıldı. Verileriniz korunur.");
    } else {
      setHata(sonuc.hata || "Vitrin yayından kaldırılamadı.");
    }
    setIslem(null);
  }

  async function vitriniSil() {
    if (!vitrin || vitrinOnayi.trim() !== "SİL") return;
    setIslem("store");
    setHata("");
    setBilgi("");
    const token = await tokenGetir();
    const response = await fetch("/api/account", {
      method: "DELETE",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        target: "store",
        slug: vitrin.slug,
        confirmation: vitrinOnayi,
      }),
    });
    const sonuc = await response.json();
    if (response.ok) {
      setVitrin(null);
      setVitrinOnayi("");
      setBilgi("Vitrinin kalıcı olarak silindi. Hesabın açık kalmaya devam ediyor.");
    } else {
      setHata(sonuc.hata || "Vitrin silinemedi.");
    }
    setIslem(null);
  }

  async function hesabiSil() {
    if (hesapOnayi.trim() !== "SİL") return;
    setIslem("account");
    setHata("");
    setBilgi("");
    const token = await tokenGetir();
    const response = await fetch("/api/account", {
      method: "DELETE",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        target: "account",
        slug: vitrin?.slug,
        confirmation: hesapOnayi,
      }),
    });
    const sonuc = await response.json();
    if (!response.ok) {
      setHata(sonuc.hata || "Hesap silinemedi.");
      setIslem(null);
      return;
    }

    await supabase.auth.signOut({ scope: "local" });
    router.replace("/");
    router.refresh();
  }

  if (yukleniyor) {
    return <main className="owner-shell flex items-center justify-center"><p role="status">Hesap bilgileri yükleniyor…</p></main>;
  }

  const mesgul = islem !== null;
  return (
    <main className="owner-shell px-4 py-8 sm:px-6">
      <div className="mx-auto flex max-w-3xl flex-col gap-5" aria-busy={mesgul}>
        <header className="owner-card p-5">
          <Link href="/app" className="text-sm font-bold text-[var(--owner-secondary)]">← Vitrinime Dön</Link>
          <h1 className="mt-2 text-2xl font-extrabold text-[var(--owner-text)]">Hesap ve Veri Yönetimi</h1>
          <p className="mt-2 text-sm text-[var(--owner-muted)]">{email}</p>
        </header>

        {hata ? <p className="owner-error" role="alert">{hata}</p> : null}
        {bilgi ? <p className="owner-card p-4 text-sm font-bold text-[var(--owner-success)]" role="status">{bilgi}</p> : null}

        {vitrin ? (
          <section className="owner-card p-5" aria-labelledby="unpublish-title">
            <h2 id="unpublish-title" className="text-lg font-extrabold text-[var(--owner-text)]">Vitrini Yayından Kaldır</h2>
            <p className="mt-2 text-sm leading-6 text-[var(--owner-muted)]">
              Vitrinin müşterilere ve Keşfet sayfasına kapanır. Verileriniz korunur; yeniden yayınlayabilirsiniz.
            </p>
            <button type="button" className="owner-button-secondary mt-4" disabled={mesgul || !vitrin.is_published} onClick={() => void yayindanKaldir()}>
              {vitrin.is_published ? (islem === "unpublish" ? "Yayından kaldırılıyor…" : "Vitrini Yayından Kaldır") : "Vitrin Yayında Değil"}
            </button>
          </section>
        ) : null}

        {vitrin ? (
          <section className="owner-card border-[var(--owner-error)] p-5" aria-labelledby="delete-store-title">
            <h2 id="delete-store-title" className="text-lg font-extrabold text-[var(--owner-error)]">Vitrini Kalıcı Sil</h2>
            <p className="mt-2 text-sm leading-6 text-[var(--owner-muted)]">
              Vitrininiz, ürünleriniz, blog yazılarınız ve randevularınız kalıcı olarak silinir. Hesabınız açık kalır. Bu işlem geri alınamaz.
            </p>
            <label className="owner-label mt-4 block" htmlFor="vitrin-sil-onay">Onaylamak için SİL yazın</label>
            <input id="vitrin-sil-onay" className="owner-input mt-2" placeholder="SİL" value={vitrinOnayi} onChange={(event) => setVitrinOnayi(event.target.value)} />
            <button type="button" className="mt-3 rounded-xl bg-[var(--owner-error)] px-4 py-3 text-sm font-extrabold text-white disabled:opacity-50" disabled={mesgul || vitrinOnayi.trim() !== "SİL"} onClick={() => void vitriniSil()}>
              {islem === "store" ? "Vitrin siliniyor…" : "Vitrini Kalıcı Sil"}
            </button>
          </section>
        ) : null}

        <section className="owner-card border-[var(--owner-error)] p-5" aria-labelledby="delete-account-title">
          <h2 id="delete-account-title" className="text-lg font-extrabold text-[var(--owner-error)]">Hesabı Kalıcı Sil</h2>
          <p className="mt-2 text-sm leading-6 text-[var(--owner-muted)]">
            Giriş hesabınız ve varsa vitrininizle bağlantılı tüm veriler kalıcı olarak silinir. Bu işlem geri alınamaz.
          </p>
          <label className="owner-label mt-4 block" htmlFor="hesap-sil-onay">Onaylamak için SİL yazın</label>
          <input id="hesap-sil-onay" className="owner-input mt-2" placeholder="SİL" value={hesapOnayi} onChange={(event) => setHesapOnayi(event.target.value)} />
          <button type="button" className="mt-3 rounded-xl bg-[var(--owner-error)] px-4 py-3 text-sm font-extrabold text-white disabled:opacity-50" disabled={mesgul || hesapOnayi.trim() !== "SİL"} onClick={() => void hesabiSil()}>
            {islem === "account" ? "Hesap siliniyor…" : "Hesabı Kalıcı Sil"}
          </button>
        </section>
      </div>
    </main>
  );
}
