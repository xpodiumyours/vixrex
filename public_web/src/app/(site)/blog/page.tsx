import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { BlogKesif } from "@/components/blog/BlogKesif";
import { type BlogListeYazisi, yayindakiYazilar } from "@/data/blogYazilari";
import { okumaDakikasiHesapla } from "@/lib/blogIcerik";

export const metadata: Metadata = {
  title: "İşletmeler için pratik rehberler | Vixrex Blog",
  alternates: { canonical: "/blog", types: { "application/rss+xml": "/blog/rss.xml" } },
  openGraph: { title: "Vixrex Blog — İşletmen için işe yarayan bilgiler", description: "Dijital vitrin, Google ve müşteri iletişimi için pratik işletme rehberleri.", url: "/blog", type: "website", locale: "tr_TR", images: [{ url: "/blog/kapak/blog", width: 1200, height: 630, alt: "Vixrex Blog — işletme rehberleri" }] },
  description:
    "Dijital vitrin, müşteri iletişimi, Google'da keşfedilme ve Vixrex yenilikleri için pratik ve kontrol edilmiş işletme rehberleri.",
};

export default function BlogListePage() {
  const yazilar = yayindakiYazilar();
  if (yazilar.length === 0) notFound();

  const listeYazilari: BlogListeYazisi[] = yazilar.map((yazi) => ({
    slug: yazi.slug,
    baslik: yazi.baslik,
    ozet: yazi.ozet,
    kategori: yazi.kategori,
    icerikTuru: yazi.icerikTuru,
    sektorler: yazi.sektorler,
    kapak: yazi.kapak,
    kapakAlt: yazi.kapakAlt,
    yayinTarihi: yazi.yayinTarihi,
    guncellemeTarihi: yazi.guncellemeTarihi,
    okumaDakika: okumaDakikasiHesapla(yazi.govde),
  }));

  return <BlogKesif yazilar={listeYazilari} />;
}
