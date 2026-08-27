"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { blogSeoAnalizi } from "@/lib/blogSeo";
import { sahipOturumuAc } from "@/lib/ownerCookie";
import { vixRexMesajlari } from "@/lib/vixrexMesajlari";

interface YaziFormu {
  id: string;
  title: string;
  slug: string;
  summary: string;
  content: string;
  cover_image_url: string;
  article_type: string;
  target_topic: string;
  target_city: string;
  status: string;
}

export default function BlogEditorPage() {
  const params = useParams<{ slug: string; articleSlug: string }>();
  const router = useRouter();
  const slug = params.slug;
  const articleSlug = params.articleSlug;
  const [yazi, setYazi] = useState<YaziFormu | null>(null);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [kaydediyor, setKaydediyor] = useState(false);
  const [yukluyor, setYukluyor] = useState(false);
  const [hata, setHata] = useState("");
  const [bilgi, setBilgi] = useState("");

  const yaziGetir = useCallback(async () => {
    setHata("");
    let response = await fetch(
      `/api/articles?slug=${encodeURIComponent(slug)}&articleSlug=${encodeURIComponent(articleSlug)}`
    );
    if (response.status === 401 && (await sahipOturumuAc())) {
      response = await fetch(
        `/api/articles?slug=${encodeURIComponent(slug)}&articleSlug=${encodeURIComponent(articleSlug)}`
      );
    }
    const sonuc = await response.json();
    if (!response.ok) {
      setHata(
        response.status === 401
          ? "Oturumunuz bulunamadı. Panodan giriş yapın."
          : sonuc.hata || "Yazı yüklenemedi."
      );
      return;
    }
    setYazi({
      ...sonuc.yazi,
      summary: sonuc.yazi.summary ?? "",
      content: sonuc.yazi.content ?? "",
      cover_image_url: sonuc.yazi.cover_image_url ?? "",
      article_type: sonuc.yazi.article_type ?? "standard",
      target_topic: sonuc.yazi.target_topic ?? "",
      target_city: sonuc.yazi.target_city ?? "",
    });
  }, [articleSlug, slug]);

  useEffect(() => {
    async function init() {
      const oturumVar = await sahipOturumuAc();
      if (!oturumVar) {
        setHata("Oturumunuz bulunamadı. Panodan giriş yapın.");
        setYukleniyor(false);
        return;
      }
      try {
        await yaziGetir();
      } catch {
        setHata("Bağlantı kurulamadı.");
      } finally {
        setYukleniyor(false);
      }
    }
    void init();
  }, [yaziGetir]);

  const seo = useMemo(
    () =>
      blogSeoAnalizi({
        title: yazi?.title ?? "",
        summary: yazi?.summary ?? "",
        content: yazi?.content ?? "",
        topic: yazi?.target_topic ?? "",
        city: yazi?.target_city ?? "",
        hasCover: Boolean(yazi?.cover_image_url),
      }),
    [yazi]
  );

  function alanGuncelle(alan: keyof YaziFormu, deger: string) {
    setYazi((onceki) => (onceki ? { ...onceki, [alan]: deger } : onceki));
  }

  async function kapakYukle(file: File | undefined) {
    if (!file || !yazi) return;
    setYukluyor(true);
    setHata("");
    const form = new FormData();
    form.append("slug", slug);
    form.append("anahtar", "kapakGorseli");
    form.append("dosya", file);

    try {
      let response = await fetch("/api/owner-upload", { method: "POST", body: form });
      if (response.status === 401 && (await sahipOturumuAc())) {
        response = await fetch("/api/owner-upload", { method: "POST", body: form });
      }
      const sonuc = await response.json();
      if (!response.ok) {
        setHata(sonuc.hata || "Kapak görseli yüklenemedi.");
        return;
      }
      alanGuncelle("cover_image_url", sonuc.url);
    } catch {
      setHata("Kapak görseli yüklenemedi.");
    } finally {
      setYukluyor(false);
    }
  }

  async function kaydet(status: "draft" | "published") {
    if (!yazi) return;
    if (!yazi.title.trim() || !yazi.summary.trim() || !yazi.content.trim()) {
      setHata("Başlık, özet ve içerik zorunludur.");
      return;
    }
    setKaydediyor(true);
    setHata("");
    setBilgi("");

    try {
      const istek = () => fetch("/api/articles", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug,
          articleId: yazi.id,
          articleSlug: yazi.slug,
          title: yazi.title,
          summary: yazi.summary,
          content: yazi.content,
          coverImageUrl: yazi.cover_image_url,
          articleType: yazi.article_type,
          targetTopic: yazi.target_topic,
          targetCity: yazi.target_city,
          seoScore: seo.score,
          seoErrors: seo.recommendations,
          status,
        }),
      });
      let response = await istek();
      if (response.status === 401 && (await sahipOturumuAc())) {
        response = await istek();
      }
      const sonuc = await response.json();
      if (!response.ok) {
        setHata(sonuc.hata || "Yazı kaydedilemedi.");
        return;
      }
      alanGuncelle("status", status);
      setBilgi(
        status === "published"
          ? vixRexMesajlari["blog_yayinlandi"]
          : "Yazı taslak olarak kaydedildi."
      );
      router.refresh();
    } catch {
      setHata("Bağlantı kurulamadı.");
    } finally {
      setKaydediyor(false);
    }
  }

  if (yukleniyor) {
    return <main className="owner-shell flex items-center justify-center"><p role="status">Yazı yükleniyor…</p></main>;
  }

  if (!yazi) {
    return <main className="owner-shell px-4 py-10"><div className="owner-card mx-auto max-w-xl p-6"><p className="owner-error" role="alert">{hata || "Yazı bulunamadı."}</p><Link href="/app" className="owner-button-secondary mt-4 inline-flex">Panoya Dön</Link></div></main>;
  }

  return (
    <main className="owner-shell px-4 py-8 sm:px-6">
      <form className="mx-auto flex max-w-4xl flex-col gap-5" aria-busy={kaydediyor || yukluyor} onSubmit={(event) => event.preventDefault()}>
        <header className="owner-card flex flex-wrap items-center justify-between gap-3 p-4">
          <div><Link href={`/v/${slug}/blog-yonetim`} className="text-sm font-bold text-[var(--owner-secondary)]">← Yazı Yönetimi</Link><h1 className="mt-1 text-2xl font-extrabold text-[var(--owner-text)]">Yazıyı Düzenle</h1></div>
          <div className="flex gap-2"><button type="button" className="owner-button-secondary" disabled={kaydediyor || yukluyor} onClick={() => void kaydet("draft")}>Taslak Kaydet</button><button type="button" className="owner-button-primary" disabled={kaydediyor || yukluyor} onClick={() => void kaydet("published")}>Yayınla</button></div>
        </header>

        {hata ? <p className="owner-error" role="alert">{hata}</p> : null}
        {bilgi ? <p className="owner-card p-3 text-sm font-bold text-[var(--owner-success)]" role="status">{bilgi} {yazi.status === "published" ? <Link className="ml-2 underline" href={`/v/${slug}/yazilar/${articleSlug}`}>Yazıyı Gör</Link> : null}</p> : null}

        <section className="owner-card grid gap-4 p-5 sm:grid-cols-2">
          <div className="sm:col-span-2"><label className="owner-label" htmlFor="blog-title">Yazı Başlığı *</label><input id="blog-title" className="owner-input mt-2" maxLength={80} value={yazi.title} onChange={(event) => alanGuncelle("title", event.target.value)} /></div>
          <div className="sm:col-span-2"><label className="owner-label" htmlFor="blog-summary">Yazı Özeti (Meta Açıklaması) *</label><textarea id="blog-summary" className="owner-input mt-2 min-h-24" maxLength={200} value={yazi.summary} onChange={(event) => alanGuncelle("summary", event.target.value)} /></div>
          <div className="sm:col-span-2"><label className="owner-label" htmlFor="blog-content">Makale Metni (İçerik) *</label><textarea id="blog-content" className="owner-input mt-2 min-h-80" value={yazi.content} onChange={(event) => alanGuncelle("content", event.target.value)} /></div>
        </section>

        <section className="owner-card grid gap-4 p-5 sm:grid-cols-2">
          <div className="sm:col-span-2"><p className="owner-label">Kapak Görseli</p>{yazi.cover_image_url ? <div className="mt-2 flex items-center gap-3"><Image unoptimized src={yazi.cover_image_url} alt="Yazı kapak önizlemesi" width={144} height={96} className="h-24 w-36 rounded-xl object-cover" /><button type="button" className="owner-button-secondary" onClick={() => alanGuncelle("cover_image_url", "")}>Kaldır</button></div> : null}<label className="owner-button-secondary mt-3 inline-flex cursor-pointer"><span>{yukluyor ? "Yükleniyor…" : "Kapak Yükle"}</span><input className="sr-only" type="file" accept="image/jpeg,image/png,image/webp" disabled={yukluyor} onChange={(event) => void kapakYukle(event.target.files?.[0])} /></label></div>
          <div><label className="owner-label" htmlFor="article-type">Yazı Türü</label><select id="article-type" className="owner-input mt-2" value={yazi.article_type} onChange={(event) => alanGuncelle("article_type", event.target.value)}><option value="standard">Standart Rehber / Blog</option><option value="news">Duyuru / Haber</option><option value="promotion">Kampanya / Promosyon</option></select></div>
          <div><label className="owner-label" htmlFor="target-topic">Hedef Anahtar Kelime / Konu</label><input id="target-topic" className="owner-input mt-2" value={yazi.target_topic} onChange={(event) => alanGuncelle("target_topic", event.target.value)} /></div>
          <div className="sm:col-span-2"><label className="owner-label" htmlFor="target-city">Hedef Şehir (Yerel SEO)</label><input id="target-city" className="owner-input mt-2" value={yazi.target_city} onChange={(event) => alanGuncelle("target_city", event.target.value)} /></div>
        </section>

        <section className="owner-card p-5"><div className="flex items-center justify-between gap-3"><h2 className="font-extrabold text-[var(--owner-text)]">SEO Puanı</h2><strong className="text-2xl text-[var(--owner-primary)]">{seo.score} / 100</strong></div>{seo.recommendations.length ? <ul className="mt-3 space-y-1 text-sm text-[var(--owner-muted)]">{seo.recommendations.map((onerme) => <li key={onerme}>• {onerme}</li>)}</ul> : <p className="mt-3 text-sm text-[var(--owner-success)]">Yazı arama görünürlüğü için hazır.</p>}</section>
      </form>
    </main>
  );
}
