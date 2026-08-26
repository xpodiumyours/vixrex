import Link from "next/link";
import type { KesfetVitrini } from "@/lib/explore";

/**
 * Keşfet kartı — Flutter'daki `vitrin_store_card.dart`'ın web karşılığı.
 *
 * Kiralık (örnek) vitrinlerde iki eylem var: "İncele" vitrini açar,
 * "Kirala" güvenli köprü sayfasına gider. Köprü ÖNEMLİ: `/api/rent-demo`
 * doğrudan çağrılmaz, reCAPTCHA doğrulaması `/rent-demo` sayfasında yapılır
 * (2026-08-15 güvenlik düzeltmesi, bkz. api/rent-demo/route.ts başlığı).
 */
export function VitrinKarti({ vitrin }: { vitrin: KesfetVitrini }) {
  return (
    <article className="flex h-full flex-col overflow-hidden rounded-3xl border border-lp-border/70 bg-lp-surface">
      <Link
        href={`/v/${vitrin.slug}`}
        className="relative block aspect-[4/3] w-full overflow-hidden bg-lp-surface-soft"
      >
        {vitrin.kapakUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={vitrin.kapakUrl}
            alt=""
            className="h-full w-full object-cover"
            loading="lazy"
          />
        ) : (
          <span className="flex h-full w-full items-center justify-center px-4 text-center text-[12px] font-bold text-lp-muted">
            Kapak görseli bekleniyor
          </span>
        )}

        {vitrin.kiralikMi ? (
          <span className="absolute left-3 top-3 rounded-full bg-amber-400 px-2.5 py-1 text-[10px] font-black tracking-[1px] text-lp-bg-editor">
            KİRALIK
          </span>
        ) : (
          <span
            className={`absolute left-3 top-3 rounded-full px-2.5 py-1 text-[10px] font-black tracking-[1px] ${
              vitrin.acikMi
                ? "bg-lp-mint text-lp-bg-editor"
                : "bg-lp-border text-lp-text-alt"
            }`}
          >
            {vitrin.acikMi ? "CANLI" : "KAPALI"}
          </span>
        )}
      </Link>

      <div className="flex flex-1 flex-col gap-1 p-4">
        <p className="text-[10px] font-black uppercase tracking-[1px] text-lp-primary">
          {vitrin.kategoriEtiketi}
        </p>
        <h3 className="text-[15px] font-black leading-tight text-lp-text">
          <Link href={`/v/${vitrin.slug}`}>{vitrin.ad}</Link>
        </h3>
        <p className="text-[12px] font-semibold text-lp-muted">
          {vitrin.konum}
        </p>

        {vitrin.kiralikMi ? (
          <p className="mt-1 text-[12px] font-bold text-lp-text-alt">
            Aylık 299 TL · 14 gün ücretsiz dene
          </p>
        ) : vitrin.urunSayisi > 0 ? (
          <p className="mt-1 text-[12px] font-semibold text-lp-muted">
            {vitrin.urunSayisi} ürün
          </p>
        ) : null}

        <div className="mt-4 flex gap-2">
          <Link
            href={`/v/${vitrin.slug}`}
            className="flex-1 rounded-xl border border-lp-border px-3 py-2.5 text-center text-[12px] font-black text-lp-text-alt transition-colors hover:bg-lp-surface-soft"
          >
            {vitrin.kiralikMi ? "İncele" : "Vitrini gör"}
          </Link>
          {vitrin.kiralikMi ? (
            <Link
              href={`/rent-demo?slug=${vitrin.slug}`}
              className="flex-1 rounded-xl bg-lp-primary px-3 py-2.5 text-center text-[12px] font-black text-lp-on-primary transition-transform hover:-translate-y-0.5"
            >
              Kirala
            </Link>
          ) : null}
        </div>
      </div>
    </article>
  );
}
