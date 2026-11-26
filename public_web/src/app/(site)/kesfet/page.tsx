import type { Metadata } from "next";
import { KesfetIcerik } from "@/components/kesfet/KesfetIcerik";
import { kesfetVitrinleriniGetir } from "@/lib/explore";
import { getSiteUrl, buildSiteUrl } from "@/lib/siteUrl";
import { safeJsonLdHtml } from "@/lib/jsonLd";

/**
 * Keşfet dizini (#344).
 *
 * Bugüne kadar yayındaki vitrinlere yalnız uygulamanın içinden ya da doğrudan
 * adresi bilerek ulaşılabiliyordu: platformun hiçbir yerinde "işte vitrinler"
 * diyen taranabilir bir sayfa yoktu. Bu sayfa hem ziyaretçiye giriş kapısı,
 * hem de her vitrine giden iç bağlantıyı üreten yüzey.
 */
export const revalidate = 300;

export const metadata: Metadata = {
  title: "Keşfet — yayındaki Vixrex vitrinleri",
  description:
    "Yayındaki işletme vitrinlerini ve kiralanabilir hazır şablonları incele. Beğendiğin şablonu kirala, kendi vitrinin olsun.",
  alternates: { canonical: "/kesfet" },
  openGraph: {
    type: "website",
    siteName: "Vixrex",
    locale: "tr_TR",
    title: "Keşfet — yayındaki Vixrex vitrinleri",
    description:
      "Yayındaki işletme vitrinlerini ve kiralanabilir hazır şablonları incele.",
    url: "/kesfet",
  },
};

export default async function KesfetPage() {
  const vitrinler = await kesfetVitrinleriniGetir();
  const siteUrl = getSiteUrl();
  const breadcrumbJsonLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "Ana Sayfa", item: siteUrl },
      { "@type": "ListItem", position: 2, name: "Keşfet", item: buildSiteUrl("/kesfet") },
    ],
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: safeJsonLdHtml(breadcrumbJsonLd) }}
      />
      <KesfetIcerik
        vitrinler={vitrinler}
        baslik="Vixrex'leri Keşfet"
        aciklama="Yayındaki tüm Vixrex vitrinlerini inceleyin. Beğendiğin hazır vitrini kirala, kendi işletmenin vitrini olsun."
      />
    </>
  );
}
