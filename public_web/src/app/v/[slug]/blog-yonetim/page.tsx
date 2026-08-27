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

  const yaziListesiniGetir = useCallback(async () => {
    setHata(null);

    const {
      data: { session },
    } = await supabase.auth.getSession();
    if (!session) {
      router.push("/giris");
      return;
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

  useEffect(() => {
    async function init() {
      // Önce çerezi kendisi kursun
      await sahipOturumuAc();
      await yaziListesiniGetir();
    }
    init();
  }, [yaziListesiniGetir]);

  async function yaziOlustur() {
    if (!yeniBaslik.trim()) return;
    setOlusturuyor(true);

    const {
      data: { session },
    } = await supabase.auth.getSession();
    if (!session) {
      router.push("/giris");
      return;
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
      setYeniBaslik("");
      await yaziListesiniGetir();
    } catch {
      setHata("Bağlantı kurulamadı.");
    } finally {
      setOlusturuyor(false);
    }
  }

  async function yaziSil(articleId: string) {
    if (!window.confirm("Bu yazıyı silmek istediğinden emin misin?")) return;

    const {
      data: { session },
    } = await supabase.auth.getSession();
    if (!session) return;

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
    <main className="min-h-screen bg-[#0c0d10] px-4 py-8 text-[#f4f1ea] sm:px-6">
      <div className="mx-auto flex w-full max-w-[720px] flex-col gap-6">
        {/* Başlık */}
        <div className="flex items-center justify-between gap-3 rounded-2xl border border-white/8 bg-[#15171c] px-4 py-3">
          <Link
            href={`/v/${slug}`}
            className="inline-flex items-center gap-1 text-sm font-extrabold text-[#E8A87C]"
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
          <span className="text-xs font-extrabold text-white/45">
            Blog Yönetimi
          </span>
        </div>

        <h1 className="text-2xl font-extrabold text-white">Yazı Yönetimi</h1>

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
        <div className="rounded-2xl border border-white/8 bg-[#15171c] p-4">
          <h2 className="mb-3 text-sm font-extrabold text-white">
            Yeni Yazı Oluştur
          </h2>
          <div className="flex gap-2">
            <input
              type="text"
              value={yeniBaslik}
              onChange={(e) => setYeniBaslik(e.target.value)}
              placeholder="Yazı başlığı..."
              className="flex-1 rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-white placeholder:text-white/30 focus:border-[#E8A87C] focus:outline-none"
              onKeyDown={(e) => {
                if (e.key === "Enter") yaziOlustur();
              }}
            />
            <button
              onClick={yaziOlustur}
              disabled={olusturuyor || !yeniBaslik.trim()}
              className="shrink-0 rounded-xl bg-[#E8A87C] px-4 py-2.5 text-sm font-extrabold text-[#0c0d10] transition hover:brightness-110 disabled:opacity-50"
            >
              {olusturuyor ? "Oluşturuluyor..." : "Oluştur"}
            </button>
          </div>
        </div>

        {/* Yazı Listesi */}
        {yukleniyor ? (
          <div className="flex items-center justify-center py-12">
            <div className="h-4 w-4 animate-pulse rounded-full bg-[#E8A87C]" />
          </div>
        ) : yazilar.length === 0 ? (
          <div className="rounded-2xl border border-white/8 bg-[#15171c] py-12 text-center">
            <p className="text-sm text-white/40">
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
                  className="flex items-center gap-4 rounded-2xl border border-white/8 bg-[#15171c] p-4 transition hover:border-white/15"
                >
                  {yazi.cover_image_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={yazi.cover_image_url}
                      alt=""
                      className="h-16 w-16 shrink-0 rounded-xl object-cover"
                    />
                  ) : (
                    <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-xl bg-white/5 text-xl text-white/20">
                      📝
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <h3 className="truncate text-sm font-extrabold text-white">
                        {yazi.title}
                      </h3>
                      <span
                        className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-extrabold ${durum.renk}`}
                      >
                        {durum.metin}
                      </span>
                    </div>
                    {yazi.summary && (
                      <p className="mt-1 line-clamp-1 text-xs text-white/40">
                        {yazi.summary}
                      </p>
                    )}
                    <p className="mt-1 text-[10px] font-bold text-white/25">
                      {formatDateTR(yazi.updated_at)}
                      {yazi.seo_score != null && yazi.seo_score > 0 && (
                        <span className="ml-2 text-[#E8A87C]">
                          SEO: %{yazi.seo_score}
                        </span>
                      )}
                    </p>
                  </div>
                  <div className="flex shrink-0 gap-1">
                    <Link
                      href={`/v/${slug}/yazilar/${yazi.slug}`}
                      className="rounded-lg border border-white/10 px-2.5 py-1.5 text-[10px] font-extrabold text-white/60 transition hover:border-white/25 hover:text-white"
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
