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
    <div className="px-6 py-12">
      <div className="mx-auto w-full max-w-[1200px]">
        <h1 className="text-[32px] font-black leading-tight text-lp-text md:text-[38px]">
          Vixrex&apos;leri Keşfet
        </h1>
        <p className="mt-3 max-w-[640px] text-[16px] leading-[1.5] text-lp-text-alt">
          Yayındaki tüm Vixrex vitrinlerini inceleyin. Beğendiğin hazır vitrini
          kirala, kendi işletmenin vitrini olsun.
        </p>

        <KesfetIcerik vitrinler={vitrinler} />
      </div>
    </div>
  );
}
