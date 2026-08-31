import type { Metadata } from "next";
import { cookies } from "next/headers";
import { KesfetIcerik } from "@/components/kesfet/KesfetIcerik";
import { kesfetVitrinleriniGetir } from "@/lib/explore";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";

/**
 * Keşfet dizini (#344).
 *
 * Bugüne kadar yayındaki vitrinlere yalnız uygulamanın içinden ya da doğrudan
 * adresi bilerek ulaşılabiliyordu: platformun hiçbir yerinde "işte vitrinler"
 * diyen taranabilir bir sayfa yoktu. Bu sayfa hem ziyaretçiye giriş kapısı,
 * hem de her vitrine giden iç bağlantıyı üreten yüzey.
 */
export const revalidate = 300;
// Çerez ve canlı vitrin verisi kullanan ana Keşfet build sırasında
// ön-üretilmez. Veri sorgusunun 5 dakikalık cache'i ayrı olarak korunur.
export const dynamic = "force-dynamic";

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

type Props = { searchParams: Promise<{ yalniz_kiralik?: string }> };

export default async function KesfetPage({ searchParams }: Props) {
  const vitrinler = await kesfetVitrinleriniGetir();
  const sadeceKiralik = (await searchParams).yalniz_kiralik === "1";
  const sahipCerezi = (await cookies()).get(OWNER_SESSION_COOKIE)?.value;
  const ilkSahipSlug = sahipCerezi
    ? vitrinler.find((vitrin) => verifyOwnerSession(sahipCerezi, vitrin.slug))?.slug ?? null
    : null;

  return (
    <KesfetIcerik
      vitrinler={vitrinler}
      ilkSahipSlug={ilkSahipSlug}
      sadeceKiralik={sadeceKiralik}
      baslik={sadeceKiralik ? "Hazır Vitrin Seç" : "Vixrex'leri Keşfet"}
      aciklama={
        sadeceKiralik
          ? "Beğendiğini kirala, kendi vitrinin olsun"
          : "Yayındaki tüm Vixrex vitrinlerini inceleyin. Beğendiğin hazır vitrini kirala, kendi işletmenin vitrini olsun."
      }
    />
  );
}

