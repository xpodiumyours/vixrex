import Image from "next/image";
import Link from "next/link";
import { kategoriUrlParcasi } from "@/lib/businessCategories";
import { kategoriSablonHaritasi } from "@/lib/categoryTemplates";
import { MaterialRoundIcon } from "./MaterialRoundIcon";

const KATEGORILER = [
  { key: "butik_giyim", dbKey: "giyim", label: "Butik & Giyim", icon: "checkroom", color: "#FF5A1F" },
  { key: "kuafor_guzellik", dbKey: "kuafor", label: "Kuaför & Güzellik", icon: "content_cut", color: "#DB2777" },
  { key: "kafe_restoran", dbKey: "kafe_lokanta", label: "Kafe & Restoran", icon: "restaurant_menu", color: "#EA580C" },
  { key: "berber", dbKey: "kuafor", label: "Berber", icon: "face", color: "#7C3AED" },
  { key: "oto_kuafor", dbKey: "oto_arac", label: "Oto Kuaför", icon: "local_car_wash", color: "#2563EB" },
  { key: "market_bakkal", dbKey: "gida", label: "Market & Bakkal", icon: "shopping_basket", color: "#059669" },
  { key: "pastane_tatlici", dbKey: "firin", label: "Pastane & Tatlıcı", icon: "bakery_dining", color: "#D946EF" },
  { key: "mobilya_dekorasyon", dbKey: "dekorasyon", label: "Mobilya & Dekorasyon", icon: "chair", color: "#CA8A04" },
  { key: "spor_salonu", dbKey: "spor_fitness", label: "Spor Salonu", icon: "fitness_center", color: "#DC2626" },
  { key: "dis_klinigi", dbKey: "saglik_yasam", label: "Diş Kliniği", icon: "medical_services", color: "#0891B2" },
  { key: "eczane", dbKey: "saglik_yasam", label: "Eczane", icon: "local_pharmacy", color: "#16A34A" },
  { key: "teknik_servis", dbKey: "teknik_servis", label: "Teknik Servis", icon: "build_circle", color: "#4F46E5" },
  { key: "butik", dbKey: "butik", label: "Butik", icon: "local_mall", color: "#8B5CF6" },
  { key: "kozmetik", dbKey: "kozmetik", label: "Kozmetik", icon: "face_retouching_natural", color: "#F472B6" },
  { key: "elektronik", dbKey: "elektronik", label: "Elektronik", icon: "devices", color: "#6366F1" },
  { key: "kirtasiye", dbKey: "kirtasiye", label: "Kırtasiye", icon: "menu_book", color: "#FBBF24" },
  { key: "pet_shop_veteriner", dbKey: "pet_shop_veteriner", label: "Pet Shop & Veteriner", icon: "pets", color: "#14B8A2" },
  { key: "hizmet_danismanlik", dbKey: "hizmet_danismanlik", label: "Hizmet & Danışmanlık", icon: "business_center", color: "#84CC16" },
  { key: "egitim_ders", dbKey: "egitim_ders", label: "Eğitim & Ders", icon: "school", color: "#38BDF8" },
  { key: "ev_temizlik", dbKey: "ev_temizlik", label: "Ev & Temizlik", icon: "clean_hands", color: "#4ADE80" },
] as const;

/**
 * Flutter `landing_template_catalog.dart` + `landing_template_card.dart`
 * görünüm karşılığı. Link hedefi Next.js'in taranabilir Keşfet sayfasını korur.
 */
export async function TemplateCatalog() {
  const sablonlar = await kategoriSablonHaritasi();

  return (
    <section className="bg-lp-bg-light py-16">
      <div className="mx-auto w-full max-w-[1200px] px-6">
        <div className="text-center">
          <p className="inline-block rounded-full bg-lp-primary/10 px-4 py-2 text-[12px] font-black tracking-[1.5px] text-lp-primary">
            HAZIR ŞABLONLAR
          </p>
          <h2 className="mt-5 text-[28px] font-black leading-[1.2] text-lp-text">
            İşletme Kategorine Özel Hazır Görseller
          </h2>
          <p className="mx-auto mt-3 px-5 text-[15px] font-semibold leading-[1.5] text-lp-muted">
            12 farklı kategoride profesyonel, telifsiz görsellerle vitrinini saniyeler içinde oluştur.
          </p>
        </div>

        <ul className="mt-10 grid grid-cols-2 gap-4 min-[649px]:grid-cols-3 min-[949px]:grid-cols-4">
          {KATEGORILER.map((kategori) => {
            const sablon = sablonlar.get(kategori.dbKey);
            const kapak = sablon?.kapaklar[0]?.url ?? null;
            return (
              <li key={kategori.key} className="aspect-[0.85] min-w-0">
                <Link
                  href={`/kesfet/${kategoriUrlParcasi(kategori.dbKey)}`}
                  className="flex h-full flex-col overflow-hidden rounded-[20px] border border-lp-border bg-lp-surface shadow-[0_4px_12px_rgba(0,0,0,0.04)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary"
                  aria-label={`${kategori.label} hazır görsellerini aç`}
                >
                  <span
                    className="relative min-h-0 flex-[3] overflow-hidden rounded-t-[20px]"
                    style={{ backgroundColor: `color-mix(in srgb, ${kategori.color} 8%, transparent)` }}
                  >
                    {kapak ? (
                      <Image src={kapak} alt="" fill sizes="(min-width: 949px) 276px, (min-width: 649px) 368px, 50vw" className="object-cover" />
                    ) : (
                      <span className="flex h-full w-full items-center justify-center" style={{ color: kategori.color }}>
                        <span className="opacity-40"><MaterialRoundIcon name={kategori.icon} size={48} /></span>
                      </span>
                    )}
                  </span>

                  <span className="flex min-h-0 flex-[2] flex-col items-start p-[14px]">
                    <span
                      className="flex h-[30px] w-[30px] items-center justify-center rounded-lg"
                      style={{ color: kategori.color, backgroundColor: `color-mix(in srgb, ${kategori.color} 12%, transparent)` }}
                    >
                      <MaterialRoundIcon name={kategori.icon} size={18} />
                    </span>
                    <span className="mt-2 block max-w-full truncate text-[13px] font-extrabold text-lp-text">
                      {kategori.label}
                    </span>
                    <span className="mt-1 text-[11px] font-bold text-lp-primary">Hazır görseller →</span>
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
