import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { yayindakiYazilar } from "@/data/blogYazilari";
import { tarihiYaz } from "@/lib/blogIcerik";

/**
 * Vixrex blog listesi.
 *
 * Katman 1'de içerik kaynağı `vixrex_blog_articles` tablosuna taşındı.
 * Hiç yayınlanmış yazı yoksa mevcut davranış korunur: `/blog` 404 verir.
 */

export const revalidate = 300;

export const metadata: Metadata = {
  title: "Blog | Vixrex",
  description:
    "Esnaf ve küçük işletmeler için dijital vitrin, Google'da görünme, " +
    "QR menü ve müşteri kazanma rehberleri.",
};

export default async function BlogListePage() {
  const yazilar = await yayindakiYazilar();
  if (yazilar.length === 0) notFound();

  return (
    <div className="bg-lp-bg-light px-5 py-12 sm:py-16">
      <div className="mx-auto w-full max-w-3xl">
        <section className="overflow-hidden rounded-[28px] border border-lp-border bg-lp-bg-editor px-6 py-8 shadow-[0_24px_70px_rgba(14,32,58,0.12)] sm:px-10 sm:py-12">
          <p className="text-xs font-black uppercase tracking-[0.18em] text-lp-primary">
            Vixrex blog
          </p>
          <h1 className="mt-3 max-w-xl text-3xl font-black tracking-tight text-lp-text sm:text-4xl">
            Esnaf için dijital rehber
          </h1>
          <p className="mt-4 max-w-2xl text-sm font-medium leading-7 text-lp-muted sm:text-base">
            İşletmenizi internette görünür kılmanın yollarını sade bir dille
            anlatıyoruz. Teknik bilgi gerekmiyor.
          </p>
        </section>

        <section className="mt-8 space-y-4" aria-label="Yazılar">
          {yazilar.map((yazi) => (
            <article
              key={yazi.slug}
              className="rounded-2xl border border-lp-border bg-white px-5 py-5 shadow-sm transition-colors hover:border-lp-primary/50 sm:px-7 sm:py-6"
            >
              <h2 className="text-lg font-black leading-snug text-lp-text sm:text-xl">
                <Link href={`/blog/${yazi.slug}`} className="hover:text-lp-primary">
                  {yazi.baslik}
                </Link>
              </h2>
              <p className="mt-2 text-sm font-medium leading-6 text-lp-muted">
                {yazi.ozet}
              </p>
              <p className="mt-3 text-xs font-bold text-lp-muted">
                {tarihiYaz(yazi.yayinTarihi)} · {yazi.okumaDakika} dk okuma
              </p>
            </article>
          ))}
        </section>
      </div>
    </div>
  );
}
