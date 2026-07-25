/**
 * Public vitrin kategori profili — Flutter BusinessCategoryConfig ile hizalı.
 * Tek shell + aile varyantı (ayrı sayfa yok).
 */

export type VitrinFamily = "product" | "service" | "venue";

export type PrimaryActionId = "whatsapp" | "maps" | "booking" | "website";

export interface VitrinCategoryProfile {
  id: string;
  label: string;
  family: VitrinFamily;
  sectionTitle: string;
  ctaLabel: string;
  /** Birincil CTA sırası (max 3 gösterilir; URL yoksa atlanır) */
  primaryActions: PrimaryActionId[];
}

const PROFILES: VitrinCategoryProfile[] = [
  { id: "giyim", label: "Giyim", family: "product", sectionTitle: "Yeni Sezon", ctaLabel: "Ürün Sor", primaryActions: ["whatsapp", "maps", "website"] },
  { id: "butik", label: "Butik", family: "product", sectionTitle: "Özel Tasarımlar", ctaLabel: "Ürün Sor", primaryActions: ["whatsapp", "maps", "website"] },
  { id: "gida", label: "Gıda", family: "product", sectionTitle: "Taze Ürünler", ctaLabel: "Sipariş Talebi", primaryActions: ["whatsapp", "maps", "website"] },
  { id: "firin", label: "Fırın", family: "product", sectionTitle: "Bugün Neler Var?", ctaLabel: "Sipariş Talebi", primaryActions: ["whatsapp", "maps", "website"] },
  { id: "kozmetik", label: "Kozmetik", family: "product", sectionTitle: "Ürünler ve Bakım", ctaLabel: "Bilgi Al", primaryActions: ["whatsapp", "booking", "maps"] },
  { id: "dekorasyon", label: "Dekorasyon", family: "product", sectionTitle: "Koleksiyon", ctaLabel: "Teklif İste", primaryActions: ["whatsapp", "maps", "website"] },
  { id: "elektronik", label: "Elektronik", family: "product", sectionTitle: "Ürünler", ctaLabel: "Ürün Sor", primaryActions: ["whatsapp", "maps", "website"] },
  { id: "kirtasiye", label: "Kırtasiye", family: "product", sectionTitle: "Ürünler", ctaLabel: "Ürün Sor", primaryActions: ["whatsapp", "maps", "website"] },
  { id: "pet_shop_veteriner", label: "Pet / Veteriner", family: "service", sectionTitle: "Hizmetler", ctaLabel: "Bilgi Al", primaryActions: ["whatsapp", "booking", "maps"] },
  { id: "kafe_lokanta", label: "Kafe / Lokanta", family: "venue", sectionTitle: "Menü", ctaLabel: "Sipariş / Rezervasyon", primaryActions: ["whatsapp", "maps", "website"] },
  { id: "kuafor", label: "Kuaför", family: "service", sectionTitle: "Hizmetler", ctaLabel: "Randevu Sor", primaryActions: ["whatsapp", "booking", "maps"] },
  { id: "teknik_servis", label: "Teknik Servis", family: "service", sectionTitle: "Hizmetler", ctaLabel: "Servis Talebi", primaryActions: ["whatsapp", "booking", "maps"] },
  { id: "hizmet_danismanlik", label: "Danışmanlık", family: "service", sectionTitle: "Hizmetler", ctaLabel: "Bilgi Al", primaryActions: ["whatsapp", "booking", "maps"] },
  { id: "egitim_ders", label: "Eğitim", family: "service", sectionTitle: "Programlar", ctaLabel: "Bilgi Al", primaryActions: ["whatsapp", "booking", "maps"] },
  { id: "ev_temizlik", label: "Ev Temizlik", family: "service", sectionTitle: "Hizmetler", ctaLabel: "Teklif İste", primaryActions: ["whatsapp", "booking", "maps"] },
  { id: "spor_fitness", label: "Spor / Fitness", family: "service", sectionTitle: "Programlar", ctaLabel: "Bilgi Al", primaryActions: ["whatsapp", "booking", "maps"] },
  { id: "saglik_yasam", label: "Sağlık / Yaşam", family: "service", sectionTitle: "Hizmetler", ctaLabel: "Bilgi Al", primaryActions: ["whatsapp", "booking", "maps"] },
  { id: "oto_arac", label: "Oto / Araç", family: "service", sectionTitle: "Hizmetler", ctaLabel: "Randevu Sor", primaryActions: ["whatsapp", "booking", "maps"] },
  { id: "diger", label: "Diğer", family: "product", sectionTitle: "Öne Çıkanlar", ctaLabel: "Bilgi Al", primaryActions: ["whatsapp", "maps", "website"] },
];

const BY_ID = new Map(PROFILES.map((p) => [p.id, p]));

function normalizeTr(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/ı/g, "i")
    .replace(/İ/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ü/g, "u")
    .replace(/ş/g, "s")
    .replace(/ö/g, "o")
    .replace(/ç/g, "c");
}

const KEYWORDS: Array<[string, string]> = [
  ["kafe", "kafe_lokanta"],
  ["restoran", "kafe_lokanta"],
  ["lokanta", "kafe_lokanta"],
  ["kuafor", "kuafor"],
  ["guzellik", "kuafor"],
  ["giyim", "giyim"],
  ["butik", "butik"],
  ["gida", "gida"],
  ["firin", "firin"],
  ["veteriner", "pet_shop_veteriner"],
  ["pet", "pet_shop_veteriner"],
  ["egitim", "egitim_ders"],
  ["ders", "egitim_ders"],
  ["temizlik", "ev_temizlik"],
  ["spor", "spor_fitness"],
  ["fitness", "spor_fitness"],
  ["saglik", "saglik_yasam"],
  ["oto", "oto_arac"],
  ["arac", "oto_arac"],
  ["teknik", "teknik_servis"],
  ["danismanlik", "hizmet_danismanlik"],
  ["kozmetik", "kozmetik"],
  ["dekorasyon", "dekorasyon"],
  ["elektronik", "elektronik"],
  ["kirtasiye", "kirtasiye"],
];

function resolveFromLabel(raw: string): VitrinCategoryProfile | null {
  const value = raw.trim();
  if (!value) return null;

  const lower = value.toLowerCase();
  for (const p of PROFILES) {
    if (p.label.toLowerCase() === lower || p.id === lower) return p;
  }

  const normalized = normalizeTr(value);
  for (const p of PROFILES) {
    if (normalizeTr(p.label) === normalized || normalizeTr(p.id) === normalized) {
      return p;
    }
  }

  for (const [key, id] of KEYWORDS) {
    if (normalized.includes(key)) {
      return BY_ID.get(id) ?? null;
    }
  }

  return null;
}

/**
 * Kategori öncelikli. `Diğer` / boş ise business_type ile yeniden dene
 * (ör. kategori=Diğer, business_type=Butik → butik profili).
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
