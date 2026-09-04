import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { BlogArticleCard } from "@/components/blog/BlogArticleCard";
import { yayindakiYazilar } from "@/data/blogYazilari";
import { BLOG_TOPICS, blogTopicById } from "@/lib/blogTaxonomy";
import { buildSiteUrl } from "@/lib/siteUrl";

export const revalidate = 300;

interface SayfaProps {
  params: Promise<{ topic: string }>;
}

export function generateStaticParams() {
  return BLOG_TOPICS.map((konu) => ({ topic: konu.id }));
}

export async function generateMetadata({ params }: SayfaProps): Promise<Metadata> {
  const { topic } = await params;
  const konu = blogTopicById(topic);
  if (!konu) return { title: "Konu bulunamadı | Vixrex" };
  return {
    title: `${konu.label} | Vixrex Blog`,
    description: konu.description,
    alternates: { canonical: buildSiteUrl(`/blog/konu/${konu.id}`) },
  };
}

export default async function BlogKonuPage({ params }: SayfaProps) {
  const { topic } = await params;
  const konu = blogTopicById(topic);
  if (!konu) notFound();

  const yazilar = await yayindakiYazilar({ konu: konu.id });
  if (yazilar.length === 0) notFound();

  return (
    <div className="bg-lp-bg-light px-5 py-10 sm:px-6 sm:py-14">
      <div className="mx-auto w-full max-w-[1200px]">
        <Link href="/blog" className="text-xs font-extrabold text-lp-muted hover:text-lp-text-alt">
          ← Tüm yazılar
        </Link>
        <header className="mt-4 rounded-[28px] border border-lp-border bg-lp-bg-editor px-6 py-8 shadow-sm sm:px-10">
          <p className="text-xs font-black uppercase tracking-[0.16em] text-lp-primary">Blog konusu</p>
          <h1 className="mt-2 text-3xl font-black tracking-tight text-lp-text sm:text-4xl">{konu.label}</h1>
          {konu.description ? <p className="mt-3 max-w-2xl text-sm font-medium leading-7 text-lp-muted sm:text-base">{konu.description}</p> : null}
          <p className="mt-4 text-xs font-bold text-lp-muted">{yazilar.length} yayınlanmış rehber</p>
        </header>

        <section className="mt-8 grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          {yazilar.map((yazi) => <BlogArticleCard key={yazi.slug} yazi={yazi} />)}
        </section>
      </div>
    </div>
  );
}
