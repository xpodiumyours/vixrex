import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { BlogArticleCard } from "@/components/blog/BlogArticleCard";
import { yayindakiYazilar } from "@/data/blogYazilari";
import { BUSINESS_CATEGORIES } from "@/lib/businessCategories";
import {
  blogSectorFromUrl,
  blogSectorUrl,
} from "@/lib/blogTaxonomy";
import { buildSiteUrl } from "@/lib/siteUrl";

export const revalidate = 300;

interface SayfaProps {
  params: Promise<{ sector: string }>;
}

export function generateStaticParams() {
  return BUSINESS_CATEGORIES.map((sektor) => ({
    sector: blogSectorUrl(sektor.id),
  }));
}

export async function generateMetadata({ params }: SayfaProps): Promise<Metadata> {
  const { sector } = await params;
  const sektor = blogSectorFromUrl(sector);
  if (!sektor) return { title: "Sektör bulunamadı | Vixrex" };
  return {
    title: `${sektor.label} rehberleri | Vixrex Blog`,
    description: `${sektor.label} işletmeleri için dijital görünürlük, müşteri iletişimi ve Vixrex kullanım rehberleri.`,
    alternates: {
      canonical: buildSiteUrl(`/blog/sektor/${blogSectorUrl(sektor.id)}`),
    },
  };
}

export default async function BlogSektorPage({ params }: SayfaProps) {
  const { sector } = await params;
  const sektor = blogSectorFromUrl(sector);
  if (!sektor) notFound();

  const yazilar = await yayindakiYazilar({ sektor: sektor.id });
  if (yazilar.length === 0) notFound();

  return (
    <div className="bg-lp-bg-light px-5 py-10 sm:px-6 sm:py-14">
      <div className="mx-auto w-full max-w-[1200px]">
        <Link href="/blog" className="text-xs font-extrabold text-lp-muted hover:text-lp-text-alt">
          ← Tüm yazılar
        </Link>
        <header className="mt-4 rounded-[28px] border border-lp-border bg-lp-bg-editor px-6 py-8 shadow-sm sm:px-10">
          <p className="text-xs font-black uppercase tracking-[0.16em] text-lp-primary">Sektör rehberleri</p>
          <h1 className="mt-2 text-3xl font-black tracking-tight text-lp-text sm:text-4xl">{sektor.label}</h1>
          <p className="mt-3 max-w-2xl text-sm font-medium leading-7 text-lp-muted sm:text-base">
            {sektor.label} işletmeleri için yayınlanmış Vixrex rehberleri.
          </p>
          <p className="mt-4 text-xs font-bold text-lp-muted">{yazilar.length} yayınlanmış rehber</p>
        </header>

        <section className="mt-8 grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          {yazilar.map((yazi) => <BlogArticleCard key={yazi.slug} yazi={yazi} />)}
        </section>
      </div>
    </div>
  );
}
