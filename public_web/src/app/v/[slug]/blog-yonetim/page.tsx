"use client";

import { useEffect, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { sahipOturumuAc } from "@/lib/ownerCookie";

/**
 * Blog yönetim sayfası — sahibin tüm yazılarını gördüğü ve yeni yazı
 * oluşturabildiği yüzey.
 *
 * Flutter'daki BlogPostListScreen'in web karşılığı.
 * Sahip çerezi /app panosundan bağımsız olarak kendi kendine kurulur.
 */

interface Yazi {
  id: string;
  title: string;
  slug: string;
  summary: string | null;
  status: string;
  article_type: string | null;
  seo_score: number | null;
  cover_image_url: string | null;
  created_at: string;
  updated_at: string;
  published_at: string | null;
}

interface VixrexKutuphaneYazisi {
  id: string;
  title: string;
  slug: string;
  summary: string | null;
  cover_image_url: string | null;
  reading_minutes: number | null;
  primary_topic: string | null;
  purpose: string | null;
}

type ImportMode = "linked_excerpt" | "adaptable_draft";

const KUTUPHANE_LIMIT = 20;

const DURUM_ETIKET: Record<string, { metin: string; renk: string }> = {
  draft: { metin: "Taslak", renk: "bg-amber-500/20 text-amber-400" },
  review: { metin: "İnceleme", renk: "bg-blue-500/20 text-blue-400" },
  published: { metin: "Yayında", renk: "bg-green-500/20 text-green-400" },
  rejected: { metin: "Reddedildi", renk: "bg-red-500/20 text-red-400" },
};

export default function BlogYonetimPage() {
  const params = useParams();
  const router = useRouter();
  const slug = params.slug as string;

  const [yazilar, setYazilar] = useState<Yazi[]>([]);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [hata, setHata] = useState<string | null>(null);
  const [yeniBaslik, setYeniBaslik] = useState("");
  const [olusturuyor, setOlusturuyor] = useState(false);
  const [kutuphaneAcik, setKutuphaneAcik] = useState(false);
  const [kutuphaneYazilari, setKutuphaneYazilari] = useState<VixrexKutuphaneYazisi[]>([]);
  const [kutuphaneYukleniyor, setKutuphaneYukleniyor] = useState(false);
  const [iceAktarilanId, setIceAktarilanId] = useState<string | null>(null);

  const yaziListesiniGetir = useCallback(async () => {
    setHata(null);

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

    try {
      const res = await fetch(
        `/api/articles?slug=${encodeURIComponent(slug)}`
      );
      const sonuc = await res.json();
      if (!res.ok) {
        // 401 = çerez düşmüş, bir kez yenile
        if (res.status === 401) {
          const kuruldu = await sahipOturumuAc();
          if (kuruldu) {
            const res2 = await fetch(
              `/api/articles?slug=${encodeURIComponent(slug)}`
            );
            const sonuc2 = await res2.json();
            if (res2.ok) {
              setYazilar(sonuc2.yaziListesi ?? []);
              return;
            }
          }
          setHata(
            "Oturumunuz bulunamadı veya süresi dolmuş. Panodan giriş yapın."
          );
          return;
        }
        setHata(sonuc.hata || "Yazılar yüklenemedi.");
        return;
      }
      setYazilar(sonuc.yaziListesi ?? []);
    } catch {
      setHata("Bağlantı kurulamadı.");
    } finally {
      setYukleniyor(false);
    }
  }, [slug, router]);

  useEffect(() => {
    async function init() {
      await sahipOturumuAc();
      await yaziListesiniGetir();
    }
    void init();
  }, [yaziListesiniGetir]);

  async function yaziOlustur() {
    if (!yeniBaslik.trim()) return;
    setOlusturuyor(true);

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

    try {
      const res = await fetch("/api/articles", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug, title: yeniBaslik.trim() }),
      });
      const sonuc = await res.json();
      if (!res.ok) {
        setHata(sonuc.hata || "Yazı oluşturulamadı.");
        return;
      }
      router.push(`/v/${slug}/blog-yonetim/${sonuc.slug}`);
    } catch {
      setHata("Bağlantı kurulamadı.");
    } finally {
      setOlusturuyor(false);
    }
  }

  async function kutuphaneyiGetir() {
    if (kutuphaneYukleniyor) return;
    setKutuphaneYukleniyor(true);
    setHata(null);
    try {
      const { data, error } = await supabase
        .from("vixrex_blog_articles")
        .select(
          "id,title,slug,summary,cover_image_url,reading_minutes,primary_topic,purpose",
        )
        .eq("status", "published")
        .order("published_at", { ascending: false })
        .range(0, KUTUPHANE_LIMIT - 1);

      if (error) {
        setHata("Vixrex kütüphanesi yüklenemedi.");
        return;
      }
      setKutuphaneYazilari((data ?? []) as VixrexKutuphaneYazisi[]);
    } catch {
      setHata("Vixrex kütüphanesine bağlanılamadı.");
    } finally {
      setKutuphaneYukleniyor(false);
    }
  }

  async function kutuphaneAcKapat() {
    const yeniDurum = !kutuphaneAcik;
    setKutuphaneAcik(yeniDurum);
    if (yeniDurum && kutuphaneYazilari.length === 0) {
      await kutuphaneyiGetir();
    }
  }

  async function vixrexYazisiniIceAktar(
    kaynak: VixrexKutuphaneYazisi,
    mode: ImportMode,
  ) {
    if (iceAktarilanId) return;
    setIceAktarilanId(kaynak.id);
    setHata(null);

    const istek = () =>
      fetch("/api/articles/import-vixrex", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug,
          sourceArticleId: kaynak.id,
          mode,
        }),
      });

    try {
      let res = await istek();
      if (res.status === 401 && (await sahipOturumuAc())) {
        res = await istek();
      }
      const sonuc = await res.json();
      if (!res.ok) {
        setHata(sonuc.hata || "Yazı vitrininize eklenemedi.");
        return;
      }
      router.push(`/v/${slug}/blog-yonetim/${sonuc.yaziSlug}`);
    } catch {
      setHata("Yazı vitrininize eklenemedi. Bağlantıyı kontrol edin.");
    } finally {
      setIceAktarilanId(null);
    }
  }

  async function yaziSil(articleId: string) {
    if (!window.confirm("Bu yazıyı silmek istediğinden emin misin?")) return;

    let {
      data: { session },
    } = await supabase.auth.getSession();
    if (!session) {
      try {
        const { data: anonData } = await supabase.auth.signInAnonymously();
        if (anonData?.session) session = anonData.session;
        else return;
      } catch {
        return;
      }
    }

    try {
      const res = await fetch("/api/articles", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ articleId, slug }),
      });
      if (!res.ok) {
        const sonuc = await res.json();
        setHata(sonuc.hata || "Yazı silinemedi.");
        return;
      }
      await yaziListesiniGetir();
    } catch {
      setHata("Bağlantı kurulamadı.");
    }
  }

  const formatDateTR = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString("tr-TR", {
      day: "numeric",
      month: "long",
      year: "numeric",
    });

  return (
    <main className="owner-shell px-4 py-8 sm:px-6">
      <div className="mx-auto flex w-full max-w-[720px] flex-col gap-6">
        <div className="flex items-center justify-between gap-3 rounded-2xl owner-card px-4 py-3">
          <Link
            href={`/v/${slug}`}
            className="inline-flex items-center gap-1 text-sm font-extrabold text-[var(--owner-secondary)]"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
            >
              <polyline points="15 18 9 12 15 6" />
            </svg>
            Vitrine Dön
          </Link>
          <span className="text-xs font-extrabold text-[var(--owner-muted)]">
            Blog Yönetimi
          </span>
        </div>

        <h1 className="text-2xl font-extrabold text-[var(--owner-text)]">Yazı Yönetimi</h1>

        {hata && (
          <div
            className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-400"
            role="alert"
          >
            {hata}
          </div>
        )}

        <div className="rounded-2xl owner-card p-4">
          <h2 className="mb-3 text-sm font-extrabold text-[var(--owner-text)]">
            Yeni Yazı Oluştur
          </h2>
          <div className="flex gap-2">
            <input
              type="text"
              value={yeniBaslik}
              onChange={(e) => setYeniBaslik(e.target.value)}
              placeholder="Yazı başlığı..."
              className="flex-1 rounded-xl border border-[var(--owner-border)] bg-white/5 px-3 py-2.5 text-sm text-[var(--owner-text)] placeholder:text-[var(--owner-muted)] focus:border-[var(--owner-primary)] focus:outline-none"
              onKeyDown={(e) => {
                if (e.key === "Enter") void yaziOlustur();
              }}
            />
            <button
              onClick={() => void yaziOlustur()}
              disabled={olusturuyor || !yeniBaslik.trim()}
              className="shrink-0 rounded-xl bg-[var(--owner-primary)] px-4 py-2.5 text-sm font-extrabold text-[var(--owner-on-primary)] transition hover:brightness-110 disabled:opacity-50"
            >
              {olusturuyor ? "Oluşturuluyor..." : "Oluştur"}
            </button>
          </div>
        </div>

        <section className="rounded-2xl owner-card p-4">
          <div className="flex items-center justify-between gap-3">
            <div>
              <h2 className="text-sm font-extrabold text-[var(--owner-text)]">
                Vixrex Kütüphanesinden Yazı Ekle
              </h2>
              <p className="mt-1 text-xs text-[var(--owner-muted)]">
                Yayındaki bir Vixrex rehberini vitrininize taslak olarak alın.
              </p>
            </div>
            <button
              type="button"
              onClick={() => void kutuphaneAcKapat()}
              className="owner-button-secondary shrink-0"
              aria-expanded={kutuphaneAcik}
            >
              {kutuphaneAcik ? "Kapat" : "Kütüphaneyi Aç"}
            </button>
          </div>

          {kutuphaneAcik ? (
            <div className="mt-4 space-y-3 border-t border-[var(--owner-border)] pt-4">
              {kutuphaneYukleniyor ? (
                <p className="text-sm text-[var(--owner-muted)]" role="status">
                  Kütüphane yükleniyor…
                </p>
              ) : kutuphaneYazilari.length === 0 ? (
                <p className="text-sm text-[var(--owner-muted)]">
                  Şu anda yayında Vixrex yazısı bulunmuyor.
                </p>
              ) : (
                kutuphaneYazilari.map((kaynak) => {
                  const isleniyor = iceAktarilanId === kaynak.id;
                  return (
                    <article
                      key={kaynak.id}
                      className="rounded-xl border border-[var(--owner-border)] p-3"
                    >
                      <div className="flex gap-3">
                        {kaynak.cover_image_url ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img
                            src={kaynak.cover_image_url}
                            alt=""
                            className="h-14 w-14 shrink-0 rounded-lg object-cover"
                          />
                        ) : null}
                        <div className="min-w-0 flex-1">
                          <h3 className="text-sm font-extrabold text-[var(--owner-text)]">
                            {kaynak.title}
                          </h3>
                          {kaynak.summary ? (
                            <p className="mt-1 line-clamp-2 text-xs text-[var(--owner-muted)]">
                              {kaynak.summary}
                            </p>
                          ) : null}
                          <div className="mt-2 flex flex-wrap gap-1 text-[10px] font-bold text-[var(--owner-muted)]">
                            {kaynak.reading_minutes ? <span>{kaynak.reading_minutes} dk</span> : null}
                            {kaynak.primary_topic ? <span>· {kaynak.primary_topic}</span> : null}
                          </div>
                        </div>
                      </div>
                      <div className="mt-3 grid gap-2 sm:grid-cols-2">
                        <button
                          type="button"
                          disabled={Boolean(iceAktarilanId)}
                          onClick={() => void vixrexYazisiniIceAktar(kaynak, "linked_excerpt")}
                          className="owner-button-secondary justify-center disabled:opacity-50"
                        >
                          {isleniyor ? "Ekleniyor…" : "Kaynak bağlantılı kısa sürüm"}
                        </button>
                        <button
                          type="button"
                          disabled={Boolean(iceAktarilanId)}
                          onClick={() => void vixrexYazisiniIceAktar(kaynak, "adaptable_draft")}
                          className="owner-button-primary justify-center disabled:opacity-50"
                        >
                          {isleniyor ? "Ekleniyor…" : "Uyarlanabilir taslak"}
                        </button>
                      </div>
                    </article>
                  );
                })
              )}
              {kutuphaneYazilari.length >= KUTUPHANE_LIMIT ? (
                <p className="text-[11px] text-[var(--owner-muted)]">
                  İlk {KUTUPHANE_LIMIT} yayındaki yazı gösteriliyor. Kütüphane istemciye sınırsız yüklenmez.
                </p>
              ) : null}
            </div>
          ) : null}
        </section>

        {yukleniyor ? (
          <div className="flex items-center justify-center py-12">
            <div className="h-4 w-4 animate-pulse rounded-full bg-[var(--owner-primary)]" />
          </div>
        ) : yazilar.length === 0 ? (
          <div className="rounded-2xl owner-card py-12 text-center">
            <p className="text-sm text-[var(--owner-muted)]">
              Henüz yazınız yok. Yukarıdaki seçeneklerden ilk yazınızı oluşturun.
            </p>
          </div>
        ) : (
          <div className="space-y-2">
            {yazilar.map((yazi) => {
              const durum = DURUM_ETIKET[yazi.status] ?? DURUM_ETIKET.draft;
              return (
                <div
                  key={yazi.id}
                  className="flex items-center gap-4 rounded-2xl owner-card p-4 transition hover:border-[var(--owner-border)]"
                >
                  {yazi.cover_image_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={yazi.cover_image_url}
                      alt=""
                      className="h-16 w-16 shrink-0 rounded-xl object-cover"
                    />
                  ) : (
                    <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-xl bg-white/5 text-xl text-[var(--owner-muted)]">
                      📝
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <h3 className="truncate text-sm font-extrabold text-[var(--owner-text)]">
                        {yazi.title}
                      </h3>
                      <span
                        className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-extrabold ${durum.renk}`}
                      >
                        {durum.metin}
                      </span>
                    </div>
                    {yazi.summary && (
                      <p className="mt-1 line-clamp-1 text-xs text-[var(--owner-muted)]">
                        {yazi.summary}
                      </p>
                    )}
                    <p className="mt-1 text-[10px] font-bold text-[var(--owner-muted)]">
                      {formatDateTR(yazi.updated_at)}
                      {yazi.seo_score != null && yazi.seo_score > 0 && (
                        <span className="ml-2 text-[var(--owner-secondary)]">
                          SEO: %{yazi.seo_score}
                        </span>
                      )}
                    </p>
                  </div>
                  <div className="flex shrink-0 gap-1">
                    <Link
                      href={`/v/${slug}/blog-yonetim/${yazi.slug}`}
                      className="rounded-lg border border-[var(--owner-primary)] px-2.5 py-1.5 text-[10px] font-extrabold text-[var(--owner-primary)] transition hover:brightness-110"
                    >
                      Düzenle
                    </Link>
                    <Link
                      href={`/v/${slug}/yazilar/${yazi.slug}`}
                      className="rounded-lg border border-[var(--owner-border)] px-2.5 py-1.5 text-[10px] font-extrabold text-[var(--owner-text-alt)] transition hover:border-[var(--owner-border)] hover:text-[var(--owner-text)]"
                    >
                      Gör
                    </Link>
                    <button
                      onClick={() => void yaziSil(yazi.id)}
                      className="rounded-lg border border-red-500/20 px-2.5 py-1.5 text-[10px] font-extrabold text-red-400/60 transition hover:border-red-500/40 hover:text-red-400"
                    >
                      Sil
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}
