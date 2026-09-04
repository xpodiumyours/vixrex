import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { BlogArticleCard } from "@/components/blog/BlogArticleCard";
import { yayindakiYazilar } from "@/data/blogYazilari";
import { BUSINESS_CATEGORIES } from "@/lib/businessCategories";
import {
  BLOG_TOPICS,
  blogSectorUrl,
} from "@/lib/blogTaxonomy";

/**
 * Vixrex blog ana sayfası — Katman 2 merkezi bilgi kütüphanesi.
 *
 * Public kaynak yalnız yayınlanmış satırları döndürür. Konu/sektör navigasyonu
 * yalnız gerçekten yayınlanmış içerikte bulunan değerlerden üretilir; boş
 * kategori bağlantıları kullanıcıya gösterilmez.
 */

export const revalidate = 300;

export const metadata: Metadata = {
  title: "Blog | Vixrex",
  description:
    "Esnaf ve küçük işletmeler için dijital vitrin, Google'da görünme, " +
    "müşteri iletişimi ve işletme yönetimi rehberleri.",
};

export default async function BlogListePage() {
  const yazilar = await yayindakiYazilar();
  if (yazilar.length === 0) notFound();

  const [oneCikan, ...digerYazilar] = yazilar;
  const konuIdleri = new Set(yazilar.map((yazi) => yazi.konu).filter(Boolean));
  const sektorIdleri = new Set(yazilar.flatMap((yazi) => yazi.sektorler));
  const konular = BLOG_TOPICS.filter((konu) => konuIdleri.has(konu.id));
  const sektorler = BUSINESS_CATEGORIES.filter((sektor) => sektorIdleri.has(sektor.id));

  return (
    <div className="bg-lp-bg-light px-5 py-10 sm:px-6 sm:py-14">
      <div className="mx-auto w-full max-w-[1200px]">
        <section className="overflow-hidden rounded-[28px] border border-lp-border bg-lp-bg-editor px-6 py-8 shadow-[0_24px_70px_rgba(14,32,58,0.12)] sm:px-10 sm:py-12 lg:px-12">
          <div className="max-w-3xl">
            <p className="text-xs font-black uppercase tracking-[0.18em] text-lp-primary">
              Vixrex blog
            </p>
            <h1 className="mt-3 text-3xl font-black tracking-tight text-lp-text sm:text-4xl lg:text-[44px] lg:leading-[1.08]">
              Esnaf için dijital rehber
            </h1>
            <p className="mt-4 max-w-2xl text-sm font-medium leading-7 text-lp-muted sm:text-base">
              Google&apos;da görünürlükten dijital vitrininizi geliştirmeye,
              müşteri iletişiminden işletme yönetimine kadar doğrudan
              uygulayabileceğiniz rehberler.
            </p>
            <div className="mt-6 flex flex-wrap items-center gap-3">
              <Link
                href="/kesfet"
                className="inline-flex min-h-11 items-center justify-center rounded-full bg-lp-primary px-5 text-sm font-black text-lp-on-primary transition hover:brightness-105"
              >
                Vitrinleri Keşfet
              </Link>
              <span className="text-xs font-bold text-lp-muted">
                {yazilar.length} yayınlanmış rehber
              </span>
            </div>
          </div>
        </section>

        {konular.length > 0 ? (
          <section className="mt-8" aria-labelledby="blog-konular">
            <h2 id="blog-konular" className="text-lg font-black text-lp-text">
              Konuya göre keşfet
            </h2>
            <div className="mt-4 flex flex-wrap gap-2">
              {konular.map((konu) => (
                <Link
                  key={konu.id}
                  href={`/blog/konu/${konu.id}`}
                  className="rounded-full border border-lp-border bg-lp-surface px-4 py-2 text-sm font-extrabold text-lp-text transition hover:border-lp-primary/50 hover:text-lp-primary"
                >
                  {konu.label}
                </Link>
              ))}
            </div>
          </section>
        ) : null}

        {sektorler.length > 0 ? (
          <section className="mt-6" aria-labelledby="blog-sektorler">
            <h2 id="blog-sektorler" className="text-sm font-black text-lp-text">
              Sektörüne göre
            </h2>
            <div className="mt-3 flex flex-wrap gap-2">
              {sektorler.map((sektor) => (
                <Link
                  key={sektor.id}
                  href={`/blog/sektor/${blogSectorUrl(sektor.id)}`}
                  className="rounded-full bg-lp-primary/[0.08] px-3.5 py-2 text-xs font-black text-lp-primary"
                >
                  {sektor.label}
                </Link>
              ))}
            </div>
          </section>
        ) : null}

        <section className="mt-10" aria-labelledby="blog-one-cikan">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.16em] text-lp-primary">
              Öne çıkan
            </p>
            <h2 id="blog-one-cikan" className="mt-2 text-2xl font-black tracking-tight text-lp-text sm:text-3xl">
              İlk bakılacak rehber
            </h2>
          </div>
          <div className="mt-6 max-w-3xl">
            <BlogArticleCard yazi={oneCikan} />
          </div>
        </section>

        {digerYazilar.length > 0 ? (
          <section className="mt-10" aria-labelledby="blog-son-yazilar">
            <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
              <div>
                <p className="text-xs font-black uppercase tracking-[0.16em] text-lp-primary">
                  Güncel içerikler
                </p>
                <h2 id="blog-son-yazilar" className="mt-2 text-2xl font-black tracking-tight text-lp-text sm:text-3xl">
                  Son rehberler
                </h2>
              </div>
              <p className="max-w-md text-sm font-medium leading-6 text-lp-muted">
                Yeni rehberler eklendikçe konu ve sektör bağlantıları da aynı
                merkezi kütüphaneden büyür.
              </p>
            </div>

            <div className="mt-6 grid gap-5 md:grid-cols-2 xl:grid-cols-3">
              {digerYazilar.map((yazi) => (
                <BlogArticleCard key={yazi.slug} yazi={yazi} />
              ))}
            </div>
          </section>
        ) : null}
      </div>
    </div>
  );
}
