import { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";
import { buildSiteUrl, getSiteUrl } from "@/lib/siteUrl";

export const revalidate = 300;

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

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: "Ana Sayfa",
        item: siteUrl,
      },
      {
        "@type": "ListItem",
        position: 2,
        name: store.name,
        item: buildSiteUrl(`/v/${store.slug}`),
      },
      {
        "@type": "ListItem",
        position: 3,
        name: "Yazılar",
        item: buildSiteUrl(`/v/${store.slug}/yazilar`),
      },
    ],
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <div className="min-h-screen bg-[#0c0d10] px-4 py-8 text-[#f4f1ea] sm:px-6">
        <div className="mx-auto flex w-full max-w-[720px] flex-col gap-6 animate-fade-in">
          <div className="flex items-center justify-between gap-3 rounded-2xl border border-white/8 bg-[#15171c] px-4 py-3">
            <Link
              href={`/v/${store.slug}`}
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
              {store.name}
            </Link>
            <span className="text-xs font-extrabold text-white/45">Yazılar</span>
          </div>

          <div className="space-y-2 py-4 text-center">
            {store.logo_url && (
              <Image
                src={store.logo_url}
                alt={store.name}
                width={64}
                height={64}
                className="mx-auto mb-3 h-16 w-16 rounded-full border border-white/15 bg-white object-contain"
              />
            )}
            <h1 className="font-vitrin-display text-3xl font-normal text-white">
              {store.name} yazıları
            </h1>
            <p className="text-xs font-semibold text-white/45">
              Güncel paylaşımlar, rehberler ve duyurular.
            </p>
          </div>

          <div className="grid gap-3">
            {articles.map((article) => (
              <Link
                key={article.id}
                href={`/v/${store.slug}/yazilar/${article.slug}`}
                className="flex flex-col gap-4 rounded-2xl border border-white/8 bg-[#15171c] p-4 transition hover:-translate-y-0.5 hover:border-white/20 md:flex-row"
              >
                {article.cover_image_url && (
                  <Image
                    src={article.cover_image_url}
                    alt={article.title}
                    width={128}
                    height={128}
                    className="aspect-video w-full shrink-0 rounded-xl object-cover md:aspect-square md:w-32"
                  />
                )}
                <div className="flex flex-1 flex-col justify-between gap-3">
                  <div className="space-y-1.5">
                    <span className="text-[10px] font-extrabold uppercase tracking-wider text-[#E8A87C]">
                      {article.article_type || "Paylaşım"}
                    </span>
                    <h2 className="text-base font-extrabold leading-snug text-white">
                      {article.title}
                    </h2>
                    <p className="line-clamp-2 text-xs font-medium leading-relaxed text-white/50">
                      {article.summary || article.content.substring(0, 150)}
                    </p>
                  </div>
                  <div className="flex items-center justify-between border-t border-white/8 pt-2 text-[10px] font-bold text-white/35">
                    <span>{formatDateTR(article.published_at || article.created_at)}</span>
                    {article.target_city && (
                      <span className="rounded-full bg-white/5 px-2 py-0.5 text-white/50">
                        {article.target_city}
                      </span>
                    )}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}
