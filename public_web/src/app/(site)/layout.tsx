import { SiteFooter } from "@/components/site/SiteFooter";
import { SiteHeader } from "@/components/site/SiteHeader";
import { organizationJsonLd, safeJsonLdHtml, webSiteJsonLd } from "@/lib/jsonLd";
import { getSiteUrl } from "@/lib/siteUrl";

/**
 * Platform yüzeyinin düzeni: ana sayfa, Keşfet ve kategori sayfaları.
 *
 * Keşfet sayfası için SiteHeader ve SiteFooter render edilmez.
 * Route grupları adresi değiştirmez: `(site)/page.tsx` yine `/` adresinde yayınlanır.
 */
export default function SiteLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const siteUrl = getSiteUrl();

  return (
    <div className="flex min-h-full flex-col bg-lp-bg-light text-lp-text">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: safeJsonLdHtml(organizationJsonLd(siteUrl)),
        }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: safeJsonLdHtml(webSiteJsonLd(siteUrl)),
        }}
      />
      <main className="flex-1">{children}</main>
    </div>
  );
}