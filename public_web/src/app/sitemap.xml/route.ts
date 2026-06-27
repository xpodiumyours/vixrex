import { NextResponse } from "next/server";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";
import { getProductUrlSlug, safeParseJson, type ProductItem } from "@/lib/products";
import { getSiteUrl } from "@/lib/siteUrl";

export const revalidate = 300;

async function _getSitemapData() {
  const { data: stores } = await supabase
    .from("stores")
    .select("slug, updated_at, products")
    .eq("is_published", true);

  const { data: articles } = await supabase
    .from("store_articles")
    .select("store_slug, slug, updated_at")
    .eq("status", "published");

  return {
    stores: stores || [],
    articles: articles || [],
  };
}

const getSitemapData = () =>
  unstable_cache(_getSitemapData, ["sitemap"], {
    tags: ["sitemap"],
    revalidate: 300,
  })();

function escapeXml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

export async function GET() {
  try {
    const { stores, articles } = await getSitemapData();
    const baseUrl = getSiteUrl();
    const articleLastModByStore = new Map<string, string>();

    if (articles) {
      for (const article of articles) {
        const lastMod = article.updated_at
          ? new Date(article.updated_at).toISOString()
          : new Date().toISOString();
        const currentLastMod = articleLastModByStore.get(article.store_slug);
        if (!currentLastMod || lastMod > currentLastMod) {
          articleLastModByStore.set(article.store_slug, lastMod);
        }
      }
    }
    
    // Start sitemap XML
    let xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>${baseUrl}</loc>
    <changefreq>daily</changefreq>
    <priority>1.0</priority>
  </url>`;

    // Add stores + blog list pages only when they have published articles
    if (stores) {
      for (const store of stores) {
        const lastMod = store.updated_at ? new Date(store.updated_at).toISOString() : new Date().toISOString();
        const blogLastMod = articleLastModByStore.get(store.slug);
        xml += `
  <url>
    <loc>${escapeXml(`${baseUrl}/v/${store.slug}`)}</loc>
    <lastmod>${lastMod}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>`;

        const products = safeParseJson<ProductItem>(store.products);
        products.forEach((product, index) => {
          if (!product.name?.trim() || !product.description?.trim()) return;

          const productSlug = getProductUrlSlug(product, index);
          if (!productSlug) return;

          xml += `
  <url>
    <loc>${escapeXml(`${baseUrl}/v/${store.slug}/urun/${productSlug}`)}</loc>
    <lastmod>${lastMod}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.65</priority>
  </url>`;
        });

        if (blogLastMod) {
          xml += `
  <url>
    <loc>${escapeXml(`${baseUrl}/v/${store.slug}/yazilar`)}</loc>
    <lastmod>${blogLastMod}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.7</priority>
  </url>`;
        }
      }
    }

    // Add articles
    if (articles) {
      for (const article of articles) {
        const lastMod = article.updated_at ? new Date(article.updated_at).toISOString() : new Date().toISOString();
        xml += `
  <url>
    <loc>${escapeXml(`${baseUrl}/v/${article.store_slug}/yazilar/${article.slug}`)}</loc>
    <lastmod>${lastMod}</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.6</priority>
  </url>`;
      }
    }

    xml += "\n</urlset>";

    return new NextResponse(xml, {
      headers: {
        "Content-Type": "application/xml",
        "Cache-Control": "public, max-age=300, s-maxage=300",
      },
    });
  } catch (error) {
    console.error("Error generating sitemap:", error);
    return new NextResponse("Error generating sitemap", { status: 500 });
  }
}
