"use client";

import Image from "next/image";
import Link from "next/link";
import { useMemo, useState } from "react";
import {
  BLOG_KATEGORILERI,
  type BlogIcerikTuru,
  type BlogKategori,
  type BlogListeYazisi,
} from "@/data/blogYazilari";
import { tarihiYaz } from "@/lib/blogIcerik";

interface Props {
  yazilar: BlogListeYazisi[];
}

function icerikTuruEtiketi(icerikTuru: BlogIcerikTuru): string {
  switch (icerikTuru) {
    case "haber":
      return "Haber";
    case "urun_guncellemesi":
      return "Ürün güncellemesi";
    case "isletme_hikayesi":
      return "İşletme hikâyesi";
    default:
      return "Rehber";
  }
}

function icerikEylemEtiketi(icerikTuru: BlogIcerikTuru): string {
  switch (icerikTuru) {
    case "haber":
      return "Haberi oku";
    case "urun_guncellemesi":
      return "Güncellemeyi oku";
    case "isletme_hikayesi":
      return "Hikâyeyi oku";
    default:
      return "Rehberi oku";
  }
}

function Kapak({
  yazi,
  oncelikli = false,
}: {
  yazi: BlogListeYazisi;
  oncelikli?: boolean;
}) {
  if (!yazi.kapak) {
    return (
      <div
        className="relative flex aspect-[16/9] overflow-hidden rounded-[20px] border border-lp-border bg-lp-surface-soft p-6 sm:p-7"
        role="img"
        aria-label={`${yazi.baslik} için Vixrex editoryal kapak`}
      >
        <span
          aria-hidden="true"
          className="absolute right-5 top-5 h-20 w-20 rounded-full border border-lp-primary/25"
        />
        <span
          aria-hidden="true"
          className="absolute bottom-5 right-10 h-10 w-10 rounded-full border border-lp-secondary/25"
        />
        <div className="relative z-10 flex w-full flex-col justify-between">
          <div className="flex items-center justify-between gap-4">
            <span className="text-xs font-black uppercase tracking-[0.18em] text-lp-secondary">
              Vixrex Blog
            </span>
            <span className="rounded-full border border-lp-border bg-lp-bg-editor/40 px-3 py-1 text-[11px] font-black text-lp-muted">
              {icerikTuruEtiketi(yazi.icerikTuru)}
            </span>
          </div>
          <div className="max-w-[82%]">
            <p className="text-xs font-black uppercase tracking-[0.14em] text-lp-muted">
              {yazi.kategori}
            </p>
            <p className="mt-2 break-words text-xl font-black leading-tight tracking-tight text-lp-text sm:text-2xl">
              {yazi.baslik}
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="relative aspect-[16/9] overflow-hidden rounded-[20px] border border-lp-border bg-lp-surface-soft">
      <Image
        src={yazi.kapak}
        alt={yazi.kapakAlt || yazi.baslik}
        fill
        preload={oncelikli}
        sizes={
          oncelikli
            ? "(max-width: 768px) 100vw, 58vw"
            : "(max-width: 768px) 100vw, 33vw"
        }
        className="object-cover"
      />
    </div>
  );
}

function YaziKarti({ yazi }: { yazi: BlogListeYazisi }) {
  const anlamliGuncelleme =
    Boolean(yazi.guncellemeTarihi) &&
    yazi.guncellemeTarihi !== yazi.yayinTarihi;

  return (
    <article className="flex min-w-0 flex-col overflow-hidden rounded-[20px] border border-lp-border bg-lp-surface">
      <div className="p-4 pb-0">
        <Kapak yazi={yazi} />
      </div>
      <div className="flex flex-1 flex-col px-5 pb-5 pt-4 sm:px-6 sm:pb-6">
        <p className="text-xs font-black text-lp-secondary">
          {yazi.kategori} · {icerikTuruEtiketi(yazi.icerikTuru)}
        </p>
        <h3 className="mt-2 break-words text-xl font-black leading-snug tracking-tight text-lp-text">
          {yazi.baslik}
        </h3>
        <p className="mt-3 text-sm font-medium leading-6 text-lp-muted">
          {yazi.ozet}
        </p>
        <p className="mt-auto pt-5 text-xs font-bold leading-5 text-lp-muted">
          <time
            dateTime={
              anlamliGuncelleme ? yazi.guncellemeTarihi! : yazi.yayinTarihi
            }
          >
            {anlamliGuncelleme
              ? `Güncellendi ${tarihiYaz(yazi.guncellemeTarihi!)}`
              : tarihiYaz(yazi.yayinTarihi)}
          </time>
          {" · "}
          {yazi.okumaDakika} dk okuma
        </p>
        <Link
          href={`/blog/${yazi.slug}`}
          className="mt-4 inline-flex min-h-11 items-center self-start rounded-full text-sm font-black text-lp-secondary outline-none transition-colors hover:text-lp-text focus-visible:ring-2 focus-visible:ring-lp-secondary focus-visible:ring-offset-2 focus-visible:ring-offset-lp-surface"
        >
          {icerikEylemEtiketi(yazi.icerikTuru)} →
        </Link>
      </div>
    </article>
  );
}

export function BlogKesif({ yazilar }: Props) {
  const [arama, setArama] = useState("");
  const [kategori, setKategori] = useState<"Tümü" | BlogKategori>("Tümü");

  const aktifKategoriler = useMemo(() => {
    const bulunan = new Set(yazilar.map((yazi) => yazi.kategori));
    return BLOG_KATEGORILERI.filter((aday) => bulunan.has(aday));
  }, [yazilar]);

  const filtreAktif = arama.trim().length > 0 || kategori !== "Tümü";
  const aramaNormalize = arama.trim().toLocaleLowerCase("tr-TR");
  const oneCikan = yazilar[0];

  const guncellemeler = yazilar
    .filter(
      (yazi) =>
        yazi.kategori === "Vixrex’te Yenilikler" &&
        yazi.slug !== oneCikan?.slug
    )
    .slice(0, 3);

  const baslangic = yazilar.find(
    (yazi) =>
      yazi.kategori === "Dijital Vitrin" &&
      yazi.icerikTuru === "rehber" &&
      yazi.slug !== oneCikan?.slug &&
      !guncellemeler.some((guncelleme) => guncelleme.slug === yazi.slug)
  );

  const sonuclar = useMemo(
    () =>
      yazilar.filter((yazi) => {
        if (!filtreAktif && oneCikan && yazi.slug === oneCikan.slug) {
          return false;
        }
        if (kategori !== "Tümü" && yazi.kategori !== kategori) return false;
        if (!aramaNormalize) return true;
        const aranan = [
          yazi.baslik,
          yazi.ozet,
          yazi.kategori,
          yazi.icerikTuru,
          ...yazi.sektorler,
        ]
          .join(" ")
          .toLocaleLowerCase("tr-TR");
        return aranan.includes(aramaNormalize);
      }),
    [aramaNormalize, filtreAktif, kategori, oneCikan, yazilar]
  );

  const ayrikTutulanSluglar = new Set([
    oneCikan?.slug,
    baslangic?.slug,
    ...guncellemeler.map((yazi) => yazi.slug),
  ]);

  const sonRehberler = filtreAktif
    ? sonuclar
    : sonuclar.filter(
        (yazi) =>
          yazi.icerikTuru === "rehber" && !ayrikTutulanSluglar.has(yazi.slug)
      );

  return (
    <div className="bg-lp-bg-editor px-4 py-10 sm:px-5 sm:py-14">
      <div className="mx-auto w-full max-w-[1200px]">
        <header className="max-w-3xl">
          <p className="text-xs font-black uppercase tracking-[0.18em] text-lp-secondary">
            Vixrex Blog
          </p>
          <h1 className="mt-3 text-4xl font-black leading-[1.05] tracking-[-0.04em] text-lp-text sm:text-5xl lg:text-6xl">
            İşletmen için bir adım ileri.
          </h1>
          <p className="mt-5 max-w-2xl text-base font-medium leading-7 text-lp-muted sm:text-lg sm:leading-8">
            Dijital vitrinin, müşterilerin ve işini kolaylaştıran yenilikler
            için anlaşılır rehberler.
          </p>
        </header>

        {!filtreAktif && oneCikan ? (
          <section
            className="mt-10 grid gap-6 border-t border-lp-border pt-8 lg:grid-cols-[minmax(0,1.2fr)_minmax(320px,.8fr)] lg:items-center lg:gap-10"
            aria-labelledby="one-cikan-baslik"
          >
            <Kapak yazi={oneCikan} oncelikli />
            <div>
              <p className="text-xs font-black text-lp-secondary">
                {oneCikan.kategori} · {icerikTuruEtiketi(oneCikan.icerikTuru)}
              </p>
              <h2
                id="one-cikan-baslik"
                className="mt-3 break-words text-3xl font-black leading-tight tracking-tight text-lp-text sm:text-4xl"
              >
                {oneCikan.baslik}
              </h2>
              <p className="mt-4 text-base font-medium leading-7 text-lp-muted">
                {oneCikan.ozet}
              </p>
              <p className="mt-4 text-xs font-bold text-lp-muted">
                {tarihiYaz(oneCikan.yayinTarihi)} ·{" "}
                {oneCikan.okumaDakika} dk okuma
              </p>
              <Link
                href={`/blog/${oneCikan.slug}`}
                className="mt-6 inline-flex min-h-11 items-center justify-center rounded-full bg-lp-primary px-6 text-sm font-black text-lp-on-primary outline-none transition-opacity hover:opacity-90 focus-visible:ring-2 focus-visible:ring-lp-secondary focus-visible:ring-offset-2 focus-visible:ring-offset-lp-bg-editor"
              >
                {icerikEylemEtiketi(oneCikan.icerikTuru)}
              </Link>
            </div>
          </section>
        ) : null}

        <section
          className="mt-12 border-t border-lp-border pt-8"
          aria-labelledby="arama-baslik"
        >
          <div className="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <p className="text-xs font-black uppercase tracking-[0.18em] text-lp-secondary">
                İçerik bul
              </p>
              <h2
                id="arama-baslik"
                className="mt-2 text-2xl font-black text-lp-text sm:text-3xl"
              >
                Ne öğrenmek istersin?
              </h2>
            </div>
            <div className="w-full lg:max-w-[440px]">
              <label htmlFor="blog-arama" className="sr-only">
                Blogda ara
              </label>
              <input
                id="blog-arama"
                type="search"
                value={arama}
                onChange={(event) => setArama(event.target.value)}
                placeholder="Örn. çalışma saatleri, WhatsApp, Google"
                className="min-h-12 w-full rounded-[14px] border border-lp-border bg-lp-surface px-4 text-base font-semibold text-lp-text outline-none placeholder:text-lp-muted focus:border-lp-secondary focus:ring-2 focus:ring-lp-secondary/25"
              />
            </div>
          </div>

          <div
            className="mt-4 flex gap-2 overflow-x-auto pb-2"
            aria-label="Blog kategorileri"
          >
            {(["Tümü", ...aktifKategoriler] as const).map((aday) => {
              const secili = kategori === aday;
              return (
                <button
                  key={aday}
                  type="button"
                  aria-pressed={secili}
                  onClick={() => setKategori(aday)}
                  className={`min-h-11 shrink-0 rounded-full border px-4 text-sm font-black outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary focus-visible:ring-offset-2 focus-visible:ring-offset-lp-bg-editor ${
                    secili
                      ? "border-lp-primary bg-lp-primary text-lp-on-primary"
                      : "border-lp-border bg-lp-surface text-lp-muted hover:text-lp-text"
                  }`}
                >
                  {aday}
                </button>
              );
            })}
          </div>

          {filtreAktif || sonRehberler.length > 0 ? (
            <>
              <div className="mt-7 flex items-baseline justify-between gap-4">
                <h2 className="text-2xl font-black text-lp-text">
                  {filtreAktif
                    ? `Sonuçlar (${sonRehberler.length})`
                    : "Son rehberler"}
                </h2>
              </div>

              {sonRehberler.length > 0 ? (
                <div className="mt-5 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                  {sonRehberler.map((yazi) => (
                    <YaziKarti key={yazi.slug} yazi={yazi} />
                  ))}
                </div>
              ) : (
                <div
                  className="mt-5 rounded-[20px] border border-dashed border-lp-border bg-lp-surface px-6 py-8"
                  role="status"
                >
                  <p className="font-black text-lp-text">Sonuç bulunamadı.</p>
                  <p className="mt-2 text-sm font-medium leading-6 text-lp-muted">
                    Aramayı sadeleştir veya başka bir kategori seç.
                  </p>
                </div>
              )}
            </>
          ) : null}
        </section>

        {!filtreAktif && guncellemeler.length > 0 ? (
          <section
            className="mt-14 border-t border-lp-border pt-8"
            aria-labelledby="yenilik-baslik"
          >
            <p className="text-xs font-black uppercase tracking-[0.18em] text-lp-secondary">
              Ürün güncellemeleri
            </p>
            <h2
              id="yenilik-baslik"
              className="mt-2 text-2xl font-black text-lp-text sm:text-3xl"
            >
              Vixrex’te neler yeni?
            </h2>
            <div className="mt-5 overflow-hidden rounded-[18px] border border-lp-border">
              {guncellemeler.map((yazi) => (
                <article
                  key={yazi.slug}
                  className="grid gap-2 border-b border-lp-border bg-lp-surface px-5 py-5 last:border-b-0 sm:grid-cols-[150px_1fr] sm:gap-5"
                >
                  <time className="text-sm font-black text-lp-secondary">
                    {tarihiYaz(yazi.guncellemeTarihi || yazi.yayinTarihi)}
                  </time>
                  <div>
                    <h3 className="font-black text-lp-text">
                      <Link
                        href={`/blog/${yazi.slug}`}
                        className="outline-none hover:text-lp-secondary focus-visible:ring-2 focus-visible:ring-lp-secondary"
                      >
                        {yazi.baslik}
                      </Link>
                    </h3>
                    <p className="mt-1 text-sm font-medium leading-6 text-lp-muted">
                      {yazi.ozet}
                    </p>
                  </div>
                </article>
              ))}
            </div>
            <button
              type="button"
              onClick={() => setKategori("Vixrex’te Yenilikler")}
              className="mt-5 inline-flex min-h-11 items-center rounded-full font-black text-lp-secondary outline-none hover:text-lp-text focus-visible:ring-2 focus-visible:ring-lp-secondary focus-visible:ring-offset-2 focus-visible:ring-offset-lp-bg-editor"
            >
              Tüm yenilikleri gör →
            </button>
          </section>
        ) : null}

        {!filtreAktif && baslangic ? (
          <section className="mt-14 rounded-[22px] border border-lp-border bg-lp-surface-soft px-6 py-7 sm:flex sm:items-center sm:justify-between sm:gap-8">
            <div>
              <p className="text-xs font-black uppercase tracking-[0.18em] text-lp-secondary">
                Başlangıç rehberi
              </p>
              <h2 className="mt-2 text-2xl font-black text-lp-text">
                İlk vitrinin için nereden başlamalısın?
              </h2>
              <p className="mt-2 max-w-2xl text-sm font-medium leading-6 text-lp-muted">
                {baslangic.ozet}
              </p>
            </div>
            <Link
              href={`/blog/${baslangic.slug}`}
              className="mt-5 inline-flex min-h-11 shrink-0 items-center justify-center rounded-full bg-lp-primary px-5 text-sm font-black text-lp-on-primary outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary focus-visible:ring-offset-2 focus-visible:ring-offset-lp-surface-soft sm:mt-0"
            >
              Başlangıç rehberini aç
            </Link>
          </section>
        ) : null}

        <section className="mt-14 border-t border-lp-border pt-7 text-sm font-medium leading-6 text-lp-muted">
          <p>
            İçerikler kaynak, güncelleme ve düzeltme bilgileri görünür olacak
            şekilde hazırlanır.
          </p>
          <div className="mt-3 flex flex-wrap gap-x-5 gap-y-2">
            <Link
              className="font-black text-lp-secondary outline-none hover:text-lp-text focus-visible:ring-2 focus-visible:ring-lp-secondary"
              href="/iletisim"
            >
              Düzeltme bildir
            </Link>
            <Link
              className="font-black text-lp-secondary outline-none hover:text-lp-text focus-visible:ring-2 focus-visible:ring-lp-secondary"
              href="/blog/rss.xml"
            >
              RSS
            </Link>
          </div>
        </section>
      </div>
    </div>
  );
}
