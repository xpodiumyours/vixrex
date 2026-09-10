import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { BlogKesif } from "@/components/blog/BlogKesif";
import { type BlogListeYazisi, yayindakiYazilar } from "@/data/blogYazilari";
import { okumaDakikasiHesapla } from "@/lib/blogIcerik";

export const metadata: Metadata = {
  title: "Blog | Vixrex",
  description:
    "Dijital vitrin, müşteri iletişimi, Google'da keşfedilme ve Vixrex yenilikleri için kaynaklı işletme rehberleri.",
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
