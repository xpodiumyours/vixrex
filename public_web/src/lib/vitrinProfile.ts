/**
 * Public vitrin kategori profili. Kimlik ve etiket ortak core'dan, sunum
 * kararları bu Next.js adapter'ından gelir.
 */

import {
  BUSINESS_CATEGORIES,
  resolveBusinessCategory,
} from "./businessCategories";

export type VitrinFamily = "product" | "service" | "venue";
export type PrimaryActionId = "whatsapp" | "maps" | "booking" | "website";

export interface VitrinCategoryProfile {
  id: string;
  label: string;
  family: VitrinFamily;
  sectionTitle: string;
  ctaLabel: string;
  primaryActions: PrimaryActionId[];
  waMesaji?: string;
}

type CategoryPresentation = Omit<VitrinCategoryProfile, "id" | "label">;

const productActions: PrimaryActionId[] = ["whatsapp", "maps", "website"];
const serviceActions: PrimaryActionId[] = ["whatsapp", "booking", "maps"];

const PRESENTATION: Record<string, CategoryPresentation> = {
  giyim: { family: "product", sectionTitle: "Yeni Sezon", ctaLabel: "Ürün Sor", primaryActions: productActions },
  butik: { family: "product", sectionTitle: "Özel Tasarımlar", ctaLabel: "Ürün Sor", primaryActions: productActions },
  gida: { family: "product", sectionTitle: "Taze Ürünler", ctaLabel: "Sipariş Talebi", primaryActions: productActions },
  firin: { family: "product", sectionTitle: "Bugün Neler Var?", ctaLabel: "Sipariş Talebi", primaryActions: productActions },
  kozmetik: { family: "product", sectionTitle: "Ürünler ve bakım", ctaLabel: "Bilgi Al", primaryActions: serviceActions, waMesaji: "Merhaba, ürünleriniz hakkında bilgi almak istiyorum." },
  dekorasyon: { family: "product", sectionTitle: "Koleksiyon", ctaLabel: "Teklif İste", primaryActions: productActions },
  elektronik: { family: "product", sectionTitle: "Ürünler", ctaLabel: "Ürün Sor", primaryActions: productActions },
  kirtasiye: { family: "product", sectionTitle: "Ürünler", ctaLabel: "Ürün Sor", primaryActions: productActions },
  kafe_lokanta: { family: "venue", sectionTitle: "Menü", ctaLabel: "Sipariş / Rezervasyon", primaryActions: productActions },
  kuafor: { family: "service", sectionTitle: "Hizmetler", ctaLabel: "Randevu Sor", primaryActions: serviceActions, waMesaji: "Merhaba, randevu almak istiyorum." },
  teknik_servis: { family: "service", sectionTitle: "Hizmetler", ctaLabel: "Servis Talebi", primaryActions: serviceActions, waMesaji: "Merhaba, cihazım için servis talebinde bulunmak istiyorum." },
  hizmet_danismanlik: { family: "service", sectionTitle: "Hizmetler", ctaLabel: "Bilgi Al", primaryActions: serviceActions, waMesaji: "Merhaba, hizmetleriniz hakkında bilgi almak istiyorum." },
  egitim_ders: { family: "service", sectionTitle: "Programlar", ctaLabel: "Bilgi Al", primaryActions: serviceActions, waMesaji: "Merhaba, dersleriniz hakkında bilgi almak istiyorum." },
  ev_temizlik: { family: "service", sectionTitle: "Hizmetler", ctaLabel: "Teklif İste", primaryActions: serviceActions, waMesaji: "Merhaba, temizlik hizmeti için teklif almak istiyorum." },
  spor_fitness: { family: "service", sectionTitle: "Programlar", ctaLabel: "Bilgi Al", primaryActions: serviceActions, waMesaji: "Merhaba, üyelik ve fiyat bilgisi almak istiyorum." },
  pet_shop_veteriner: { family: "service", sectionTitle: "Hizmetler", ctaLabel: "Bilgi Al", primaryActions: serviceActions, waMesaji: "Merhaba, randevu ve fiyat bilgisi almak istiyorum." },
  saglik_yasam: { family: "service", sectionTitle: "Hizmetler", ctaLabel: "Bilgi Al", primaryActions: serviceActions, waMesaji: "Merhaba, randevu ve bilgi almak istiyorum." },
  oto_arac: { family: "service", sectionTitle: "Hizmetler", ctaLabel: "Randevu Sor", primaryActions: serviceActions, waMesaji: "Merhaba, aracım için randevu almak istiyorum." },
  diger: { family: "product", sectionTitle: "Öne çıkanlar", ctaLabel: "Bilgi Al", primaryActions: productActions },
};

export const PROFILES: VitrinCategoryProfile[] = BUSINESS_CATEGORIES.map(
  (category) => ({
    id: category.id,
    label: category.label,
    ...PRESENTATION[category.id],
  }),
);

const BY_ID = new Map(PROFILES.map((profile) => [profile.id, profile]));

function resolveFromLabel(raw: string): VitrinCategoryProfile | null {
  const category = resolveBusinessCategory(raw);
  return category ? (BY_ID.get(category.id) ?? null) : null;
}

/**
 * Kategori öncelikli. `Diğer` / boş ise business_type ile yeniden dene.
 */
export function resolveVitrinProfile(
  kategori: string | null | undefined,
  businessType?: string | null,
): VitrinCategoryProfile {
  const fromKategori = resolveFromLabel(kategori || "");
  if (fromKategori && fromKategori.id !== "diger") return fromKategori;

  const fromType = resolveFromLabel(businessType || "");
  if (fromType && fromType.id !== "diger") return fromType;

  return fromKategori ?? BY_ID.get("diger")!;
}
