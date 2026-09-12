"use client";

import Link from "next/link";
import { useState } from "react";
import {
  BLOG_KATEGORILERI,
  type BlogKategori,
  type BlogListeYazisi,
} from "@/data/blogYazilari";
import { tarihiYaz } from "@/lib/blogIcerik";
import { blogYazilariniFiltrele } from "@/lib/blogKesif";
import { BlogKapak } from "./BlogKapak";

const odak =
  "outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary focus-visible:ring-offset-4 focus-visible:ring-offset-lp-bg-editor";

export function BlogKesif({ yazilar }: { yazilar: BlogListeYazisi[] }) {
  const [arama, setArama] = useState("");
  const [kategori, setKategori] = useState<"Tümü" | BlogKategori>("Tümü");
  const [limit, setLimit] = useState(9);
  const aktifKategoriler = BLOG_KATEGORILERI.filter((aday) =>
    yazilar.some((yazi) => yazi.kategori === aday),
  );
  const filtreAktif = Boolean(arama.trim()) || kategori !== "Tümü";
  const oneCikan =
    yazilar.find((yazi) => yazi.slug === "dijital-vitrin-hazirlik-listesi") ||
    yazilar[0];
  const sonuclar = blogYazilariniFiltrele(yazilar, arama, kategori);
  const liste = filtreAktif
    ? sonuclar
    : sonuclar.filter((yazi) => yazi.slug !== oneCikan?.slug);
  function temizle() {
    setArama("");
    setKategori("Tümü");
    setLimit(9);
  }

  return (
    <div className="bg-lp-bg-editor px-5 pb-16 pt-8 sm:px-8 sm:pt-12">
      <div className="mx-auto max-w-[1200px]">
        <header className="border-b border-lp-border/60 pb-10 sm:flex sm:items-end sm:justify-between sm:gap-10 sm:pb-12">
          <div>
            <p className="text-xs font-bold uppercase tracking-[.22em] text-lp-secondary">
              Vixrex Blog
            </p>
            <h1 className="mt-4 max-w-[780px] text-4xl font-bold leading-[1.1] tracking-[-.035em] text-lp-text sm:text-5xl lg:text-6xl">
              İşletmen için
              <br />
              <span className="text-lp-secondary">işe yarayan bilgiler.</span>
            </h1>
          </div>
          <p className="mt-5 max-w-[340px] text-base leading-7 text-lp-muted">
            Dijital vitrinden müşteri iletişimine: okuyup kendi işletmende
            uygulayabileceğin rehberler.
          </p>
        </header>

        {oneCikan ? (
          <section
            aria-labelledby="one-cikan-baslik"
            className="grid items-center gap-7 py-10 lg:grid-cols-[1.15fr_1fr] lg:gap-12 lg:py-12"
          >
            <Link
              href={`/blog/${oneCikan.slug}`}
              aria-label={oneCikan.baslik}
              className={`block rounded-2xl ${odak}`}
            >
              <BlogKapak yazi={oneCikan} oncelikli />
            </Link>
            <div>
              <p className="text-xs font-bold uppercase tracking-[.14em] text-lp-secondary">
                Başlamak için · {oneCikan.kategori}
              </p>
              <h2
                id="one-cikan-baslik"
                className="mt-4 text-3xl font-bold leading-tight tracking-tight text-lp-text sm:text-4xl"
              >
                <Link
                  href={`/blog/${oneCikan.slug}`}
                  className={`rounded ${odak} hover:text-lp-secondary`}
                >
                  {oneCikan.baslik}
                </Link>
              </h2>
              <p className="mt-4 text-base leading-7 text-lp-muted">
                {oneCikan.ozet}
              </p>
              <p className="mt-5 text-sm text-lp-muted">
                {oneCikan.okumaDakika} dk okuma{" "}
                <span aria-hidden="true">·</span>{" "}
                <time dateTime={oneCikan.yayinTarihi}>
                  {tarihiYaz(oneCikan.yayinTarihi)}
                </time>
              </p>
              <Link
                href={`/blog/${oneCikan.slug}`}
                className={`mt-6 inline-flex min-h-12 items-center rounded-xl bg-lp-primary px-6 font-bold text-lp-on-primary ${odak}`}
              >
                Rehberi oku{" "}
                <span aria-hidden="true" className="ml-5">
                  ↗
                </span>
              </Link>
            </div>
          </section>
        ) : null}

        <section
          aria-labelledby="rehberler-baslik"
          className="border-t border-lp-border/60 pt-9"
        >
          <div className="flex flex-col gap-5 md:flex-row md:items-end md:justify-between">
            <div>
              <p className="text-xs font-bold uppercase tracking-[.18em] text-lp-secondary">
                Bilgiden uygulamaya
              </p>
              <h2
                id="rehberler-baslik"
                className="mt-2 text-3xl font-bold text-lp-text"
              >
                Sıradaki adımını bul.
              </h2>
            </div>
            <div className="w-full md:max-w-[360px]">
              <label
                htmlFor="blog-arama"
                className="mb-2 block text-sm font-semibold text-lp-muted"
              >
                Rehberlerde ara
              </label>
              <input
                id="blog-arama"
                type="search"
                value={arama}
                onChange={(e) => {
                  setArama(e.target.value);
                  setLimit(9);
                }}
                placeholder="Örn. Google, kuaför, iletişim"
                className="min-h-12 w-full rounded-xl border border-lp-border bg-lp-surface px-4 text-base text-lp-text outline-none placeholder:text-lp-muted focus:border-lp-secondary focus:ring-2 focus:ring-lp-secondary/40"
              />
            </div>
          </div>
          <div
            aria-label="Blog kategorileri"
            className="mt-6 flex flex-wrap gap-2"
          >
            {(["Tümü", ...aktifKategoriler] as const).map((aday) => (
              <button
                key={aday}
                type="button"
                aria-pressed={kategori === aday}
                onClick={() => {
                  setKategori(aday);
                  setLimit(9);
                }}
                className={`min-h-11 rounded-full border px-4 text-sm font-semibold ${odak} ${kategori === aday ? "border-lp-secondary bg-lp-secondary text-lp-on-primary" : "border-lp-border bg-transparent text-lp-muted hover:border-lp-secondary hover:text-lp-text"}`}
              >
                {aday}
              </button>
            ))}
          </div>
          <div className="mt-6 flex min-h-11 items-center justify-between gap-3 text-sm text-lp-muted">
            <p role="status" aria-live="polite">
              {filtreAktif
                ? `${liste.length} sonuç`
                : `${yazilar.length} yazı · İşletmene uygun bir konu seç`}
            </p>
            {filtreAktif ? (
              <button
                type="button"
                onClick={temizle}
                className={`min-h-11 rounded px-2 font-semibold text-lp-secondary ${odak}`}
              >
                Filtreleri temizle
              </button>
            ) : null}
          </div>
          {liste.length ? (
            <div className="mt-3 grid gap-x-7 gap-y-10 md:grid-cols-2 lg:grid-cols-3">
              {liste.slice(0, limit).map((yazi) => (
                <article key={yazi.slug} className="group min-w-0">
                  <Link
                    href={`/blog/${yazi.slug}`}
                    className={`block h-full rounded-2xl ${odak}`}
                  >
                    <BlogKapak yazi={yazi} />
                    <div className="pt-5">
                      <p className="text-xs font-bold text-lp-secondary">
                        {yazi.kategori}
                      </p>
                      <h3 className="mt-2 text-xl font-semibold leading-snug tracking-tight text-lp-text transition-colors group-hover:text-lp-secondary">
                        {yazi.baslik}
                      </h3>
                      <p className="mt-3 text-sm leading-6 text-lp-muted">
                        {yazi.ozet}
                      </p>
                      <p className="mt-4 text-xs text-lp-muted">
                        <time
                          dateTime={yazi.guncellemeTarihi || yazi.yayinTarihi}
                        >
                          {yazi.guncellemeTarihi &&
                          yazi.guncellemeTarihi !== yazi.yayinTarihi
                            ? "Güncellendi · "
                            : ""}
                          {tarihiYaz(yazi.guncellemeTarihi || yazi.yayinTarihi)}
                        </time>{" "}
                        · {yazi.okumaDakika} dk okuma{" "}
                        <span
                          aria-hidden="true"
                          className="float-right text-lg text-lp-secondary"
                        >
                          ↗
                        </span>
                      </p>
                    </div>
                  </Link>
                </article>
              ))}
            </div>
          ) : (
            <div className="mt-3 rounded-2xl border border-dashed border-lp-border p-8">
              <h3 className="text-lg font-semibold text-lp-text">
                Bu aramada yazı bulunamadı.
              </h3>
              <p className="mt-2 text-lp-muted">
                Daha kısa bir kelime dene veya tüm rehberlere dön.
              </p>
              <button
                onClick={temizle}
                type="button"
                className={`mt-4 min-h-11 rounded text-sm font-bold text-lp-secondary ${odak}`}
              >
                Tüm rehberleri göster →
              </button>
            </div>
          )}
          {liste.length > limit ? (
            <button
              type="button"
              onClick={() => setLimit((deger) => deger + 9)}
              className={`mx-auto mt-10 block min-h-12 rounded-xl border border-lp-border px-6 font-bold text-lp-text ${odak}`}
            >
              Daha fazla yazı göster ({liste.length - limit})
            </button>
          ) : null}
        </section>

        <section className="mt-16 flex flex-col gap-6 rounded-2xl border border-lp-border bg-lp-surface p-7 sm:flex-row sm:items-center sm:justify-between sm:p-9">
          <div>
            <p className="text-xs font-bold uppercase tracking-[.16em] text-lp-secondary">
              Şimdi kendi işletmen için
            </p>
            <h2 className="mt-3 text-2xl font-semibold text-lp-text">
              Bilgilerini bir vitrinde buluştur.
            </h2>
            <p className="mt-2 max-w-xl text-sm leading-6 text-lp-muted">
              İşletme bilgilerini, hizmetlerini ve iletişim yollarını nasıl
              sunabileceğini vitrin örneklerinde incele.
            </p>
          </div>
          <Link
            href="/kesfet"
            className={`inline-flex min-h-12 shrink-0 items-center justify-center rounded-xl bg-lp-primary px-5 font-bold text-lp-on-primary ${odak}`}
          >
            Vitrinleri keşfet →
          </Link>
        </section>
        <footer className="mt-10 flex flex-wrap items-center justify-between gap-5 border-t border-lp-border/60 pt-6 text-sm text-lp-muted">
          <p>Vixrex tarafından hazırlanan işletme rehberleri.</p>
          <div className="flex gap-5">
            <Link
              href="/blog/yayin-ilkeleri"
              className={`rounded py-3 hover:text-lp-text ${odak}`}
            >
              Yayın ilkeleri
            </Link>
            <Link
              href="/blog/rss.xml"
              className={`rounded py-3 hover:text-lp-text ${odak}`}
            >
              RSS
            </Link>
          </div>
        </footer>
      </div>
    </div>
  );
}
