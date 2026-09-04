import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { yayindakiYazilar } from "@/data/blogYazilari";
import { tarihiYaz } from "@/lib/blogIcerik";

/**
 * Vixrex blog ana sayfası.
 *
 * Katman 1'de içerik kaynağı `vixrex_blog_articles` tablosuna taşındı.
 * Liste yüzeyi günlük büyüyen katalog için 1200px Vixrex platform genişliğine
 * çıkarıldı; detay sayfasındaki dar okuma genişliği bilinçli olarak korunur.
 * Hiç yayınlanmış yazı yoksa mevcut davranış sürer: `/blog` 404 verir.
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
              İşletmenizi internette görünür kılmanın yollarını, dijital vitrininizi
              geliştirmeyi ve müşterilerin sizi daha kolay bulmasını sade bir dille
              anlatıyoruz.
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

        <section className="mt-10" aria-labelledby="blog-son-yazilar">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p className="text-xs font-black uppercase tracking-[0.16em] text-lp-primary">
                Güncel içerikler
              </p>
              <h2
                id="blog-son-yazilar"
                className="mt-2 text-2xl font-black tracking-tight text-lp-text sm:text-3xl"
              >
                Son rehberler
              </h2>
            </div>
            <p className="max-w-md text-sm font-medium leading-6 text-lp-muted">
              Yeni rehberler eklendikçe bu katalog genişler; okuma sayfaları sade ve
              odaklı kalır.
            </p>
          </div>

          <div className="mt-6 grid gap-5 md:grid-cols-2 xl:grid-cols-3">
            {yazilar.map((yazi) => (
              <article
                key={yazi.slug}
                className="flex h-full flex-col rounded-3xl border border-lp-border/80 bg-lp-surface p-6 shadow-sm transition-colors hover:border-lp-primary/50 sm:p-7"
              >
                <p className="text-[11px] font-black uppercase tracking-[0.14em] text-lp-primary">
                  Rehber
                </p>
                <h3 className="mt-3 text-xl font-black leading-snug text-lp-text">
                  <Link href={`/blog/${yazi.slug}`} className="hover:text-lp-primary">
                    {yazi.baslik}
                  </Link>
                </h3>
                <p className="mt-3 flex-1 text-sm font-medium leading-6 text-lp-muted">
                  {yazi.ozet}
                </p>
                <div className="mt-6 flex items-center justify-between gap-4 border-t border-lp-border pt-4">
                  <p className="text-xs font-bold text-lp-muted">
                    {tarihiYaz(yazi.yayinTarihi)} · {yazi.okumaDakika} dk
                  </p>
                  <Link
                    href={`/blog/${yazi.slug}`}
                    className="shrink-0 text-xs font-black text-lp-primary"
                  >
                    Oku →
                  </Link>
                </div>
              </article>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}
