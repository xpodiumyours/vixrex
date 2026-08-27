"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

export const dynamic = "force-dynamic";

export default function AyarlarPage() {
  const router = useRouter();
  const [yukleniyor, setYukleniyor] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [exportMsg, setExportMsg] = useState("");

  useEffect(() => {
    async function init() {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        router.push("/giris");
        return;
      }
      setYukleniyor(false);
    }
    init();
  }, [router]);

  async function verileriDisaAktar() {
    setExporting(true);
    setExportMsg("");
    try {
      const { data: durum } = await supabase.rpc("bootstrap_owner_state");
      const sonuc = (durum ?? {}) as { has_store?: boolean; slug?: string };

      const veri: Record<string, unknown> = {
        exported_at: new Date().toISOString(),
        app: "Vixrex",
        user: { email: "mevcut oturum" },
      };

      if (sonuc.has_store && sonuc.slug) {
        // Store verisini çek (sadece公开alanlar)
        const { data: store } = await supabase
          .from("stores")
          .select("id, slug, name, kategori, description, whatsapp, phone, email, address, is_published, created_at, updated_at")
          .eq("slug", sonuc.slug)
          .single();

        if (store) {
          veri.store = store;

          // Ürünleri çek
          const { data: products } = await supabase
            .from("products")
            .select("id, name, slug, description, price_text, category_id, is_visible, created_at")
            .eq("store_id", store.id)
            .eq("is_active", true);

          veri.products = products ?? [];

          // Yazıları çek
          const { data: articles } = await supabase
            .from("store_articles")
            .select("id, slug, title, status, created_at, published_at")
            .eq("store_slug", sonuc.slug);

          veri.articles = articles ?? [];
        }
      }

      // JSON olarak indir
      const jsonText = JSON.stringify(veri, null, 2);
      const blob = new Blob([jsonText], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `vixrex-verilerim-${new Date().toISOString().split("T")[0]}.json`;
      a.click();
      URL.revokeObjectURL(url);

      setExportMsg("Verileriniz indirildi.");
    } catch {
      setExportMsg("Veriler indirilemedi. Lütfen tekrar deneyin.");
    } finally {
      setExporting(false);
    }
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

  return (
    <main className="owner-shell">
      <header className="border-b border-[var(--owner-border)] bg-[var(--owner-bg)]/90 px-4 py-4 sm:px-6">
        <div className="mx-auto flex max-w-3xl items-center gap-3">
          <Link href="/app" className="owner-button-secondary px-3 py-2 text-xs">
            ← Geri
          </Link>
          <h1 className="text-xl font-bold text-[var(--owner-text)]">Ayarlar</h1>
        </div>
      </header>

      <div className="mx-auto max-w-3xl space-y-6 px-4 py-8 sm:px-6">
        {/* Profil Yönetimi */}
        <section className="owner-card p-5 sm:p-6">
          <Link href="/app/profil" className="group flex items-center justify-between no-underline">
            <div>
              <h2 className="text-lg font-bold text-[var(--owner-text)] group-hover:text-[var(--owner-secondary)]">Profil</h2>
              <p className="text-sm text-[var(--owner-muted)]">E-posta, şifre ve vitrin bağlantısı</p>
            </div>
            <span className="text-[var(--owner-muted)]">→</span>
          </Link>
        </section>

        {/* Hesap Yönetimi */}
        <section className="owner-card p-5 sm:p-6">
          <Link href="/app/hesap" className="group flex items-center justify-between no-underline">
            <div>
              <h2 className="text-lg font-bold text-[var(--owner-text)] group-hover:text-[var(--owner-secondary)]">Hesap Yönetimi</h2>
              <p className="text-sm text-[var(--owner-muted)]">Vitrin yayından kaldırma, hesap silme (KVKK)</p>
            </div>
            <span className="text-[var(--owner-muted)]">→</span>
          </Link>
        </section>

        {/* Verilerimi İndir */}
        <section className="owner-card p-5 sm:p-6">
          <h2 className="text-lg font-bold text-[var(--owner-text)]">Verilerimi İndir (KVKK)</h2>
          <p className="mt-1 text-sm text-[var(--owner-muted)]">
            Hesabındaki tüm verileri JSON olarak indir. Bu hakkın KVKK kapsamında garanti altındadır.
          </p>
          {exportMsg && (
            <p className="mt-3 rounded-xl border border-[var(--owner-success)]/40 bg-[var(--owner-success)]/10 p-3 text-sm text-[var(--owner-success)]">
              {exportMsg}
            </p>
          )}
          <button
            type="button"
            className="owner-button-primary mt-4"
            onClick={verileriDisaAktar}
            disabled={exporting}
          >
            {exporting ? "İndiriliyor…" : "📥 Verilerimi İndir"}
          </button>
        </section>

        {/* Yasal Linkler */}
        <section className="owner-card p-5 sm:p-6">
          <h2 className="text-lg font-bold text-[var(--owner-text)]">Yasal</h2>
          <div className="mt-3 space-y-2">
            <a
              href="/legal/privacy"
              target="_blank"
              rel="noopener noreferrer"
              className="block text-sm text-[var(--owner-secondary)] underline"
            >
              Gizlilik Politikası
            </a>
            <a
              href="/legal/terms"
              target="_blank"
              rel="noopener noreferrer"
              className="block text-sm text-[var(--owner-secondary)] underline"
            >
              Kullanım Şartları
            </a>
          </div>
        </section>

        {/* Uygulama Hakkında */}
        <section className="owner-card p-5 sm:p-6">
          <h2 className="text-lg font-bold text-[var(--owner-text)]">Hakkında</h2>
          <div className="mt-3 space-y-1 text-sm text-[var(--owner-muted)]">
            <p>Vixrex — Dijital Vitrin Platformu</p>
            <p>Web uygulaması sürümü</p>
          </div>
        </section>
      </div>
    </main>
  );
}
