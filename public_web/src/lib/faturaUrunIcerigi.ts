import { normalizeProductMetadata, type ProductMetadata } from "@/lib/productRichData";

export interface FaturaKatalogIcerigi {
  uretici?: unknown;
  gramaj?: unknown;
  beden?: unknown;
  varyant?: unknown;
  kategori?: unknown;
  ozellikler?: unknown;
  kaynak?: unknown;
  dogrulamaDurumu?: unknown;
}

/** Yalnız alan taşıma ve sunum: araştırma, ürün doğrulama veya özellik üretme yoktur. */
export function faturaKatalogMetadatasi(katalog: FaturaKatalogIcerigi): ProductMetadata {
  const attributes = normalizeProductMetadata({
    lunaInvoice: true,
    attributes: katalog.ozellikler,
  }).attributes ?? [];

  function ekle(key: string, label: string, raw: unknown): void {
    if (typeof raw !== "string" || !raw.trim()) return;
    const value = raw.trim();
    const existing = attributes.find((attribute) => attribute.key === key);
    if (existing && String(existing.value).trim() === value) return;
    // İki aktarılan alan farklıysa birini silme veya doğru olanı seçme.
    let outputKey = key;
    while (attributes.some((attribute) => attribute.key === outputKey)) {
      outputKey += "_reported";
    }
    attributes.push({ key: outputKey, label: existing ? `${label} (aktarılan)` : label, value });
  }

  ekle("manufacturer", "Üretici", katalog.uretici);
  ekle("netQuantity", "Gramaj / hacim", katalog.gramaj);
  ekle("size", "Beden", katalog.beden);
  ekle("variant", "Varyant", katalog.varyant);
  ekle("category", "Kategori", katalog.kategori);

  return normalizeProductMetadata({
    lunaInvoice: true,
    attributes,
    manufacturerSource: {
      url: katalog.kaynak,
      verificationStatus: katalog.dogrulamaDurumu,
    },
  });
}
