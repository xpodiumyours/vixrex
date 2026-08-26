import { SiteFooter } from "@/components/site/SiteFooter";
import { SiteHeader } from "@/components/site/SiteHeader";
import { organizationJsonLd, safeJsonLdHtml, webSiteJsonLd } from "@/lib/jsonLd";
import { getSiteUrl } from "@/lib/siteUrl";

/**
 * Platform yüzeyinin düzeni: ana sayfa, Keşfet ve kategori sayfaları.
 *
 * NEDEN AYRI BİR ROUTE GRUBU: başlık/altbilgi kök `layout.tsx`'e konsaydı
 * `/v/[slug]` vitrin sayfalarını da sarardı. Orada müşterinin gördüğü
 * tam ekran vitrin var — üstüne platform gezinmesi koymak 29 canlı
 * vitrinin görünümünü bozardı. Route grupları adresi değiştirmez:
 * `(site)/page.tsx` yine `/` adresinde yayınlanır.
 */
export default function SiteLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const siteUrl = getSiteUrl();

  return (
    <div className="flex min-h-full flex-col bg-lp-bg-light text-lp-text">
      {/* Kaçış her zaman safeJsonLdHtml üzerinden — json-ld-xss testi bunu korur. */}
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
      <SiteHeader />
      <main className="flex-1">{children}</main>
      <SiteFooter />
    </div>
  );
}
