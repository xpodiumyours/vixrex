export interface ProductItem {
  id?: string;
  slug?: string;
  name: string;
  description?: string;
  price?: string;
  imagePath?: string;
  category?: string;
  stockStatus?: string;
  source?: string;
  sourceMediaId?: string;
  sourcePermalink?: string;
  importedAt?: string;
}

export interface ProductCollection {
  name: string;
  count: number;
}

export function safeParseJson<T>(value: unknown): T[] {
  if (!value) return [];
  if (Array.isArray(value)) return value as T[];
  if (typeof value === "string") {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? (parsed as T[]) : [];
    } catch {
      return [];
    }
  }
  return [];
}

export function slugifyTR(value: string): string {
  const normalized = value
    .trim()
    .toLowerCase()
    .replaceAll("ç", "c")
    .replaceAll("ğ", "g")
    .replaceAll("ı", "i")
    .replaceAll("ö", "o")
    .replaceAll("ş", "s")
    .replaceAll("ü", "u")
    .replaceAll("â", "a")
    .replaceAll("î", "i")
    .replaceAll("û", "u");

  return normalized
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
}

export function getProductUrlSlug(product: ProductItem, index = 0): string {
  const explicitSlug = slugifyTR(product.slug || "");
  if (explicitSlug) return explicitSlug;

  const nameSlug = slugifyTR(product.name || "urun") || "urun";
  const idSlug = slugifyTR(product.id || "");
  return idSlug ? `${nameSlug}-${idSlug}` : `${nameSlug}-${index + 1}`;
}

export function findProductBySlug(products: ProductItem[], productSlug: string) {
  const requestedSlug = slugifyTR(productSlug);

  return products.find((product, index) => {
    return getProductUrlSlug(product, index) === requestedSlug;
  });
}

export function deriveCollections(products: ProductItem[], limit = 8): ProductCollection[] {
  const counts = new Map<string, number>();

  for (const product of products) {
    const category = String(product.category || "").trim();
    if (!category || category.toLowerCase() === "tümü") continue;
    counts.set(category, (counts.get(category) || 0) + 1);
  }

  return Array.from(counts.entries())
    .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0], "tr"))
    .slice(0, limit)
    .map(([name, count]) => ({ name, count }));
}

export function normalizeWhatsappDigits(value: unknown): string {
  const digits = String(value || "").replace(/[^0-9]/g, "");
  if (digits.startsWith("0") && digits.length === 11) return `90${digits.slice(1)}`;
  if (digits.startsWith("5") && digits.length === 10) return `90${digits}`;
  return digits;
}

export function normalizeExternalUrl(value: unknown): string | null {
  const url = String(value || "").trim();
  if (!url) return null;
  return url.startsWith("http") ? url : `https://${url}`;
}

export function cleanInstagramCaption(caption: string): string {
  return caption
    .replace(/#[\p{L}\p{N}_-]+/gu, "")
    .replace(/\s+/g, " ")
    .trim();
}

export function buildInstagramProductName(caption: string, fallback = "Instagram ürünü") {
  const firstLine = caption
    .split(/\r?\n/)
    .map((line) => cleanInstagramCaption(line))
    .find(Boolean);

  if (!firstLine) return fallback;
  return firstLine.length > 72 ? `${firstLine.slice(0, 69).trim()}...` : firstLine;
}

export function buildInstagramProductDescription(args: {
  caption: string;
  storeName: string;
  productName: string;
}) {
  const cleaned = cleanInstagramCaption(args.caption);
  if (cleaned.length >= 40) return cleaned;

  return `${args.storeName} vitrini için Instagram'dan aktarılan ${args.productName}. Ürün detayı, beden, renk ve stok bilgisi için WhatsApp üzerinden bilgi alabilirsiniz.`;
}

export function retainManualProducts(
  products: ProductItem[],
  importedSlugs: readonly string[] = [],
): ProductItem[] {
  const importedSlugSet = new Set(importedSlugs.filter(Boolean));

  return products.filter((product) => {
    if (product.source === "instagram") return false;
    if (!product.slug) return true;
    return !importedSlugSet.has(product.slug);
  });
}
