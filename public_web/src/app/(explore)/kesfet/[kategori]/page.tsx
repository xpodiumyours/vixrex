import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { KategoriSeridi } from "@/components/kesfet/KategoriSeridi";
import { VitrinKarti } from "@/components/kesfet/VitrinKarti";
import {
  BUSINESS_CATEGORIES,
  kategoriUrlParcasi,
  kategoriUrlParcasindanCoz,
} from "@/lib/businessCategories";
import { kategoriSablonuGetir } from "@/lib/categoryTemplates";
import { kategoriVitrinleriniGetir } from "@/lib/explore";

/**
 * Kategori sayfası (#344).
 *
 * Ana sayfadaki şablon kataloğunun 19 kartı buraya bağlanıyor. Kategori
 * sayfaları olmasaydı katalog bölümü hiçbir yere gitmeyen, sayfanın en
 * büyük ama arama motoru açısından ölü parçası olurdu.
 *
 * Adres parçası tire kullanır (`/kesfet/kafe-lokanta`): Google alt çizgiyi
 * kelime birleştirici sayar, tireyi ayırıcı.
 */
export const revalidate = 300;

export function generateStaticParams() {
  return BUSINESS_CATEGORIES.map((kategori) => ({
    kategori: kategoriUrlParcasi(kategori.id),
  }));
}

type Props = { params: Promise<{ kategori: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { kategori: parca } = await params;
  const kategori = kategoriUrlParcasindanCoz(parca);
  if (!kategori) return { title: "Kategori bulunamadı" };

  const baslik = `${kategori.label} vitrinleri ve hazır şablonlar`;
  const aciklama = `${kategori.label} işletmeleri için yayındaki Vixrex vitrinleri ve kategoriye özel hazır şablon görselleri.`;

  return {
    title: baslik,
    description: aciklama,
    alternates: { canonical: `/kesfet/${kategoriUrlParcasi(kategori.id)}` },
    openGraph: {
      type: "website",
      siteName: "Vixrex",
      locale: "tr_TR",
      title: baslik,
      description: aciklama,
      url: `/kesfet/${kategoriUrlParcasi(kategori.id)}`,
    },
  };
}

export default async function KategoriPage({ params }: Props) {
  const { kategori: parca } = await params;
  const kategori = kategoriUrlParcasindanCoz(parca);
  if (!kategori) notFound();

  const [vitrinler, sablon] = await Promise.all([
    kategoriVitrinleriniGetir(kategori.id),
    kategoriSablonuGetir(kategori.id),
  ]);

  const onizlemeler = [
    ...(sablon?.kapaklar ?? []),
    ...(sablon?.galeri ?? []),
  ].slice(0, 8);

  return (
    <div className="px-6 py-12">
      <div className="mx-auto w-full max-w-[1200px]">
        <p className="text-[12px] font-black tracking-[1.5px] text-lp-primary">
          <Link href="/kesfet">KEŞFET</Link>
        </p>
        <h1 className="mt-3 text-[32px] font-black leading-tight text-lp-text md:text-[38px]">
          {kategori.label} vitrinleri
        </h1>
        <p className="mt-3 max-w-[680px] text-[16px] leading-[1.5] text-lp-text-alt">
          {kategori.label} işletmeleri için yayındaki vitrinler ve bu kategoriye
          özel hazır şablon görselleri.
        </p>

        <div className="mt-8">
          <KategoriSeridi aktifKimlik={kategori.id} />
        </div>

        <h2 className="mt-12 text-[22px] font-black text-lp-text">
          Yayındaki vitrinler
        </h2>
        {vitrinler.length === 0 ? (
          <p className="mt-4 rounded-2xl border border-lp-border bg-lp-surface px-5 py-8 text-[14px] font-semibold text-lp-muted">
            Bu kategoride henüz yayında vitrin yok. Aşağıdaki hazır şablonla
            ilk vitrini sen kurabilirsin.
          </p>
        ) : (
          <ul className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {vitrinler.map((vitrin) => (
              <li key={vitrin.slug}>
                <VitrinKarti vitrin={vitrin} />
              </li>
            ))}
          </ul>
        )}

        {onizlemeler.length > 0 ? (
          <>
            <h2 className="mt-14 text-[22px] font-black text-lp-text">
              {kategori.label} için hazır görseller
            </h2>
            <p className="mt-2 text-[14px] font-semibold text-lp-muted">
              Vitrinini kurarken bu görselleri tek dokunuşla kullanabilirsin.
            </p>
            <ul className="mt-5 grid grid-cols-2 gap-3 md:grid-cols-4">
              {onizlemeler.map((gorsel) => (
                <li
                  key={gorsel.id}
                  className="aspect-[4/3] overflow-hidden rounded-2xl border border-lp-border/70 bg-lp-surface"
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={gorsel.kucukUrl ?? gorsel.url}
                    alt={gorsel.baslik ?? ""}
                    className="h-full w-full object-cover"
                    loading="lazy"
                  />
                </li>
              ))}
            </ul>
            <a
              href="/app"
              className="mt-6 inline-flex rounded-2xl bg-lp-primary px-6 py-3.5 text-[14px] font-black text-lp-on-primary transition-transform hover:-translate-y-0.5"
            >
              Bu Şablonla Başla
            </a>
          </>
        ) : null}
      </div>
    </div>
  );
}

