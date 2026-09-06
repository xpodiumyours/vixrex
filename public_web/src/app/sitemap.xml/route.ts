import { NextResponse } from "next/server";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";
import { getSiteUrl } from "@/lib/siteUrl";
import {
  BUSINESS_CATEGORIES,
  kategoriUrlParcasi,
} from "@/lib/businessCategories";
import { yayindakiYazilar } from "@/data/blogYazilari";
import { BLOG_TOPICS, blogSectorUrl } from "@/lib/blogTaxonomy";

export const revalidate = 300;

async function _getSitemapData() {
  const { data: stores } = await supabase
    .from("stores")
    .select("id, slug, updated_at, is_demo")
    .eq("is_published", true)
    .eq("is_demo", false);

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
    const [{ stores, products, articles }, vixrexBlogYazilari] = await Promise.all([
      getSitemapData(),
      yayindakiYazilar(),
    ]);
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

    const simdi = new Date().toISOString();
    const blogKonuIdleri = new Set(
      vixrexBlogYazilari.map((yazi) => yazi.konu).filter((id): id is string => Boolean(id))
    );
    const blogSektorIdleri = new Set(vixrexBlogYazilari.flatMap((yazi) => yazi.sektorler));

    let xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">`;

    const platformUrlleri: Array<{ yol: string; oncelik: string; siklik: string }> = [
      { yol: "/", oncelik: "1.0", siklik: "weekly" },
      { yol: "/kesfet", oncelik: "0.9", siklik: "daily" },
      ...BUSINESS_CATEGORIES.map((kategori) => ({
        yol: `/kesfet/${kategoriUrlParcasi(kategori.id)}`,
        oncelik: "0.7",
        siklik: "weekly",
      })),
      { yol: "/yardim", oncelik: "0.6", siklik: "monthly" },
      { yol: "/hakkimizda", oncelik: "0.5", siklik: "monthly" },
      { yol: "/iletisim", oncelik: "0.5", siklik: "monthly" },
      ...(vixrexBlogYazilari.length > 0
        ? [
            { yol: "/blog", oncelik: "0.6", siklik: "weekly" },
            ...BLOG_TOPICS.filter((konu) => blogKonuIdleri.has(konu.id)).map((konu) => ({
              yol: `/blog/konu/${konu.id}`,
              oncelik: "0.55",
              siklik: "weekly",
            })),
            ...BUSINESS_CATEGORIES.filter((sektor) => blogSektorIdleri.has(sektor.id)).map((sektor) => ({
              yol: `/blog/sektor/${blogSectorUrl(sektor.id)}`,
              oncelik: "0.5",
              siklik: "weekly",
            })),
            ...vixrexBlogYazilari.map((yazi) => ({
              yol: `/blog/${yazi.slug}`,
              oncelik: "0.5",
              siklik: "monthly",
            })),
          ]
        : []),
      { yol: "/privacy", oncelik: "0.3", siklik: "yearly" },
      { yol: "/legal/privacy", oncelik: "0.3", siklik: "yearly" },
      { yol: "/legal/terms", oncelik: "0.3", siklik: "yearly" },
    ];

    for (const platform of platformUrlleri) {
      xml += `
  <url>
    <loc>${escapeXml(`${baseUrl}${platform.yol}`)}</loc>
    <lastmod>${simdi}</lastmod>
    <changefreq>${platform.siklik}</changefreq>
    <priority>${platform.oncelik}</priority>
  </url>`;
    }

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

    const yayindakiSluglar = new Set(
      (stores || []).map((store) => String(store.slug || "").trim())
    );

    if (articles) {
      for (const article of articles) {
        if (!yayindakiSluglar.has(String(article.store_slug || "").trim())) continue;
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
