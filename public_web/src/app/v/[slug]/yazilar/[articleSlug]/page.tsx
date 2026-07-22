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

      <div className="container py-8 flex-1 flex flex-col gap-6 max-w-2xl animate-fade-in">
        {/* Navigation / Header */}
        <div className="flex justify-between items-center bg-white dark:bg-[#131A22] border border-[#D0E4E8] dark:border-[#243141] rounded-2xl p-4 shadow-sm text-xs font-bold">
          <Link href={`/v/${article.store.slug}/yazilar`} className="text-[#64748B] hover:text-[#10D8D8] flex items-center gap-1">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="15 18 9 12 15 6"/></svg>
            Tüm İçerikler
          </Link>
          <Link href={`/v/${article.store.slug}`} className="text-[#38A0E4] hover:text-[#10D8D8]">
            {article.store.name} Vitrini
          </Link>
        </div>

        {/* Cover Photo */}
        {article.cover_image_url && (
          <div className="rounded-2xl overflow-hidden aspect-video border border-[#D0E4E8] dark:border-[#243141] shadow-sm relative">
            <Image 
              src={article.cover_image_url} 
              alt={article.title} 
              fill
              className="object-cover" 
            />
          </div>
        )}

        {/* Article Body Card */}
        <article className="card bg-white dark:bg-[#131A22] p-6 sm:p-8 space-y-6">
          <div className="space-y-3">
            <div className="flex items-center gap-2 text-[10px] font-bold text-[#64748B] uppercase tracking-wider">
              <span className="text-[#0EA8B0]">{article.article_type || "Yazı"}</span>
              <span>•</span>
              <span>{formatDateTR(article.published_at || article.created_at)}</span>
              {article.target_city && (
                <>
                  <span>•</span>
                  <span className="text-slate-400">{article.target_city}</span>
                </>
              )}
            </div>
            
            <h1 className="text-2xl sm:text-3xl font-extrabold leading-tight text-slate-800 dark:text-slate-100">
              {article.title}
            </h1>

            {article.summary && (
              <p className="text-sm font-semibold text-slate-500 dark:text-slate-400 italic border-l-4 border-[#10D8D8] pl-4 py-1 leading-relaxed">
                {article.summary}
              </p>
            )}
          </div>

          <div 
            className="text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed space-y-4 whitespace-pre-wrap border-t border-slate-50 dark:border-slate-800 pt-6"
            dangerouslySetInnerHTML={{ __html: formattedHtml }}
          />
        </article>

        {/* Author widget */}
        <div className="card bg-slate-50/50 dark:bg-slate-900/30 border border-[#D0E4E8] dark:border-[#243141] p-4 flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            {article.store.logo_url ? (
              <Image src={article.store.logo_url} alt="Logo" width={40} height={40} className="w-10 h-10 rounded-full object-contain border bg-white" />
            ) : (
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#10D8D8] to-[#38A0E4] text-white flex items-center justify-center font-bold text-base">
                {article.store.name[0].toUpperCase()}
              </div>
            )}
            <div>
              <div className="text-xs font-bold">{article.store.name}</div>
              <div className="text-[10px] text-slate-400 font-semibold">Vitrin Sahibi ve Yazar</div>
            </div>
          </div>
          <Link href={`/v/${article.store.slug}`} className="btn-secondary px-4 py-2 text-[10px] rounded-lg">
            Vitrine Git
          </Link>
        </div>
      </div>
    </>
  );
}
