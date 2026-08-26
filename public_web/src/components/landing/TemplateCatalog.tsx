import Link from "next/link";
import { BUSINESS_CATEGORIES, kategoriUrlParcasi } from "@/lib/businessCategories";
import { kategoriSablonHaritasi } from "@/lib/categoryTemplates";

/**
 * Şablon kataloğu — envanter §2.9.
 *
 * Flutter'daki karşılığı bir alt sayfa (bottom sheet) açıyor; burada her
 * kart GERÇEK bir sayfaya (`/kesfet/{kategori}`) bağlanıyor. Sebep basit:
 * bir modalın içeriğini arama motoru göremez, #344'ün tamamı da zaten
 * taranabilir yüzey üretmekle ilgili.
 *
 * KATEGORİ SAYISI: Flutter 20 kart çiziyor ama başlığında "12 farklı
 * kategoride" yazıyor; veritabanı ise 19 kanonik kimlik tanıyor ve o 20
 * arayüz anahtarının 11'i hiçbir satırla eşleşmiyor. Burada tek doğru
 * kaynak kullanılıyor: shared/business_categories.json'daki 19 kimlik.
 * Ölçüm (2026-08-26): 19 kategorinin hepsinde en az 3 kapak görseli var.
 */
export async function TemplateCatalog() {
  const sablonlar = await kategoriSablonHaritasi();
  const kategoriSayisi = BUSINESS_CATEGORIES.length;

  return (
    <section className="bg-lp-bg-light px-6 py-16">
      <div className="mx-auto w-full max-w-[1200px]">
        <p className="text-center text-[12px] font-black tracking-[1.5px] text-lp-primary">
          HAZIR ŞABLONLAR
        </p>
        <h2 className="mt-3 text-center text-[32px] font-black leading-[1.15] text-lp-text md:text-[38px]">
          İşletme Kategorine Özel Hazır Görseller
        </h2>
        <p className="mx-auto mt-4 max-w-[720px] text-center text-[16px] leading-[1.5] text-lp-text-alt">
          {kategoriSayisi} farklı kategoride profesyonel, telifsiz görsellerle
          vitrinini saniyeler içinde oluştur.
        </p>

        <ul className="mt-10 grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-4">
          {BUSINESS_CATEGORIES.map((kategori) => {
            const sablon = sablonlar.get(kategori.id);
            const kapak = sablon?.kapaklar[0]?.url ?? null;
            return (
              <li key={kategori.id}>
                <Link
                  href={`/kesfet/${kategoriUrlParcasi(kategori.id)}`}
                  className="group flex h-full flex-col overflow-hidden rounded-3xl border border-lp-border/70 bg-lp-surface transition-colors hover:border-lp-primary/50"
                >
                  <span className="block aspect-[3/2] w-full overflow-hidden bg-lp-surface-soft">
                    {kapak ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={kapak}
                        alt=""
                        className="h-full w-full object-cover"
                        loading="lazy"
                      />
                    ) : null}
                  </span>
                  <span className="flex flex-1 flex-col justify-between gap-2 p-4">
                    <span className="text-[13px] font-black text-lp-text">
                      {kategori.label}
                    </span>
                    <span className="text-[11px] font-bold text-lp-primary">
                      Hazır görseller →
                    </span>
                  </span>
                </Link>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}
