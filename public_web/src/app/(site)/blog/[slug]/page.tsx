import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { BlogArticleCard } from "@/components/blog/BlogArticleCard";
import {
  ilgiliYazilar,
  yayindakiYazilar,
  yaziyiBul,
} from "@/data/blogYazilari";
import { govdeyiBicimlendir, tarihiYaz } from "@/lib/blogIcerik";
import {
  blogSectorById,
  blogSectorUrl,
  blogTopicById,
} from "@/lib/blogTaxonomy";
import { safeJsonLdHtml } from "@/lib/jsonLd";
import { buildSiteUrl, getSiteUrl } from "@/lib/siteUrl";

export const revalidate = 300;

interface SayfaProps {
  params: Promise<{ slug: string }>;
}

export async function generateStaticParams() {
  const yazilar = await yayindakiYazilar();
  return yazilar.map((yazi) => ({ slug: yazi.slug }));
}

export async function generateMetadata({ params }: SayfaProps): Promise<Metadata> {
  const { slug } = await params;
  const yazi = await yaziyiBul(slug);
  if (!yazi) return { title: "Yazı bulunamadı | Vixrex" };

  return {
    title: `${yazi.baslik} | Vixrex`,
    description: yazi.ozet,
    keywords: yazi.etiketler.length ? yazi.etiketler : undefined,
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
  const konu = blogTopicById(yazi.konu);
  const sektorler = yazi.sektorler
    .map((id) => blogSectorById(id))
    .filter((sektor): sektor is NonNullable<typeof sektor> => Boolean(sektor));
  const ilgili = await ilgiliYazilar(yazi.slug);

  const blogPosting = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    mainEntityOfPage: { "@type": "WebPage", "@id": yaziUrl },
    headline: yazi.baslik,
    description: yazi.ozet,
    datePublished: yazi.yayinTarihi,
    dateModified: yazi.guncellemeTarihi,
    ...(konu ? { articleSection: konu.label, about: konu.label } : {}),
    ...(yazi.etiketler.length ? { keywords: yazi.etiketler.join(", ") } : {}),
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
      { "@type": "ListItem", position: 2, name: "Blog", item: buildSiteUrl("/blog") },
      ...(konu
        ? [
            {
              "@type": "ListItem",
              position: 3,
              name: konu.label,
              item: buildSiteUrl(`/blog/konu/${konu.id}`),
            },
          ]
        : []),
      {
        "@type": "ListItem",
        position: konu ? 4 : 3,
        name: yazi.baslik,
        item: yaziUrl,
      },
    ],
  };

  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: safeJsonLdHtml(blogPosting) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: safeJsonLdHtml(izYolu) }} />

      <div className="bg-lp-bg-light px-5 py-12 sm:py-16">
        <div className="mx-auto w-full max-w-3xl">
          <Link href="/blog" className="text-xs font-extrabold text-lp-muted transition-colors hover:text-lp-text-alt">
            ← Tüm yazılar
          </Link>

          <article className="mt-4 overflow-hidden rounded-[28px] border border-lp-border bg-lp-bg-editor shadow-[0_24px_70px_rgba(14,32,58,0.12)]">
            {yazi.kapakGorseli ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={yazi.kapakGorseli}
                alt={`${yazi.baslik} kapak görseli`}
                className="aspect-[16/9] w-full object-cover"
              />
            ) : null}

            <div className="px-6 py-8 sm:px-10 sm:py-12">
              <div className="flex flex-wrap gap-2">
                {konu ? (
                  <Link href={`/blog/konu/${konu.id}`} className="rounded-full bg-lp-primary/[0.08] px-3 py-1 text-[11px] font-black text-lp-primary">
                    {konu.label}
                  </Link>
                ) : null}
                {sektorler.map((sektor) => (
                  <Link key={sektor.id} href={`/blog/sektor/${blogSectorUrl(sektor.id)}`} className="rounded-full border border-lp-border px-3 py-1 text-[11px] font-extrabold text-lp-muted hover:text-lp-primary">
                    {sektor.label}
                  </Link>
                ))}
              </div>

              <h1 className="mt-4 text-3xl font-black leading-tight tracking-tight text-lp-text sm:text-4xl">
                {yazi.baslik}
              </h1>
              <p className="mt-3 text-xs font-bold text-lp-muted">
                {tarihiYaz(yazi.yayinTarihi)} · {yazi.okumaDakika} dk okuma
              </p>

              <div className="mt-6 text-sm font-medium leading-7 text-lp-text sm:text-base" dangerouslySetInnerHTML={{ __html: govdeHtml }} />
            </div>
          </article>

          {ilgili.length > 0 ? (
            <section className="mt-8" aria-labelledby="ilgili-yazilar">
              <h2 id="ilgili-yazilar" className="text-xl font-black text-lp-text">İlgili rehberler</h2>
              <div className="mt-4 grid gap-4">
                {ilgili.slice(0, 3).map((ilgiliYazi) => (
                  <BlogArticleCard key={ilgiliYazi.slug} yazi={ilgiliYazi} />
                ))}
              </div>
            </section>
          ) : null}

          <section className="mt-6 rounded-2xl border border-lp-border bg-lp-bg-editor px-6 py-6 text-center shadow-sm sm:px-8">
            <p className="text-sm font-black text-lp-text sm:text-base">Kendi vitrinini görmek ister misin?</p>
            <p className="mt-2 text-sm font-medium leading-6 text-lp-muted">Hazır vitrinlere göz at, beğendiğini kendine uyarla.</p>
            <Link href="/kesfet" className="mt-4 inline-flex min-h-11 items-center justify-center rounded-full bg-lp-primary px-6 text-sm font-black text-lp-on-primary transition-opacity hover:opacity-90">
              Keşfet&apos;e bak
            </Link>
          </section>
        </div>
      </div>
    </>
  );
}
