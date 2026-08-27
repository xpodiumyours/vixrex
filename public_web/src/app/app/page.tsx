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
    const { data } = await supabase
      .from("stores")
      .select("id, slug, name, is_published, kategori, updated_at")
      .eq("user_id", userId)
      .order("updated_at", { ascending: false });

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
      const sessionRes = await fetch(
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
      <main className="flex min-h-screen items-center justify-center bg-[#0c0d10] text-white/50">
        Yükleniyor…
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-[#0c0d10] text-[#f4f1ea]">
      <header className="border-b border-white/8 px-6 py-4">
        <div className="mx-auto flex max-w-4xl items-center justify-between">
          <h1 className="text-lg font-bold">Vixrex Yönetim Paneli</h1>
          <div className="flex items-center gap-4">
            <span className="text-xs text-white/40">{user?.email}</span>
            <button
              onClick={cikisYap}
              className="rounded-lg border border-white/10 px-3 py-1.5 text-xs text-white/60 hover:bg-white/5"
            >
              Çıkış Yap
            </button>
          </div>
        </div>
      </header>

      <div className="mx-auto max-w-4xl px-6 py-8">
        {/* Yeni Vitrin Oluştur */}
        <section className="mb-8 rounded-2xl border border-white/8 bg-[#15171c] p-6">
          <h2 className="mb-4 text-base font-bold">Yeni Vitrin Oluştur</h2>
          <form onSubmit={magazaOlustur} className="flex gap-3">
            <input
              type="text"
              placeholder="İşletme adı (ör: Aymira Giyim)"
              value={yeniAd}
              onChange={(e) => setYeniAd(e.target.value)}
              className="flex-1 rounded-xl border border-white/10 bg-[#0c0d10] px-3 py-2.5 text-sm outline-none focus:border-blue-500"
            />
            <button
              type="submit"
              disabled={olusturuyor}
              className="shrink-0 rounded-xl bg-gradient-to-r from-blue-600 to-blue-700 px-5 py-2.5 text-sm font-bold text-white shadow-md transition hover:shadow-blue-500/30 disabled:opacity-60"
            >
              {olusturuyor ? "Oluşturuluyor…" : "Oluştur"}
            </button>
          </form>
          {hata && <p className="mt-2 text-xs text-red-400">{hata}</p>}
        </section>

        {/* Vitrinlerim */}
        <section>
          <h2 className="mb-4 text-base font-bold">Vitrinlerim</h2>
          {stores.length === 0 ? (
            <p className="rounded-xl border border-white/5 bg-white/[0.02] p-8 text-center text-sm text-white/40">
              Henüz vitrininiz yok. Yukarıdan yeni bir tane oluşturun.
            </p>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2">
              {stores.map((magaza) => (
                <Link
                  key={magaza.id}
                  href={`/v/${magaza.slug}`}
                  className="group rounded-2xl border border-white/8 bg-[#15171c] p-5 transition hover:border-blue-500/30"
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-bold text-white group-hover:text-blue-400">
                        {magaza.name}
                      </h3>
                      <p className="mt-1 text-xs text-white/40">
                        /v/{magaza.slug}
                      </p>
                    </div>
                    <span
                      className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${
                        magaza.is_published
                          ? "bg-emerald-500/20 text-emerald-400"
                          : "bg-amber-500/20 text-amber-400"
                      }`}
                    >
                      {magaza.is_published ? "Yayında" : "Taslak"}
                    </span>
                  </div>
                  {magaza.kategori && (
                    <p className="mt-2 text-xs text-white/30">
                      {magaza.kategori}
                    </p>
                  )}
                </Link>
              ))}
            </div>
          )}
        </section>
      </div>
    </main>
  );
}
