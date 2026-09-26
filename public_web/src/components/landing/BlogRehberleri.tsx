import Link from "next/link";
import { yayindakiYazilar } from "@/data/blogYazilari";
import { okumaDakikasiHesapla } from "@/lib/blogIcerik";

export function BlogRehberleri() {
  const yazilar = yayindakiYazilar().slice(0, 3);
  if (!yazilar.length) return null;
  return (
    <section
      aria-labelledby="landing-blog-baslik"
      className="bg-lp-bg-editor px-5 py-16 sm:px-8"
    >
      <div className="mx-auto max-w-[1200px]">
        <div className="flex flex-wrap items-end justify-between gap-5">
          <div>
            <p className="text-xs font-bold uppercase tracking-[.18em] text-lp-secondary">
              Vixrex Blog
            </p>
            <h2
              id="landing-blog-baslik"
              className="mt-3 text-3xl font-bold text-lp-text"
            >
              İşletmen için pratik rehberler.
            </h2>
            <p className="mt-3 text-lp-muted">
              İlk vitrinden günlük müşteri iletişimine, bir sonraki adımın
              burada.
            </p>
          </div>
          <Link
            href="/blog"
            className="inline-flex min-h-11 items-center rounded px-2 font-bold text-lp-secondary outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary"
          >
            Tüm rehberler →
          </Link>
        </div>
        <div className="mt-8 grid gap-5 md:grid-cols-3">
          {yazilar.map((yazi) => (
            <Link
              key={yazi.slug}
              href={`/blog/${yazi.slug}`}
              className="rounded-2xl border border-lp-border bg-lp-surface p-6 outline-none transition-colors hover:border-lp-secondary focus-visible:ring-2 focus-visible:ring-lp-secondary"
            >
              <p className="text-xs font-bold text-lp-secondary">
                {yazi.kategori}
              </p>
              <h3 className="mt-3 text-xl font-semibold leading-snug text-lp-text">
                {yazi.baslik}
              </h3>
              <p className="mt-3 text-sm leading-6 text-lp-muted">
                {yazi.ozet}
              </p>
              <p className="mt-5 text-sm text-lp-secondary">
                {okumaDakikasiHesapla(yazi.govde)} dk okuma{" "}
                <span aria-hidden="true">↗</span>
              </p>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}
