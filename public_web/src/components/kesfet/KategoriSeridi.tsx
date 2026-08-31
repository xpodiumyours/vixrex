import Link from "next/link";
import {
  BUSINESS_CATEGORIES,
  kategoriUrlParcasi,
} from "@/lib/businessCategories";

/**
 * Kategori sayfası (#344).
 *
 * Ana sayfadaki şablon kataloğunun 19 kartı buraya bağlanıyor. Kategori
 * sayfaları olmasaydı katalog bölümü hiçbir yere gitmeyen, sayfanın en
 * büyük ama arama motoru açısından ölü parçası olurdu.
 *
 * Adres parçası tire kullanır (`/kesfet/kafe-lokanta`): Google alt çizgiyi
 * kelime birleştirici sayar, tireyi ayırıcı.
 *
 * NOT: Kategori sayfalarında "Tümü" butonu gösterilmez - tüm vitrinler
 * varsayılan olarak gösterilir.
 */
export function KategoriSeridi({ aktifKimlik }: { aktifKimlik?: string }) {
  return (
    <nav aria-label="Kategoriler" className="flex flex-wrap gap-2">
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
