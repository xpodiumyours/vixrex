import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";

export const revalidate = 3600; // Cache sitemap for 1 hour

export async function GET() {
  try {
    // 1. Fetch published stores
    const { data: stores } = await supabase
      .from("stores")
      .select("slug, updated_at")
      .eq("is_published", true);

    // 2. Fetch published articles
    const { data: articles } = await supabase
      .from("store_articles")
      .select("store_slug, slug, updated_at")
      .eq("status", "published");

    const baseUrl = "https://vitrinx.app";
    
    // Start sitemap XML
    let xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>${baseUrl}</loc>
    <changefreq>daily</changefreq>
    <priority>1.0</priority>
  </url>`;

    // Add stores + their blog list pages
    if (stores) {
      for (const store of stores) {
        const lastMod = store.updated_at ? new Date(store.updated_at).toISOString() : new Date().toISOString();
        xml += `
  <url>
    <loc>${baseUrl}/v/${store.slug}</loc>
    <lastmod>${lastMod}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>${baseUrl}/v/${store.slug}/yazilar</loc>
    <lastmod>${lastMod}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.7</priority>
  </url>`;
      }
    }

    // Add articles
    if (articles) {
      for (const article of articles) {
        const lastMod = article.updated_at ? new Date(article.updated_at).toISOString() : new Date().toISOString();
        xml += `
  <url>
    <loc>${baseUrl}/v/${article.store_slug}/yazilar/${article.slug}</loc>
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
        "Cache-Control": "public, max-age=3600, s-maxage=3600",
      },
    });
  } catch (error) {
    console.error("Error generating sitemap:", error);
    return new NextResponse("Error generating sitemap", { status: 500 });
  }
}
