import { organizationJsonLd, safeJsonLdHtml, webSiteJsonLd } from "@/lib/jsonLd";
import { getSiteUrl } from "@/lib/siteUrl";

/**
 * Keşfet uygulama kabuğu. Platform başlık/altbilgisi burada özellikle yoktur;
 * ana Keşfet kendi yan menüsünü kullanır. Route grubu URL'yi değiştirmez.
 */
export default function ExploreLayout({
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
      {children}
    </div>
  );
}
