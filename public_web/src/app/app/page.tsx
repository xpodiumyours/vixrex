"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import type { User } from "@supabase/supabase-js";

interface Store {
  id: string;
  slug: string;
  name: string;
  is_published: boolean;
  kategori: string | null;
  updated_at: string | null;
}

export const dynamic = "force-dynamic";

export default function AppPage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [stores, setStores] = useState<Store[]>([]);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [olusturuyor, setOlusturuyor] = useState(false);
  const [yeniAd, setYeniAd] = useState("");
  const [hata, setHata] = useState("");

  async function magazalariGetir(userId: string) {
    setYukleniyor(true);
    const { data, error } = await supabase
      .from("stores")
      .select("id, slug, name, is_published, kategori, updated_at")
      .eq("user_id", userId)
      .order("updated_at", { ascending: false });

    if (error) {
      setHata("Vitrin bilgileri yüklenemedi. Lütfen sayfayı yenileyip tekrar dene.");
    }
    setStores((data as Store[]) ?? []);
    setYukleniyor(false);
  }

  useEffect(() => {
    async function init() {
      const {
        data: { session },
      } = await supabase.auth.getSession();
      if (!session) {
        router.push("/giris");
        return;
      }
      setUser(session.user);
      await magazalariGetir(session.user.id);
    }
    init();
  }, [router]);

  async function magazaOlustur(e: React.FormEvent) {
    e.preventDefault();
    setHata("");

    if (!yeniAd.trim()) {
      setHata("İşletme adı zorunludur.");
      return;
    }

    setOlusturuyor(true);

    const {
      data: { session },
    } = await supabase.auth.getSession();
    if (!session) {
      setHata("Oturum bulunamadı.");
      setOlusturuyor(false);
      return;
    }

    const res = await fetch("/api/create-store", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({ name: yeniAd.trim() }),
    });

    const sonuc = await res.json();
    setOlusturuyor(false);

    if (!res.ok) {
      setHata(sonuc.hata || "Vitrin oluşturulamadı.");
      return;
    }

    // Vitrin oluşturuldu — owner session kur ve vitrine git
    // Basitleştirme: edit_token ile owner-session'a geç
    if (sonuc.slug && sonuc.editToken) {
      await fetch(
        `/api/owner-session?slug=${sonuc.slug}&ocode=${sonuc.editToken}`,
        { redirect: "manual" }
      );
      // owner-session redirect zincirini takip et
      router.push(`/v/${sonuc.slug}`);
    }
  }

  async function cikisYap() {
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  }

  if (yukleniyor) {
    return (
      <main className="owner-shell flex items-center justify-center px-4">
        <div className="owner-card flex items-center gap-3 px-5 py-4" role="status" aria-live="polite">
          <span className="h-3 w-3 animate-pulse rounded-full bg-[var(--owner-primary)]" aria-hidden="true" />
          <span className="text-sm text-[var(--owner-muted)]">Vitrinin yükleniyor…</span>
        </div>
      </main>
    );
  }

  return (
    <main className="owner-shell">
      <header className="border-b border-[var(--owner-border)] bg-[var(--owner-bg)]/90 px-4 py-4 sm:px-6">
        <div className="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-3">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--owner-secondary)]">Vixrex</p>
            <h1 className="mt-1 text-xl font-bold text-[var(--owner-text)]">Vitrinim</h1>
          </div>
          <div className="flex min-w-0 items-center gap-3">
            <span className="max-w-44 truncate text-xs text-[var(--owner-muted)] sm:max-w-none">{user?.email}</span>
            <button
              type="button"
              onClick={cikisYap}
              className="owner-button-secondary min-h-11 shrink-0 px-4 py-2 text-xs"
            >
              Çıkış Yap
            </button>
          </div>
        </div>
      </header>

      <div className="mx-auto max-w-5xl px-4 py-8 sm:px-6 sm:py-10">
        <div className="mb-6 max-w-2xl">
          <h2 className="text-2xl font-bold text-[var(--owner-text)] sm:text-3xl">
            Vitrinini yönet
          </h2>
          <p className="mt-2 text-sm leading-6 text-[var(--owner-muted)] sm:text-base">
            İşletme bilgilerini, ürünlerini ve yayın durumunu aynı vitrin üzerinden yönet.
          </p>
        </div>

        {hata ? <p className="owner-error mb-6 text-sm" role="alert">{hata}</p> : null}

        {stores.length === 0 ? (
          <section className="owner-card p-5 sm:p-8" aria-labelledby="vitrin-olustur-title">
            <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(20rem,0.8fr)] lg:items-start">
              <div>
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--owner-secondary)]">İlk Adım</p>
                <h2 id="vitrin-olustur-title" className="mt-2 text-xl font-bold text-[var(--owner-text)]">
                  Vitrinini oluştur
                </h2>
                <p className="mt-2 max-w-lg text-sm leading-6 text-[var(--owner-muted)]">
                  İşletme adınla başla. Sonraki adımda vitrinini düzenleyip ürünlerini ekleyebilirsin.
                </p>
              </div>
              <form onSubmit={magazaOlustur} className="space-y-4" aria-busy={olusturuyor}>
                <div className="space-y-2">
                  <label htmlFor="isletme-adi" className="owner-label">İşletme Adı</label>
                  <input
                    id="isletme-adi"
                    type="text"
                    placeholder="Ör. Aymira Giyim"
                    value={yeniAd}
                    onChange={(e) => setYeniAd(e.target.value)}
                    className="owner-input text-sm"
                    autoComplete="organization"
                    required
                  />
                </div>
                <button type="submit" disabled={olusturuyor} className="owner-button-primary w-full">
                  {olusturuyor ? "Vitrin oluşturuluyor…" : "Vitrin Oluştur"}
                </button>
              </form>
            </div>
          </section>
        ) : (
          <section aria-labelledby="vitrinim-title">
            <h2 id="vitrinim-title" className="sr-only">Vitrinim</h2>
            <div className="grid gap-4">
              {stores.map((magaza) => (
                <Link
                  key={magaza.id}
                  href={`/v/${magaza.slug}`}
                  className="owner-card owner-link group block p-5 no-underline transition hover:border-[var(--owner-primary)] sm:p-6"
                >
                  <div className="flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
                    <div className="min-w-0">
                      <div className="flex flex-wrap items-center gap-3">
                        <h3 className="truncate text-lg font-bold text-[var(--owner-text)] group-hover:text-[var(--owner-secondary)]">
                          {magaza.name}
                        </h3>
                        <span
                          className={`rounded-full border px-2.5 py-1 text-xs font-bold ${
                            magaza.is_published
                              ? "border-[var(--owner-success)]/40 bg-[var(--owner-success)]/10 text-[var(--owner-success)]"
                              : "border-[var(--owner-warning)]/40 bg-[var(--owner-warning)]/10 text-[var(--owner-warning)]"
                          }`}
                        >
                          {magaza.is_published ? "Yayında" : "Taslak"}
                        </span>
                      </div>
                      <p className="mt-2 truncate text-xs text-[var(--owner-muted)]">
                        /v/{magaza.slug}
                      </p>
                      {magaza.kategori ? (
                        <p className="mt-2 text-sm text-[var(--owner-text-alt)]">{magaza.kategori}</p>
                      ) : null}
                    </div>
                    <span className="owner-button-primary inline-flex shrink-0 items-center justify-center sm:min-w-40">
                      Vitrini Yönet
                    </span>
                  </div>
                </Link>
              ))}
            </div>
          </section>
        )}
      </div>
    </main>
  );
}
