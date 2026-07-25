import { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";
import { sanitizeHtml } from "@/lib/sanitize";
import { buildSiteUrl, getSiteUrl, isExternalHttpUrl } from "@/lib/siteUrl";

export const revalidate = 300; // Enable 5-minute ISR

interface PageProps {
  params: Promise<{ slug: string; articleSlug: string }>;
}

function sanitizeExternalLinks(htmlContent: string): string {
  if (!htmlContent) return "";
  
  // Replace standard anchor tags targeting external URLs with nofollow ugc attributes
  return htmlContent.replace(/<a\s+([^>]*?)href="([^"]+?)"([^>]*?)>/gi, (match, prefix, href, suffix) => {
    const isExternal = isExternalHttpUrl(href);
    if (isExternal) {
      if (/rel=/i.test(match)) {
        // Append ugc and nofollow to existing rel
        return match.replace(/rel="([^"]+?)"/i, 'rel="$1 ugc nofollow"');
      } else {
        return `<a ${prefix}href="${href}"${suffix} rel="ugc nofollow">`;
      }
    }
    return match;
  });
}

// Convert plain text paragraph breaks into HTML paragraphs for better formatting
function formatContent(text: string): string {
  if (!text) return "";
  
  // First sanitize the raw text/HTML against XSS vulnerabilities
  const sanitizedInput = sanitizeHtml(text);

  // If it's already HTML (contains tag structures), just return sanitized
  if (sanitizedInput.includes("<p>") || sanitizedInput.includes("<br") || sanitizedInput.includes("</div>")) {
    return sanitizeExternalLinks(sanitizedInput);
  }

  // Otherwise, split by double newlines and wrap in paragraphs
  const paragraphs = sanitizedInput
    .split(/\n\s*\n/)
    .map(p => `<p class="mb-4 leading-relaxed">${p.replace(/\n/g, "<br />")}</p>`)
    .join("");

  return sanitizeExternalLinks(paragraphs);
}

async function _getArticleData(slug: string, articleSlug: string) {
  const { data: article, error } = await supabase
    .from("store_articles")
    .select("*, store:stores(name, logo_url, slug)")
    .eq("store_slug", slug)
    .eq("slug", articleSlug)
    .eq("status", "published")
    .single();

  if (error || !article) return null;
  return article;
}

const getArticleData = (slug: string, articleSlug: string) =>
  unstable_cache(
    () => _getArticleData(slug, articleSlug),
    [`article-${slug}-${articleSlug}`],
    { tags: [`store-${slug}`, `article-${slug}-${articleSlug}`], revalidate: 300 }
  )();

export async function generateMetadata(props: PageProps): Promise<Metadata> {
  const params = await props.params;
  const article = await getArticleData(params.slug, params.articleSlug);
  if (!article) return {};

  const title = `${article.title} - ${article.store.name} | Vixrex`;
  const description = article.summary || article.content.substring(0, 150);
  const image = article.cover_image_url || "";

  return {
    title,
    description,
    alternates: {
      canonical: `/v/${article.store.slug}/yazilar/${article.slug}`,
    },
    openGraph: {
      title,
      description,
      images: image ? [{ url: image }] : [],
      type: "article",
      publishedTime: article.published_at || article.created_at,
    },
  };
}

export default async function ArticleDetailPage(props: PageProps) {
  const params = await props.params;
  const article = await getArticleData(params.slug, params.articleSlug);
  if (!article) notFound();

  const formattedHtml = formatContent(article.content);
  const siteUrl = getSiteUrl();
  const articleUrl = buildSiteUrl(
    `/v/${article.store.slug}/yazilar/${article.slug}`
  );

  const formatDateTR = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString("tr-TR", {
      day: "numeric",
      month: "long",
      year: "numeric",
    });
  };

  // BlogPosting Schema Markup
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    "mainEntityOfPage": {
      "@type": "WebPage",
      "@id": articleUrl,
    },
    "headline": article.title,
    "image": article.cover_image_url,
    "datePublished": article.published_at || article.created_at,
    "dateModified": article.updated_at,
    "description": article.summary || article.content.substring(0, 150),
    "author": {
      "@type": "Organization",
      "name": article.store.name,
      "logo": article.store.logo_url,
    },
    "publisher": {
      "@type": "Organization",
      "name": "Vixrex",
      "logo": {
        "@type": "ImageObject",
        "url": buildSiteUrl("/favicon.png"),
      },
    },
  };

  // BreadcrumbList JSON-LD Schema
  const breadcrumbList = {
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
        "name": article.store.name,
        "item": buildSiteUrl(`/v/${article.store.slug}`)
      },
      {
        "@type": "ListItem",
        "position": 3,
        "name": "Yazılar",
        "item": buildSiteUrl(`/v/${article.store.slug}/yazilar`)
      },
      {
        "@type": "ListItem",
        "position": 4,
        "name": article.title,
        "item": articleUrl
      }
    ]
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbList) }}
      />

      <div className="min-h-screen bg-[#0c0d10] px-4 py-8 text-[#f4f1ea]">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-5 animate-fade-in">
          <div className="flex items-center justify-between gap-3 rounded-2xl border border-white/8 bg-[#15171c] px-4 py-3 text-xs font-bold">
            <Link
              href={`/v/${article.store.slug}/yazilar`}
              className="inline-flex items-center gap-1 text-white/55 hover:text-[#E8A87C]"
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
              Tüm yazılar
            </Link>
            <Link
              href={`/v/${article.store.slug}`}
              className="text-[#E8A87C] hover:text-[#f0d0b4]"
            >
              {article.store.name}
            </Link>
          </div>

          {article.cover_image_url && (
            <div className="relative aspect-video overflow-hidden rounded-2xl border border-white/8">
              <Image
                src={article.cover_image_url}
                alt={article.title}
                fill
                className="object-cover"
              />
            </div>
          )}

          <article className="space-y-6 rounded-2xl border border-white/8 bg-[#15171c] p-6 sm:p-8">
            <div className="space-y-3">
              <div className="flex flex-wrap items-center gap-2 text-[10px] font-bold uppercase tracking-wider text-white/40">
                <span className="text-[#E8A87C]">{article.article_type || "Yazı"}</span>
                <span>·</span>
                <span>{formatDateTR(article.published_at || article.created_at)}</span>
                {article.target_city && (
                  <>
                    <span>·</span>
                    <span>{article.target_city}</span>
                  </>
                )}
              </div>

              <h1 className="font-vitrin-display text-2xl font-normal leading-tight text-white sm:text-3xl">
                {article.title}
              </h1>

              {article.summary && (
                <p className="border-l-2 border-[#E8A87C] py-1 pl-4 text-sm font-medium italic leading-relaxed text-white/55">
                  {article.summary}
                </p>
              )}
            </div>

            <div
              className="space-y-4 whitespace-pre-wrap border-t border-white/8 pt-6 text-sm leading-relaxed text-white/70 sm:text-base"
              dangerouslySetInnerHTML={{ __html: formattedHtml }}
            />
          </article>

          <div className="flex items-center justify-between gap-4 rounded-2xl border border-white/8 bg-[#15171c] p-4">
            <div className="flex items-center gap-3">
              {article.store.logo_url ? (
                <Image
                  src={article.store.logo_url}
                  alt="Logo"
                  width={40}
                  height={40}
                  className="h-10 w-10 rounded-full border border-white/15 bg-white object-contain"
                />
              ) : (
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-[#E8A87C]/20 text-base font-bold text-[#E8A87C]">
                  {article.store.name[0].toUpperCase()}
                </div>
              )}
              <div>
                <div className="text-xs font-bold text-white">{article.store.name}</div>
                <div className="text-[10px] font-semibold text-white/40">Vitrin sahibi</div>
              </div>
            </div>
            <Link
              href={`/v/${article.store.slug}`}
              className="rounded-full border border-white/15 px-4 py-2 text-[10px] font-extrabold text-white/70"
            >
              Vitrine git
            </Link>
          </div>
        </div>
      </div>
    </>
  );
}
