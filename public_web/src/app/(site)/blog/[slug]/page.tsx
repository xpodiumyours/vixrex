import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { yayindakiYazilar, yaziyiBul } from "@/data/blogYazilari";
import { govdeyiBicimlendir, tarihiYaz } from "@/lib/blogIcerik";
import { safeJsonLdHtml } from "@/lib/jsonLd";
import { buildSiteUrl, getSiteUrl } from "@/lib/siteUrl";

/**
 * Tek Vixrex blog yazısı.
 *
 * Veri merkezi `vixrex_blog_articles` tablosundan gelir. Public okuma katmanı
 * yalnız `published` yazıları döndürdüğü için taslak slug burada da 404 olur.
 * BlogPosting + BreadcrumbList JSON-LD ve sanitize edilmiş gövde davranışı
 * korunur.
 */

export const revalidate = 300;

interface SayfaProps {
  params: Promise<{ slug: string }>;
}

export async function generateStaticParams() {
  const yazilar = await yayindakiYazilar();
  return yazilar.map((yazi) => ({ slug: yazi.slug }));
}

export async function generateMetadata({
  params,
}: SayfaProps): Promise<Metadata> {
  const { slug } = await params;
  const yazi = await yaziyiBul(slug);
  if (!yazi) return { title: "Yazı bulunamadı | Vixrex" };

  return {
    title: `${yazi.baslik} | Vixrex`,
    description: yazi.ozet,
    alternates: { canonical: buildSiteUrl(`/blog/${yazi.slug}`) },
    openGraph: {
      title: yazi.baslik,
      description: yazi.ozet,
      url: buildSiteUrl(`/blog/${yazi.slug}`),
      type: "article",
      publishedTime: yazi.yayinTarihi,
      modifiedTime: yazi.guncellemeTarihi,
      ...(yazi.kapakGorseli ? { images: [yazi.kapakGorseli] } : {}),
    },
  };
}

export default async function BlogYaziPage({ params }: SayfaProps) {
  const { slug } = await params;
  const yazi = await yaziyiBul(slug);
  if (!yazi) notFound();

  const siteUrl = getSiteUrl();
  const yaziUrl = buildSiteUrl(`/blog/${yazi.slug}`);
  const govdeHtml = govdeyiBicimlendir(yazi.govde);

  const blogPosting = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    mainEntityOfPage: { "@type": "WebPage", "@id": yaziUrl },
    headline: yazi.baslik,
    description: yazi.ozet,
    datePublished: yazi.yayinTarihi,
    dateModified: yazi.guncellemeTarihi,
    ...(yazi.kapakGorseli ? { image: [yazi.kapakGorseli] } : {}),
    author: { "@type": "Organization", name: "Vixrex" },
    publisher: {
      "@type": "Organization",
      name: "Vixrex",
      logo: { "@type": "ImageObject", url: buildSiteUrl("/favicon.png") },
    },
  };

  const izYolu = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "Ana Sayfa", item: siteUrl },
      {
        "@type": "ListItem",
        position: 2,
        name: "Blog",
        item: buildSiteUrl("/blog"),
      },
      { "@type": "ListItem", position: 3, name: yazi.baslik, item: yaziUrl },
    ],
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: safeJsonLdHtml(blogPosting) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: safeJsonLdHtml(izYolu) }}
      />

      <div className="bg-lp-bg-light px-5 py-12 sm:py-16">
        <div className="mx-auto w-full max-w-3xl">
          <Link
            href="/blog"
            className="text-xs font-extrabold text-lp-muted transition-colors hover:text-lp-text-alt"
          >
            ← Tüm yazılar
          </Link>

          <article className="mt-4 overflow-hidden rounded-[28px] border border-lp-border bg-lp-bg-editor px-6 py-8 shadow-[0_24px_70px_rgba(14,32,58,0.12)] sm:px-10 sm:py-12">
            <h1 className="text-3xl font-black leading-tight tracking-tight text-lp-text sm:text-4xl">
              {yazi.baslik}
            </h1>
            <p className="mt-3 text-xs font-bold text-lp-muted">
              {tarihiYaz(yazi.yayinTarihi)} · {yazi.okumaDakika} dk okuma
            </p>

            <div
              className="mt-6 text-sm font-medium leading-7 text-lp-text sm:text-base"
              dangerouslySetInnerHTML={{ __html: govdeHtml }}
            />
          </article>

          <section className="mt-6 rounded-2xl border border-lp-border bg-lp-bg-editor px-6 py-6 text-center shadow-sm sm:px-8">
            <p className="text-sm font-black text-lp-text sm:text-base">
              Kendi vitrinini görmek ister misin?
            </p>
            <p className="mt-2 text-sm font-medium leading-6 text-lp-muted">
              Hazır vitrinlere göz at, beğendiğini kendine uyarla.
            </p>
            <Link
              href="/kesfet"
              className="mt-4 inline-flex min-h-11 items-center justify-center rounded-full bg-lp-primary px-6 text-sm font-black text-white transition-opacity hover:opacity-90"
            >
              Keşfet&apos;e bak
            </Link>
          </section>
        </div>
      </div>
    </>
  );
}
