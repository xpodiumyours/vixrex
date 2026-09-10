import { NextResponse } from "next/server";
import {
  blogSonAnlamliDegisiklikTarihi,
  blogYayindaMi,
  yayindakiYazilar,
} from "@/data/blogYazilari";
import { buildSiteUrl } from "@/lib/siteUrl";

function escapeXml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

function rfc822(isoTarih: string): string {
  return new Date(`${isoTarih}T00:00:00Z`).toUTCString();
}

export function GET() {
  if (!blogYayindaMi()) {
    return new NextResponse("Not found", { status: 404 });
  }

  const yazilar = yayindakiYazilar();
  const sonDegisiklik = blogSonAnlamliDegisiklikTarihi();
  const kanalUrl = buildSiteUrl("/blog");
  const rssUrl = buildSiteUrl("/blog/rss.xml");

  const items = yazilar
    .map(
      (yazi) => `
    <item>
      <title>${escapeXml(yazi.baslik)}</title>
      <link>${escapeXml(buildSiteUrl(`/blog/${yazi.slug}`))}</link>
      <guid isPermaLink="true">${escapeXml(buildSiteUrl(`/blog/${yazi.slug}`))}</guid>
      <pubDate>${rfc822(yazi.yayinTarihi)}</pubDate>
      <description>${escapeXml(yazi.ozet)}</description>
    </item>`
    )
    .join("");

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>Vixrex Blog</title>
    <link>${escapeXml(kanalUrl)}</link>
    <description>Dijital vitrin ve işletme rehberleri.</description>
    <language>tr-TR</language>
    <atom:link href="${escapeXml(rssUrl)}" rel="self" type="application/rss+xml" />
    ${sonDegisiklik ? `<lastBuildDate>${rfc822(sonDegisiklik)}</lastBuildDate>` : ""}
    ${items}
  </channel>
</rss>`;

  return new NextResponse(xml, {
    headers: {
      "Content-Type": "application/rss+xml; charset=utf-8",
      "Cache-Control": "public, max-age=300, s-maxage=300",
    },
  });
}
