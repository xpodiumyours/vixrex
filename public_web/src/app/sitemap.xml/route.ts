import { NextResponse } from "next/server";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";
import { getSiteUrl } from "@/lib/siteUrl";

export const revalidate = 300;

async function _getSitemapData() {
  const { data: stores } = await supabase
    .from("stores")
    .select("id, slug, updated_at")
    .eq("is_published", true);

  const { data: products } = await supabase
    .from("products")
    .select("store_id, slug, updated_at")
    .eq("is_active", true)
    .eq("is_visible", true);

  const { data: articles } = await supabase
    .from("store_articles")
    .select("store_slug, slug, updated_at")
    .eq("status", "published");

  return {
    stores: stores || [],
    products: products || [],
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
    const { stores, products, articles } = await getSitemapData();
    const baseUrl = getSiteUrl();
    const articleLastModByStore = new Map<string, string>();
    const productsByStoreId = new Map<
      string,
      Array<{ slug: string; updated_at: string | null }>
    >();

    for (const product of products) {
      const storeId = String(product.store_id || "").trim();
      const productSlug = String(product.slug || "").trim();
      if (!storeId || !productSlug) continue;

      const storeProducts = productsByStoreId.get(storeId) || [];
      storeProducts.push({
        slug: productSlug,
        updated_at: product.updated_at || null,
      });
      productsByStoreId.set(storeId, storeProducts);
    }

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
    
    // Public web kökü Flutter landing'e yönlenir; sitemap yalnız içerik URL'lerini taşır.
    let xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">`;

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

        const storeProducts = productsByStoreId.get(store.id) || [];
        for (const product of storeProducts) {
          const productLastMod = product.updated_at
            ? new Date(product.updated_at).toISOString()
            : lastMod;

          xml += `
  <url>
    <loc>${escapeXml(`${baseUrl}/v/${store.slug}/urun/${product.slug}`)}</loc>
    <lastmod>${productLastMod}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.65</priority>
  </url>`;
        }

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
