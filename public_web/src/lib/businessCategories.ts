import categoryContract from "../../../shared/business_categories.json";

export interface BusinessCategoryCore {
  id: string;
  order: number;
  label: string;
  templateGroup: BusinessTemplateGroup;
  aliases: string[];
}

export type BusinessTemplateGroup = "perakende" | "hizmet" | "gida" | "diger";

export function normalizeBusinessCategoryTerm(value: string): string {
  return value
    .trim()
    .toLocaleLowerCase("tr-TR")
    .replace(/ı/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ü/g, "u")
    .replace(/ş/g, "s")
    .replace(/ö/g, "o")
    .replace(/ç/g, "c");
}

export function validateBusinessCategoryContract(
  categories: readonly BusinessCategoryCore[],
): void {
  const templateGroups = new Set<BusinessTemplateGroup>([
    "perakende",
    "hizmet",
    "gida",
    "diger",
  ]);
  const ids = new Set<string>();
  const terms = new Map<string, string>();
  categories.forEach((category, index) => {
    if (
      !category.id ||
      ids.has(category.id) ||
      category.order !== index + 1 ||
      !templateGroups.has(category.templateGroup)
    ) {
      throw new Error(`Kategori ID/sıra sözleşmesi geçersiz: ${category.id}`);
    }
    ids.add(category.id);
    for (const term of [category.id, category.label, ...category.aliases]) {
      const normalized = normalizeBusinessCategoryTerm(term);
      const owner = terms.get(normalized);
      if (owner && owner !== category.id) {
        throw new Error(`Kategori alias çakışması: ${term} (${owner}/${category.id})`);
      }
      terms.set(normalized, category.id);
    }
  });
}

export const BUSINESS_CATEGORIES =
  categoryContract.categories as BusinessCategoryCore[];
validateBusinessCategoryContract(BUSINESS_CATEGORIES);

const BY_ID = new Map(BUSINESS_CATEGORIES.map((category) => [category.id, category]));
const TERMS = new Map<string, string>();
for (const category of BUSINESS_CATEGORIES) {
  for (const term of [category.id, category.label, ...category.aliases]) {
    TERMS.set(normalizeBusinessCategoryTerm(term), category.id);
  }
}

export function resolveBusinessCategory(raw: string): BusinessCategoryCore | null {
  const normalized = normalizeBusinessCategoryTerm(raw);
  if (!normalized) return null;
  const exact = TERMS.get(normalized);
  if (exact) return BY_ID.get(exact) ?? null;
  const partialTerms = [...TERMS]
    .filter(([term]) => normalized.includes(term))
    .sort(([left], [right]) => {
      const position = normalized.indexOf(left) - normalized.indexOf(right);
      return position || right.length - left.length;
    });
  for (const [, id] of partialTerms) {
    return BY_ID.get(id) ?? null;
  }
  return null;
}

/**
 * Kategori kimliği → URL parçası. Kanonik kimlikler alt çizgi taşıyor
 * (`kafe_lokanta`, `pet_shop_veteriner`); Google alt çizgiyi kelime
 * BİRLEŞTİRİCİ sayar, tireyi ayırıcı. `/kesfet/kafe-lokanta` bu yüzden
 * `/kesfet/kafe_lokanta`'dan daha iyi okunur.
 *
 * Kimliğin kendisi hiç değişmez — dönüşüm yalnız adres katmanındadır.
 * (Sonradan değiştirmek 19 kalıcı yönlendirme demek olurdu.)
 */
export function kategoriUrlParcasi(id: string): string {
  return id.replace(/_/g, "-");
}

/** URL parçasından kanonik kategoriye. Bilinmeyen parça için `null`. */
export function kategoriUrlParcasindanCoz(
  parca: string,
): BusinessCategoryCore | null {
  const id = parca.trim().toLowerCase().replace(/-/g, "_");
  return BUSINESS_CATEGORIES.find((kategori) => kategori.id === id) ?? null;
}
