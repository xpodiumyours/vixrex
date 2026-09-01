"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";

interface Bildirim {
  id: string;
  title: string;
  body: string;
  store_slug: string | null;
  type: string;
  created_at: string;
  read_at: string | null;
}

export default function BildirimlerPage() {
  const router = useRouter();
  const [bildirimler, setBildirimler] = useState<Bildirim[]>([]);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [isleniyor, setIsleniyor] = useState(false);
  const [hata, setHata] = useState("");

  async function bildirimleriGetir() {
    setHata("");
    const { data, error } = await supabase
      .from("notification_inbox")
      .select("id,title,body,store_slug,type,created_at,read_at")
      .order("created_at", { ascending: false })
      .limit(50);
    if (error) {
      setHata("Bildirimler yüklenemedi. Lütfen tekrar dene.");
      setBildirimler([]);
    } else {
      setBildirimler((data as Bildirim[]) ?? []);
    }
    setYukleniyor(false);
  }

  useEffect(() => {
    async function init() {
      let { data: { session } } = await supabase.auth.getSession();
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
      await bildirimleriGetir();
    }
    void init();
  }, [router]);

  async function tumunuOkunduYap() {
    setIsleniyor(true);
    const { error } = await supabase
      .from("notification_inbox")
      .update({ read_at: new Date().toISOString() })
      .is("read_at", null);
    if (error) setHata("Bildirimler güncellenemedi. Lütfen tekrar dene.");
    await bildirimleriGetir();
    setIsleniyor(false);
  }

  async function bildirimiAc(bildirim: Bildirim) {
    if (!bildirim.read_at) {
      await supabase
        .from("notification_inbox")
        .update({ read_at: new Date().toISOString() })
        .eq("id", bildirim.id);
    }
    if (bildirim.store_slug && bildirim.type === "booking") {
      router.push(`/v/${bildirim.store_slug}/randevu-yonetim`);
      return;
    }
    await bildirimleriGetir();
  }

  const okunmamisVar = bildirimler.some((bildirim) => !bildirim.read_at);

  return (
    <main className="owner-shell">
      <header className="border-b border-[var(--owner-border)] bg-[var(--owner-bg)]/90 px-4 py-4 sm:px-6">
        <div className="mx-auto flex max-w-3xl items-center justify-between gap-3">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--owner-secondary)]">Vixrex</p>
            <h1 className="mt-1 text-xl font-bold text-[var(--owner-text)]">Bildirimler</h1>
          </div>
          <Link href="/app" className="owner-button-secondary min-h-11 px-4 py-2 text-sm">Panoya dön</Link>
        </div>
      </header>

      <div className="mx-auto max-w-3xl px-4 py-8 sm:px-6">
        <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
          <p className="text-sm text-[var(--owner-muted)]">Randevu talepleri ve durum güncellemeleri burada görünür.</p>
          {okunmamisVar ? (
            <button type="button" onClick={tumunuOkunduYap} disabled={isleniyor} className="owner-button-secondary min-h-11 px-4 py-2 text-sm">
              {isleniyor ? "İşleniyor…" : "Tümünü okundu yap"}
            </button>
          ) : null}
        </div>

        {hata ? <p className="owner-error mb-4 text-sm" role="alert">{hata}</p> : null}
        {yukleniyor ? (
          <div className="owner-card p-5 text-sm text-[var(--owner-muted)]" role="status">Bildirimler yükleniyor…</div>
        ) : bildirimler.length === 0 ? (
          <div className="owner-card p-8 text-center text-sm leading-6 text-[var(--owner-muted)]">
            Henüz bildirim yok. Yeni randevu talepleri ve durum güncellemeleri burada görünür.
          </div>
        ) : (
          <div className="space-y-3">
            {bildirimler.map((bildirim) => (
              <button key={bildirim.id} type="button" onClick={() => bildirimiAc(bildirim)} className="owner-card owner-link flex w-full items-start gap-3 p-4 text-left">
                <span className={`mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full ${bildirim.read_at ? "bg-[var(--owner-border)]" : "bg-[var(--owner-primary)]"}`} aria-hidden="true" />
                <span className="min-w-0 flex-1">
                  <span className={`block text-sm text-[var(--owner-text)] ${bildirim.read_at ? "font-bold" : "font-black"}`}>{bildirim.title}</span>
                  <span className="mt-1 block text-sm leading-6 text-[var(--owner-muted)]">{bildirim.body}</span>
                  <time className="mt-2 block text-xs text-[var(--owner-muted)]" dateTime={bildirim.created_at}>
                    {new Intl.DateTimeFormat("tr-TR", { dateStyle: "medium", timeStyle: "short" }).format(new Date(bildirim.created_at))}
                  </time>
                </span>
              </button>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
