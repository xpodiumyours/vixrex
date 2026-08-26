import Link from "next/link";
import {
  BUSINESS_CATEGORIES,
  kategoriUrlParcasi,
} from "@/lib/businessCategories";

/**
 * Kategori süzgeci — BİLEREK düz bağlantı, istemci durumu yok.
 *
 * JavaScript ile süzülen bir liste kategorileri arama motorundan gizler;
 * #344'ün amacı tam da taranabilir yüzey üretmek. Her kategori kendi
 * adresine sahip olduğu için hem tarayıcı hem robot aynı sayfaya ulaşır.
 */
export function KategoriSeridi({ aktifKimlik }: { aktifKimlik?: string }) {
  return (
    <nav aria-label="Kategoriler" className="flex flex-wrap gap-2">
      <Link
        href="/kesfet"
        className={`rounded-full border px-3.5 py-2 text-[12px] font-black transition-colors ${
          aktifKimlik
            ? "border-lp-border bg-lp-surface text-lp-text-alt hover:bg-lp-surface-soft"
            : "border-lp-primary bg-lp-primary text-lp-on-primary"
        }`}
      >
        Tümü
      </Link>
      {BUSINESS_CATEGORIES.map((kategori) => {
        const aktif = kategori.id === aktifKimlik;
        return (
          <Link
            key={kategori.id}
            href={`/kesfet/${kategoriUrlParcasi(kategori.id)}`}
            aria-current={aktif ? "page" : undefined}
            className={`rounded-full border px-3.5 py-2 text-[12px] font-black transition-colors ${
              aktif
                ? "border-lp-primary bg-lp-primary text-lp-on-primary"
                : "border-lp-border bg-lp-surface text-lp-text-alt hover:bg-lp-surface-soft"
            }`}
          >
            {kategori.label}
          </Link>
        );
      })}
    </nav>
  );
}
