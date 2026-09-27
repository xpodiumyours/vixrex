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

interface AsistanKonusu {
  konu: string;
  baslik: string;
  gerekce: string;
}

interface TazelenecekYazi {
  slug: string;
  title: string;
  gun: number;
}

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
  const [konular, setKonular] = useState<AsistanKonusu[]>([]);
  const [tazeleme, setTazeleme] = useState<TazelenecekYazi[]>([]);
  const [asistanIsliyor, setAsistanIsliyor] = useState<string | null>(null);

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
            // Yeniden dene
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

  const asistanOnerileriGetir = useCallback(async () => {
    try {
      const res = await fetch(
        `/api/articles/assistant?slug=${encodeURIComponent(slug)}`
      );
      if (!res.ok) return;
      const sonuc = await res.json();
      setKonular(sonuc.konular ?? []);
      setTazeleme(sonuc.tazeleme ?? []);
    } catch {
      return;
    }
  }, [slug]);

  useEffect(() => {
    async function init() {
      // Önce çerezi kendisi kursun
      await sahipOturumuAc();
      await yaziListesiniGetir();
      await asistanOnerileriGetir();
    }
    init();
  }, [asistanOnerileriGetir, yaziListesiniGetir]);

  async function asistanlaOlustur(konu: string) {
    setAsistanIsliyor(konu);
    setHata(null);
    try {
      const res = await fetch("/api/articles/assistant", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug, konu }),
      });
      const sonuc = await res.json();
      if (!res.ok) {
        setHata(sonuc.hata || "Asistan taslağı hazırlanamadı.");
        return;
      }
      router.push(`/v/${slug}/blog-yonetim/${sonuc.slug}`);
    } catch {
      setHata("Bağlantı kurulamadı.");
    } finally {
      setAsistanIsliyor(null);
    }
  }

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
        {/* Başlık */}
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

        {/* Hata */}
        {hata && (
          <div
            className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-400"
            role="alert"
          >
            {hata}
          </div>
        )}

        {/* Yeni Yazı Oluştur */}
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
                if (e.key === "Enter") yaziOlustur();
              }}
            />
            <button
              onClick={yaziOlustur}
              disabled={olusturuyor || !yeniBaslik.trim()}
              className="shrink-0 rounded-xl bg-[var(--owner-primary)] px-4 py-2.5 text-sm font-extrabold text-[var(--owner-on-primary)] transition hover:brightness-110 disabled:opacity-50"
            >
              {olusturuyor ? "Oluşturuluyor..." : "Oluştur"}
            </button>
          </div>
        </div>

        {konular.length > 0 || tazeleme.length > 0 ? (
          <div className="rounded-2xl owner-card p-4">
            <h2 className="mb-1 text-sm font-extrabold text-[var(--owner-text)]">
              VixRex Asistanı
            </h2>
            <p className="mb-3 text-xs text-[var(--owner-muted)]">
              Konu seçin; asistan SEO standardına uygun bir taslak hazırlar.
              Taslak yayına hazır iskelet olarak açılır, siz düzenleyip
              yayınlarsınız.
            </p>
            <div className="flex flex-col gap-2">
              {konular.map((aday) => (
                <button
                  key={aday.konu}
                  type="button"
                  onClick={() => asistanlaOlustur(aday.konu)}
                  disabled={asistanIsliyor !== null}
                  className="flex flex-col items-start gap-1 rounded-xl border border-[var(--owner-border)] px-3 py-2.5 text-left transition hover:border-[var(--owner-primary)] disabled:opacity-50"
                >
                  <span className="text-xs font-extrabold text-[var(--owner-text)]">
                    {aday.baslik}
                  </span>
                  <span className="text-[10px] text-[var(--owner-muted)]">
                    {aday.gerekce}
                  </span>
                  <span className="text-[10px] font-extrabold text-[var(--owner-primary)]">
                    {asistanIsliyor === aday.konu
                      ? "Hazırlanıyor…"
                      : "Asistanla oluştur"}
                  </span>
                </button>
              ))}
            </div>
            {tazeleme.length > 0 ? (
              <div className="mt-4 border-t border-[var(--owner-border)] pt-3">
                <h3 className="text-xs font-extrabold text-[var(--owner-text)]">
                  Güncellenmesi gereken yazılar
                </h3>
                <ul className="mt-2 space-y-1">
                  {tazeleme.map((yazi) => (
                    <li
                      key={yazi.slug}
                      className="flex items-center justify-between gap-2 text-xs text-[var(--owner-muted)]"
                    >
                      <span className="min-w-0 flex-1 truncate">
                        {yazi.title} · {yazi.gun} gün önce güncellendi
                      </span>
                      <Link
                        href={`/v/${slug}/blog-yonetim/${yazi.slug}`}
                        className="shrink-0 font-extrabold text-[var(--owner-secondary)]"
                      >
                        Tazele
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            ) : null}
          </div>
        ) : null}

        {/* Yazı Listesi */}
        {yukleniyor ? (
          <div className="flex items-center justify-center py-12">
            <div className="h-4 w-4 animate-pulse rounded-full bg-[var(--owner-primary)]" />
          </div>
        ) : yazilar.length === 0 ? (
          <div className="rounded-2xl owner-card py-12 text-center">
            <p className="text-sm text-[var(--owner-muted)]">
              Henüz yazınız yok. Yukarıdaki formu kullanarak ilk yazınızı
              oluşturun.
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
                      onClick={() => yaziSil(yazi.id)}
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
