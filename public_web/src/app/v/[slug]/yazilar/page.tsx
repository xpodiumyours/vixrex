import { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";
import { buildSiteUrl, getSiteUrl } from "@/lib/siteUrl";

export const revalidate = 300; // Enable 5-minute ISR

interface PageProps {
  params: Promise<{ slug: string }>;
}

async function _getBlogData(slug: string) {
  const { data: store, error: storeErr } = await supabase
    .from("stores")
    .select("slug, name, logo_url")
    .eq("slug", slug)
    .eq("is_published", true)
    .single();

  if (storeErr || !store) return null;

  const { data: articles } = await supabase
    .from("store_articles")
    .select("*")
    .eq("store_slug", slug)
    .eq("status", "published")
    .order("published_at", { ascending: false, nullsFirst: false })
    .order("created_at", { ascending: false });

  return {
    store,
    articles: articles || [],
  };
}

const getBlogData = (slug: string) =>
  unstable_cache(
    () => _getBlogData(slug),
    [`store-${slug}`],
    { tags: [`store-${slug}`], revalidate: 300 }
  )();

export async function generateMetadata(props: PageProps): Promise<Metadata> {
  const params = await props.params;
  const data = await getBlogData(params.slug);
  if (!data || data.articles.length === 0) return {};

  const title = `${data.store.name} İçerik ve Duyurular - Vixrex`;
  const description = `${data.store.name} işletmesinin güncel yazıları, duyuruları ve rehberleri.`;

  return {
    title,
    description,
    alternates: {
      canonical: `/v/${data.store.slug}/yazilar`,
    },
  };
}

export default async function BlogIndexPage(props: PageProps) {
  const params = await props.params;
  const data = await getBlogData(params.slug);
  if (!data) notFound();

  const { store, articles } = data;
  if (articles.length === 0) notFound();
  const siteUrl = getSiteUrl();

  const formatDateTR = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString("tr-TR", {
      day: "numeric",
      month: "long",
      year: "numeric",
    });
  };

  // BreadcrumbList JSON-LD Schema
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": [
      {
        "@type": "ListItem",
        "position": 1,
        "name": "Ana Sayfa",
        "item": siteUrl
      },
      {
        "@type": "ListItem",
        "position": 2,
        "name": store.name,
        "item": buildSiteUrl(`/v/${store.slug}`)
      },
      {
        "@type": "ListItem",
        "position": 3,
        "name": "Yazılar",
        "item": buildSiteUrl(`/v/${store.slug}/yazilar`)
      }
    ]
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <div className="container py-8 flex-1 flex flex-col gap-6 max-w-2xl animate-fade-in">
        {/* Header back link card */}
        <div className="flex justify-between items-center bg-white dark:bg-[#131A22] border border-[#D0E4E8] dark:border-[#243141] rounded-2xl p-4 shadow-sm">
          <Link href={`/v/${store.slug}`} className="text-sm font-bold text-[#64748B] hover:text-[#10D8D8] flex items-center gap-1">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="15 18 9 12 15 6"/></svg>
            {store.name} Vitrini
          </Link>
          <h1 className="text-sm font-extrabold">İçerik ve Duyurular</h1>
        </div>

      {/* Hero Header */}
      <div className="text-center py-6 space-y-2">
        {store.logo_url && (
          <Image src={store.logo_url} alt={store.name} width={64} height={64} className="w-16 h-16 rounded-full mx-auto border object-contain bg-white mb-3" />
        )}
        <h2 className="text-2xl font-extrabold">{store.name} Yazıları</h2>
        <p className="text-xs text-[#64748B] dark:text-[#94A3B8]">Güncel paylaşımlar, rehberler ve duyurular.</p>
      </div>

      {/* Articles Grid List */}
      <div className="grid gap-4">
        {articles.map((article) => (
          <Link
            key={article.id}
            href={`/v/${store.slug}/yazilar/${article.slug}`}
            className="card bg-white dark:bg-[#131A22] hover:border-[#10D8D8] border border-[#D0E4E8] dark:border-[#243141] p-5 flex flex-col md:flex-row gap-5 transition-all hover:-translate-y-0.5"
          >
            {article.cover_image_url && (
              <Image
                src={article.cover_image_url}
                alt={article.title}
                width={128}
                height={128}
                className="w-full md:w-32 aspect-video md:aspect-square object-cover rounded-xl border border-slate-100 dark:border-slate-800 shrink-0"
              />
            )}
            <div className="flex-1 flex flex-col justify-between py-0.5 space-y-3">
              <div className="space-y-1.5">
                <span className="text-[10px] uppercase tracking-wider font-extrabold text-[#38A0E4]">
                  {article.article_type || "Paylaşım"}
                </span>
                <h3 className="font-extrabold text-base leading-snug hover:text-[#10D8D8]">
                  {article.title}
                </h3>
                <p className="text-xs text-[#64748B] dark:text-[#94A3B8] leading-relaxed line-clamp-2">
                  {article.summary || article.content.substring(0, 150)}
                </p>
              </div>

              <div className="flex items-center justify-between text-[10px] text-slate-400 font-bold pt-1 border-t border-slate-50 dark:border-slate-900">
                <span>{formatDateTR(article.published_at || article.created_at)}</span>
                {article.target_city && (
                  <span className="bg-slate-100 dark:bg-slate-800 text-slate-500 px-2 py-0.5 rounded-full font-bold">
                    {article.target_city}
                  </span>
                )}
              </div>
            </div>
          </Link>
        ))}
      </div>
      </div>
    </>
  );
}
