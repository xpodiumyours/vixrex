import Link from "next/link";
import { AKTIF_BUSINESS_CATEGORIES, kategoriUrlParcasi } from "@/lib/businessCategories";
import { kategoriSablonHaritasi } from "@/lib/categoryTemplates";
import { TiltCard } from "./TiltCard";

/**
 * Şablon kataloğu — envanter §2.9.
 *
 * Flutter'daki karşılığı bir alt sayfa (bottom sheet) açıyor; burada her
 * kart GERÇEK bir sayfaya (`/kesfet/{kategori}`) bağlanıyor. Sebep basit:
 * bir modalın içeriğini arama motoru göremez, #344'ün tamamı da zaten
 * taranabilir yüzey üretmekle ilgili.
 *
 * KATEGORİ SAYISI: Flutter ve web aynı kaynaktan besleniyor —
 * shared/business_categories.json. Kartlar `aktif` işaretli 6 kategoriyi
 * çizer, başlık da sayıyı elle yazmak yerine o listeden okur; ikisi de
 * landing-katalog-parite testiyle kilitli. JSON'daki toplam 19 kanonik
 * kimlik, ürün şablonu çözümünün kaynağı olarak duruyor.
 * Ölçüm (2026-08-26): 19 kategorinin hepsinde en az 3 kapak görseli var.
 */
export async function TemplateCatalog() {
  const sablonlar = await kategoriSablonHaritasi();
  const kategoriSayisi = AKTIF_BUSINESS_CATEGORIES.length;

  return (
    <section className="border-t border-white/5 lp-yan-bosluk py-lp-section">
      <div className="mx-auto w-full max-w-lp">
        <p className="text-center text-[12px] font-black tracking-[1.5px] text-sky-400">
          HAZIR ŞABLONLAR
        </p>
        <h2 className="mt-3 text-center text-[32px] font-black leading-[1.15] text-lp-text md:text-[38px]">
          İşletme Kategorine Özel Hazır Görseller
        </h2>
        <p className="mx-auto mt-4 max-w-lp-dar text-center text-[16px] leading-[1.5] text-lp-text-alt">
          {kategoriSayisi} farklı kategoride profesyonel, telifsiz görsellerle
          vitrinini saniyeler içinde oluştur.
        </p>

        <ul className="mt-10 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {AKTIF_BUSINESS_CATEGORIES.map((kategori) => {
            const sablon = sablonlar.get(kategori.id);
            const kapak = sablon?.kapaklar[0]?.url ?? null;
            return (
              <li key={kategori.id}>
                <TiltCard className="lp-glass-panel h-full rounded-[26px]">
                  <Link
                    href={`/kesfet/${kategoriUrlParcasi(kategori.id)}`}
                    className="group flex h-full flex-col overflow-hidden rounded-[26px]"
                  >
                    <span className="relative block aspect-[16/10] w-full overflow-hidden bg-slate-900">
                      {kapak ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={kapak}
                          alt=""
                          className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                          loading="lazy"
                        />
                      ) : (
                        <span className="block h-full w-full bg-gradient-to-br from-[#102B59] to-[#08132D]" />
                      )}
                      <span
                        aria-hidden="true"
                        className="pointer-events-none absolute inset-x-0 bottom-0 h-14 bg-gradient-to-t from-[#081226]/90 to-transparent"
                      />
                    </span>
                    <span className="flex flex-1 items-center justify-between gap-3 bg-[#081226]/90 px-5 py-4">
                      <span>
                        <span className="block text-[16px] font-black leading-tight text-white">
                          {kategori.label}
                        </span>
                        <span className="mt-0.5 block text-[12px] font-bold text-sky-400">
                          Hazır görseller →
                        </span>
                      </span>
                      <span
                        aria-hidden="true"
                        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-white/[0.06] text-sm font-black text-sky-300 transition-all duration-300 group-hover:translate-x-0.5 group-hover:bg-[#147DFF] group-hover:text-white"
                      >
                        →
                      </span>
                    </span>
                  </Link>
                </TiltCard>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}
