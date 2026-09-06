import Link from "next/link";
import type { BlogYazisi } from "@/data/blogYazilari";
import { tarihiYaz } from "@/lib/blogIcerik";
import {
  blogSectorById,
  blogSectorUrl,
  blogTopicById,
} from "@/lib/blogTaxonomy";

export function BlogArticleCard({ yazi }: { yazi: BlogYazisi }) {
  const konu = blogTopicById(yazi.konu);
  const sektorler = yazi.sektorler
    .map((id) => blogSectorById(id))
    .filter((sektor): sektor is NonNullable<typeof sektor> => Boolean(sektor));

  return (
    <article className="flex h-full flex-col overflow-hidden rounded-3xl border border-lp-border/80 bg-lp-surface shadow-sm transition-colors hover:border-lp-primary/50">
      {yazi.kapakGorseli ? (
        // Merkezi kapaklar Vixrex yükleme hattında optimize edilir; burada yalnız responsive gösterilir.
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={yazi.kapakGorseli}
          alt={`${yazi.baslik} kapak görseli`}
          loading="lazy"
          className="aspect-[16/9] w-full object-cover"
        />
      ) : null}

      <div className="flex flex-1 flex-col p-6 sm:p-7">
        <div className="flex flex-wrap gap-2">
          {konu ? (
            <Link
              href={`/blog/konu/${konu.id}`}
              className="rounded-full bg-lp-primary/[0.08] px-3 py-1 text-[11px] font-black text-lp-primary"
            >
              {konu.label}
            </Link>
          ) : (
            <span className="text-[11px] font-black uppercase tracking-[0.14em] text-lp-primary">
              Rehber
            </span>
          )}
          {sektorler.slice(0, 2).map((sektor) => (
            <Link
              key={sektor.id}
              href={`/blog/sektor/${blogSectorUrl(sektor.id)}`}
              className="rounded-full border border-lp-border px-3 py-1 text-[11px] font-extrabold text-lp-muted hover:border-lp-primary/50 hover:text-lp-primary"
            >
              {sektor.label}
            </Link>
          ))}
        </div>

        <h3 className="mt-4 text-xl font-black leading-snug text-lp-text">
          <Link href={`/blog/${yazi.slug}`} className="hover:text-lp-primary">
            {yazi.baslik}
          </Link>
        </h3>
        <p className="mt-3 flex-1 text-sm font-medium leading-6 text-lp-muted">
          {yazi.ozet}
        </p>
        <div className="mt-6 flex items-center justify-between gap-4 border-t border-lp-border pt-4">
          <p className="text-xs font-bold text-lp-muted">
            {tarihiYaz(yazi.yayinTarihi)} · {yazi.okumaDakika} dk
          </p>
          <Link
            href={`/blog/${yazi.slug}`}
            className="shrink-0 text-xs font-black text-lp-primary"
          >
            Oku →
          </Link>
        </div>
      </div>
    </article>
  );
}
