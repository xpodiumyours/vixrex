import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import {
  ilgiliYazilariBul,
  type YayindakiBlogYazisi,
  yayindakiYazilar,
  yaziyiBul,
} from "@/data/blogYazilari";
import {
  govdeyiBloklaraAyir,
  icindekileriCikar,
  okumaDakikasiHesapla,
  tarihiYaz,
} from "@/lib/blogIcerik";
import { safeJsonLdHtml } from "@/lib/jsonLd";
import { buildSiteUrl, getSiteUrl } from "@/lib/siteUrl";

interface SayfaProps {
  params: Promise<{ slug: string }>;
}

function mutlakUrl(yol: string): string {
  if (/^https?:\/\//i.test(yol)) return yol;
  return buildSiteUrl(yol);
}

function baglamsalCta(
  yazi: Pick<YayindakiBlogYazisi, "kategori" | "icerikTuru">
): { baslik: string; aciklama: string; href: string; etiket: string } {
  if (yazi.icerikTuru === "urun_guncellemesi") {
    return {
      baslik: "Güncellemeyi vitrinde görmek ister misin?",
      aciklama: "Yayındaki vitrinleri Keşfet sayfasında inceleyebilirsin.",
      href: "/kesfet",
      etiket: "Vitrinleri incele",
    };
  }

  switch (yazi.kategori) {
    case "Google ve Keşfedilme":
      return {
        baslik: "Dijital vitrinin temelini kontrol et",
        aciklama:
          "Vitrin hazırlama ve yayınlama adımlarını Vixrex Yardım sayfasında inceleyebilirsin.",
        href: "/yardim",
        etiket: "Yardım rehberlerini aç",
      };
    case "Müşteri İletişimi":
      return {
        baslik: "İletişim bilgilerini doğru hazırlamak ister misin?",
        aciklama:
          "Vixrex Yardım sayfasındaki vitrin hazırlama adımlarını inceleyebilirsin.",
        href: "/yardim",
        etiket: "Yardım rehberlerini aç",
      };
    case "İşletme Hikâyeleri":
      return {
        baslik: "Benzer vitrinleri incele",
        aciklama: "Yayındaki işletme vitrinlerini Keşfet sayfasında görebilirsin.",
        href: "/kesfet",
        etiket: "Vitrinleri keşfet",
      };
    case "Vixrex’te Yenilikler":
      return {
        baslik: "Vixrex’i vitrinlerde incele",
        aciklama: "Yayındaki vitrinleri Keşfet sayfasında görebilirsin.",
        href: "/kesfet",
        etiket: "Vitrinleri keşfet",
      };
    default:
      return {
        baslik: "Vitrin örneklerini incele",
        aciklama:
          "Rehberde anlatılan yapıların gerçek vitrinlerde nasıl göründüğüne Keşfet sayfasından bakabilirsin.",
        href: "/kesfet",
        etiket: "Vitrinleri keşfet",
      };
  }
}

export function generateStaticParams() {
  return yayindakiYazilar().map((yazi) => ({ slug: yazi.slug }));
}

export async function generateMetadata({
  params,
}: SayfaProps): Promise<Metadata> {
  const { slug } = await params;
  const yazi = yaziyiBul(slug);
  if (!yazi) return { title: "Yazı bulunamadı | Vixrex" };

  const kapakUrl = yazi.kapak ? mutlakUrl(yazi.kapak) : undefined;

  return {
    title: `${yazi.baslik} | Vixrex`,
    description: yazi.ozet,
    alternates: { canonical: buildSiteUrl(`/blog/${yazi.slug}`) },
    openGraph: {
      title: yazi.baslik,
      description: yazi.ozet,
      url: buildSiteUrl(`/blog/${yazi.slug}`),
      type: "article",
      publishedTime: yazi.yayinTarihi,
      modifiedTime: yazi.guncellemeTarihi || yazi.yayinTarihi,
      images: kapakUrl
        ? [{ url: kapakUrl, alt: yazi.kapakAlt || yazi.baslik }]
        : undefined,
    },
  };
}

export default async function BlogYaziPage({ params }: SayfaProps) {
  const { slug } = await params;
  const yazi = yaziyiBul(slug);
  if (!yazi) notFound();

  const siteUrl = getSiteUrl();
  const yaziUrl = buildSiteUrl(`/blog/${yazi.slug}`);
  const bloklar = govdeyiBloklaraAyir(yazi.govde);
  const icindekiler = icindekileriCikar(yazi.govde);
  const okumaDakika = okumaDakikasiHesapla(yazi.govde);
  const icindekilerGoster = okumaDakika >= 5 && icindekiler.length >= 2;
  const ilgiliYazilar = ilgiliYazilariBul(yazi);
  const kapakUrl = yazi.kapak ? mutlakUrl(yazi.kapak) : null;
  const anlamliGuncelleme =
    Boolean(yazi.guncellemeTarihi) &&
    yazi.guncellemeTarihi !== yazi.yayinTarihi;
  const cta = baglamsalCta(yazi);

  const blogPosting = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    mainEntityOfPage: { "@type": "WebPage", "@id": yaziUrl },
    headline: yazi.baslik,
    description: yazi.ozet,
    datePublished: yazi.yayinTarihi,
    dateModified: yazi.guncellemeTarihi || yazi.yayinTarihi,
    author: {
      "@type": yazi.yazar.tur === "kisi" ? "Person" : "Organization",
      name: yazi.yazar.ad,
      ...(yazi.yazar.url ? { url: mutlakUrl(yazi.yazar.url) } : {}),
    },
    publisher: {
      "@type": "Organization",
      name: "Vixrex",
      url: siteUrl,
      logo: { "@type": "ImageObject", url: buildSiteUrl("/favicon.png") },
    },
    ...(kapakUrl ? { image: [kapakUrl] } : {}),
  };

  const izYolu = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "Ana Sayfa", item: siteUrl },
      {
        "@type": "ListItem",
        position: 2,
        name: "Blog",
        item: buildSiteUrl("/blog"),
      },
      { "@type": "ListItem", position: 3, name: yazi.baslik, item: yaziUrl },
    ],
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: safeJsonLdHtml(blogPosting) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: safeJsonLdHtml(izYolu) }}
      />

      <div className="bg-lp-bg-editor px-4 py-10 sm:px-5 sm:py-14">
        <div className="mx-auto w-full max-w-[1180px]">
          <nav aria-label="İz yolu" className="text-sm font-bold text-lp-muted">
            <Link
              href="/blog"
              className="inline-flex min-h-11 items-center text-lp-secondary outline-none hover:text-lp-text focus-visible:ring-2 focus-visible:ring-lp-secondary"
            >
              ← Blog
            </Link>
            <span aria-hidden="true" className="mx-2">
              /
            </span>
            <span>{yazi.kategori}</span>
          </nav>

          <div className="mt-4 grid gap-8 lg:grid-cols-[200px_minmax(0,740px)] lg:justify-center lg:gap-12">
            {icindekilerGoster ? (
              <aside className="hidden self-start border-l border-lp-border pl-5 lg:sticky lg:top-24 lg:block">
                <p className="text-sm font-black text-lp-text">Bu yazıda</p>
                <nav aria-label="Bu yazıda" className="mt-3 space-y-3">
                  {icindekiler.map((madde) => (
                    <a
                      key={`${madde.id}-${madde.seviye}`}
                      href={`#${madde.id}`}
                      className={`block text-sm font-semibold leading-5 text-lp-muted outline-none hover:text-lp-secondary focus-visible:ring-2 focus-visible:ring-lp-secondary ${
                        madde.seviye === 3 ? "pl-3" : ""
                      }`}
                    >
                      {madde.baslik}
                    </a>
                  ))}
                </nav>
              </aside>
            ) : (
              <div className="hidden lg:block" aria-hidden="true" />
            )}

            <article className="min-w-0">
              <p className="text-xs font-black text-lp-secondary">
                {yazi.kategori}
                {yazi.icerikTuru === "rehber" ? " · Rehber" : ""}
              </p>
              <h1 className="mt-3 break-words text-4xl font-black leading-[1.08] tracking-[-0.035em] text-lp-text sm:text-5xl">
                {yazi.baslik}
              </h1>
              <p className="mt-5 text-lg font-medium leading-8 text-lp-muted sm:text-xl">
                {yazi.ozet}
              </p>

              <div className="mt-5 flex flex-wrap gap-x-5 gap-y-2 text-sm font-bold leading-6 text-lp-muted">
                <span>
                  Yazar:{" "}
                  {yazi.yazar.url ? (
                    <Link
                      href={yazi.yazar.url}
                      className="text-lp-secondary underline decoration-lp-border underline-offset-4 outline-none hover:text-lp-text focus-visible:ring-2 focus-visible:ring-lp-secondary"
                    >
                      {yazi.yazar.ad}
                    </Link>
                  ) : (
                    yazi.yazar.ad
                  )}
                </span>
                {yazi.inceleyen ? <span>İnceleyen: {yazi.inceleyen.ad}</span> : null}
                <span>
                  Yayınlandı:{" "}
                  <time dateTime={yazi.yayinTarihi}>
                    {tarihiYaz(yazi.yayinTarihi)}
                  </time>
                </span>
                {anlamliGuncelleme ? (
                  <span>
                    Güncellendi:{" "}
                    <time dateTime={yazi.guncellemeTarihi!}>
                      {tarihiYaz(yazi.guncellemeTarihi!)}
                    </time>
                  </span>
                ) : null}
                <span>
                  Son kontrol:{" "}
                  <time dateTime={yazi.sonKontrolTarihi}>
                    {tarihiYaz(yazi.sonKontrolTarihi)}
                  </time>
                </span>
                {yazi.kaynaklar.length > 0 ? (
                  <span>{yazi.kaynaklar.length} kaynak</span>
                ) : null}
                <span>{okumaDakika} dk okuma</span>
              </div>

              <aside
                className="mt-7 border-l-2 border-lp-primary pl-4 sm:pl-5"
                aria-label="Bu rehberin amacı"
              >
                <p className="text-xs font-black uppercase tracking-[0.16em] text-lp-secondary">
                  Bu rehber hangi soruyu çözüyor?
                </p>
                <p className="mt-2 text-base font-semibold leading-7 text-lp-text">
                  {yazi.cozduguSoru}
                </p>
              </aside>

              {icindekilerGoster ? (
                <details className="mt-7 rounded-[16px] border border-lp-border bg-lp-surface px-4 py-3 lg:hidden">
                  <summary className="min-h-11 cursor-pointer py-3 font-black text-lp-text">
                    Bu yazıda
                  </summary>
                  <nav aria-label="Bu yazıda mobil" className="pb-3">
                    {icindekiler.map((madde) => (
                      <a
                        key={`mobil-${madde.id}-${madde.seviye}`}
                        href={`#${madde.id}`}
                        className={`block min-h-11 py-2 text-sm font-semibold leading-6 text-lp-muted ${
                          madde.seviye === 3 ? "pl-4" : ""
                        }`}
                      >
                        {madde.baslik}
                      </a>
                    ))}
                  </nav>
                </details>
              ) : null}

              {yazi.kapak ? (
                <figure className="mt-8">
                  <div className="relative aspect-[16/9] overflow-hidden rounded-[22px] border border-lp-border bg-lp-surface-soft">
                    <Image
                      src={yazi.kapak}
                      alt={yazi.kapakAlt || yazi.baslik}
                      fill
                      preload
                      sizes="(max-width: 768px) 100vw, 740px"
                      className="object-cover"
                    />
                  </div>
                  {yazi.gorselKaynagi ? (
                    <figcaption className="mt-2 text-xs font-medium leading-5 text-lp-muted">
                      Görsel kaynağı: {yazi.gorselKaynagi}
                    </figcaption>
                  ) : null}
                </figure>
              ) : (
                <div
                  className="relative mt-8 flex aspect-[16/9] overflow-hidden rounded-[22px] border border-lp-border bg-lp-surface-soft p-6 sm:p-8"
                  role="img"
                  aria-label={`${yazi.baslik} için Vixrex editoryal kapak`}
                >
                  <span
                    aria-hidden="true"
                    className="absolute right-8 top-7 h-28 w-28 rounded-full border border-lp-primary/25"
                  />
                  <span
                    aria-hidden="true"
                    className="absolute bottom-8 right-20 h-14 w-14 rounded-full border border-lp-secondary/25"
                  />
                  <div className="relative z-10 flex w-full flex-col justify-between">
                    <div className="flex items-center justify-between gap-4">
                      <span className="text-xs font-black uppercase tracking-[0.18em] text-lp-secondary">
                        Vixrex Blog
                      </span>
                      <span className="rounded-full border border-lp-border bg-lp-bg-editor/40 px-3 py-1 text-[11px] font-black text-lp-muted">
                        {yazi.icerikTuru === "rehber" ? "Rehber" : yazi.kategori}
                      </span>
                    </div>
                    <div className="max-w-[80%]">
                      <p className="text-xs font-black uppercase tracking-[0.14em] text-lp-muted">
                        {yazi.kategori}
                      </p>
                      <p className="mt-3 break-words text-2xl font-black leading-tight tracking-tight text-lp-text sm:text-4xl">
                        {yazi.baslik}
                      </p>
                    </div>
                  </div>
                </div>
              )}

              <div className="mt-9 text-[17px] font-medium leading-[1.75] text-lp-text sm:text-lg">
                {bloklar.map((blok, index) => {
                  if (blok.tur === "h2") {
                    return (
                      <h2
                        key={`${blok.id}-${index}`}
                        id={blok.id}
                        className="scroll-mt-24 pt-8 text-3xl font-black leading-tight tracking-tight text-lp-text"
                      >
                        {blok.metin}
                      </h2>
                    );
                  }
                  if (blok.tur === "h3") {
                    return (
                      <h3
                        key={`${blok.id}-${index}`}
                        id={blok.id}
                        className="scroll-mt-24 pt-6 text-2xl font-black leading-tight text-lp-text"
                      >
                        {blok.metin}
                      </h3>
                    );
                  }
                  if (blok.tur === "liste") {
                    const Liste = blok.sirali ? "ol" : "ul";
                    return (
                      <Liste
                        key={`liste-${index}`}
                        className={`my-5 space-y-2 pl-6 ${
                          blok.sirali ? "list-decimal" : "list-disc"
                        }`}
                      >
                        {blok.maddeler.map((madde, maddeIndex) => (
                          <li key={`${madde}-${maddeIndex}`}>{madde}</li>
                        ))}
                      </Liste>
                    );
                  }
                  return (
                    <p key={`p-${index}`} className="mt-5">
                      {blok.metin}
                    </p>
                  );
                })}
              </div>

              {yazi.kaynaklar.length > 0 ? (
                <section
                  className="mt-12 border-t border-lp-border pt-7"
                  aria-labelledby="kaynaklar"
                >
                  <h2 id="kaynaklar" className="text-2xl font-black text-lp-text">
                    Kaynaklar
                  </h2>
                  <ul className="mt-4 space-y-3">
                    {yazi.kaynaklar.map((kaynak) => (
                      <li key={kaynak.url}>
                        <a
                          href={kaynak.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="font-bold leading-6 text-lp-secondary underline decoration-lp-border underline-offset-4 outline-none hover:text-lp-text focus-visible:ring-2 focus-visible:ring-lp-secondary"
                        >
                          {kaynak.baslik}
                        </a>
                      </li>
                    ))}
                  </ul>
                </section>
              ) : null}

              {yazi.guncellemeNotlari.length > 0 ? (
                <section
                  className="mt-12 border-t border-lp-border pt-7"
                  aria-labelledby="guncelleme-gecmisi"
                >
                  <h2
                    id="guncelleme-gecmisi"
                    className="text-2xl font-black text-lp-text"
                  >
                    Güncelleme geçmişi
                  </h2>
                  <div className="mt-4 divide-y divide-lp-border">
                    {yazi.guncellemeNotlari.map((not) => (
                      <div
                        key={`${not.tarih}-${not.aciklama}`}
                        className="py-4"
                      >
                        <p className="font-black text-lp-text">
                          {tarihiYaz(not.tarih)}
                        </p>
                        <p className="mt-1 text-sm font-medium leading-6 text-lp-muted">
                          {not.aciklama}
                        </p>
                      </div>
                    ))}
                  </div>
                </section>
              ) : null}

              <section className="mt-12 rounded-[18px] border border-lp-border bg-lp-surface px-5 py-5 sm:flex sm:items-center sm:justify-between sm:gap-6">
                <div>
                  <h2 className="text-base font-black text-lp-text">
                    Bu bilgi yanlış veya eski mi?
                  </h2>
                  <p className="mt-1 text-sm font-medium leading-6 text-lp-muted">
                    Düzeltme bildirimini iletişim sayfasından iletebilirsiniz.
                  </p>
                </div>
                <Link
                  href="/iletisim"
                  className="mt-4 inline-flex min-h-11 items-center rounded-full font-black text-lp-secondary outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary sm:mt-0"
                >
                  Düzeltme bildir →
                </Link>
              </section>

              {ilgiliYazilar.length > 0 ? (
                <section
                  className="mt-12 border-t border-lp-border pt-7"
                  aria-labelledby="ilgili-yazilar"
                >
                  <h2
                    id="ilgili-yazilar"
                    className="text-2xl font-black text-lp-text"
                  >
                    İlgili rehberler
                  </h2>
                  <div className="mt-4 grid gap-4 sm:grid-cols-2">
                    {ilgiliYazilar.map((ilgili) => (
                      <Link
                        key={ilgili.slug}
                        href={`/blog/${ilgili.slug}`}
                        className="rounded-[16px] border border-lp-border bg-lp-surface px-5 py-5 outline-none hover:border-lp-primary focus-visible:ring-2 focus-visible:ring-lp-secondary"
                      >
                        <span className="text-xs font-black text-lp-secondary">
                          {ilgili.kategori}
                        </span>
                        <span className="mt-2 block font-black leading-6 text-lp-text">
                          {ilgili.baslik}
                        </span>
                      </Link>
                    ))}
                  </div>
                </section>
              ) : null}

              <section className="mt-12 border-t border-lp-border pt-7">
                <h2 className="text-xl font-black text-lp-text">{cta.baslik}</h2>
                <p className="mt-2 text-sm font-medium leading-6 text-lp-muted">
                  {cta.aciklama}
                </p>
                <Link
                  href={cta.href}
                  className="mt-4 inline-flex min-h-11 items-center justify-center rounded-full bg-lp-primary px-6 text-sm font-black text-lp-on-primary outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary focus-visible:ring-offset-2 focus-visible:ring-offset-lp-bg-editor"
                >
                  {cta.etiket}
                </Link>
              </section>
            </article>
          </div>
        </div>
      </div>
    </>
  );
}
