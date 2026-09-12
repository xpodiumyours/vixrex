import Link from "next/link";
import { BlogKapak } from "@/components/blog/BlogKapak";
import { yayindakiYazilar } from "@/data/blogYazilari";
import { okumaDakikasiHesapla, tarihiYaz } from "@/lib/blogIcerik";

export function BlogRehberleri() {
  const yazilar = yayindakiYazilar().slice(0, 3);
  if (yazilar.length === 0) return null;

  return (
    <section className="bg-lp-bg-editor px-5 py-16 sm:px-8 sm:py-20" aria-labelledby="landing-blog-baslik">
      <div className="mx-auto w-full max-w-lp">
        <div className="flex flex-col gap-5 border-b border-lp-border/60 pb-7 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.18em] text-lp-secondary">
              Vixrex Blog
            </p>
            <h2 id="landing-blog-baslik" className="mt-3 text-3xl font-black tracking-tight text-lp-text sm:text-4xl">
              İşletmen için pratik rehberler.
            </h2>
            <p className="mt-3 max-w-2xl text-base leading-7 text-lp-muted">
              Dijital vitrin, keşfedilme ve müşteri iletişimi için doğrudan uygulayabileceğin içerikler.
            </p>
          </div>
          <Link
            href="/blog"
            className="inline-flex min-h-11 shrink-0 items-center font-bold text-lp-secondary outline-none hover:text-lp-text focus-visible:ring-2 focus-visible:ring-lp-secondary"
          >
            Tüm rehberler →
          </Link>
        </div>

        <div className="mt-8 grid gap-7 md:grid-cols-3">
          {yazilar.map((yazi) => (
            <article key={yazi.slug} className="min-w-0">
              <Link
                href={`/blog/${yazi.slug}`}
                className="group block rounded-[20px] outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary focus-visible:ring-offset-4 focus-visible:ring-offset-lp-bg-editor"
              >
                <BlogKapak yazi={yazi} />
                <p className="mt-4 text-xs font-black text-lp-secondary">{yazi.kategori}</p>
                <h3 className="mt-2 text-xl font-black leading-snug tracking-tight text-lp-text group-hover:text-lp-secondary">
                  {yazi.baslik}
                </h3>
                <p className="mt-3 line-clamp-3 text-sm font-medium leading-6 text-lp-muted">
                  {yazi.ozet}
                </p>
                <p className="mt-4 text-xs font-bold text-lp-muted">
                  <time dateTime={yazi.guncellemeTarihi || yazi.yayinTarihi}>
                    {tarihiYaz(yazi.guncellemeTarihi || yazi.yayinTarihi)}
                  </time>
                  {" · "}{okumaDakikasiHesapla(yazi.govde)} dk okuma
                </p>
              </Link>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
