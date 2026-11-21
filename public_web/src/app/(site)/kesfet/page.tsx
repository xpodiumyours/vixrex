import type { Metadata } from "next";
import { KesfetIcerik } from "@/components/kesfet/KesfetIcerik";
import { kesfetVitrinleriniGetir } from "@/lib/explore";

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

  return (
    <KesfetIcerik
      vitrinler={vitrinler}
      baslik="Vixrex'leri Keşfet"
      aciklama="Yayındaki tüm Vixrex vitrinlerini inceleyin. Beğendiğin hazır vitrini kirala, kendi işletmenin vitrini olsun."
    />
  );
}
