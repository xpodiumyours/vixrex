import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import {
  MAX_PRODUCT_IMAGES,
  MIN_PRODUCT_IMAGES,
  normalizeProductImageUrls,
  validateExternalProductImageUrls,
  validateProductImageUrls,
} from "@/lib/productImagePolicy";
import {
  normalizeProductMetadata,
  normalizeProductVariants,
  type ProductMetadata,
  type ProductVariant,
} from "@/lib/productRichData";
import {
  PRODUCT_ATTRIBUTE_SCHEMA,
  productAttributesForTemplate,
  productTemplateByKey,
} from "@/lib/productAttributeSchema";
import { parseProductPriceNumber } from "@/lib/productPrice";
import { eksikZorunluAlanlar, eksikZorunluAlanMesaji } from "@/lib/productRequiredFields";

type YonetimIstemcisi = ReturnType<typeof getSupabaseAdmin>;

export function cleanString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed || null;
}

export function cleanNonNegativeInt(value: unknown): number | null {
  return typeof value === "number" && Number.isInteger(value) && value >= 0 ? value : null;
}

export function cleanAmount(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) && value >= 0 ? value : null;
}

function variantSignature(variant: ProductVariant): string {
  return Object.entries(variant.options)
    .sort(([left], [right]) => left.localeCompare(right, "tr"))
    .map(([key, value]) => `${key.toLocaleLowerCase("tr-TR")}=${value.trim().toLocaleLowerCase("tr-TR")}`)
    .join("|");
}

export function validateVariantSet(
  variants: ProductVariant[],
  parentBarcode: string | null,
): string | null {
  const ids = new Set<string>();
  const combinations = new Set<string>();
  const skus = new Set<string>();
  const barcodes = new Set<string>();
  if (parentBarcode) barcodes.add(parentBarcode);

  for (const variant of variants) {
    if (ids.has(variant.id)) return "Aynı varyant kimliği birden fazla kez kullanılamaz.";
    ids.add(variant.id);

    const signature = variantSignature(variant);
    if (combinations.has(signature)) {
      return "Aynı ürün seçeneği kombinasyonu birden fazla kez eklenemez.";
    }
    combinations.add(signature);

    const sku = cleanString(variant.sku)?.toLocaleLowerCase("tr-TR") || null;
    if (sku) {
      if (skus.has(sku)) return "Aynı varyant SKU değeri birden fazla kez kullanılamaz.";
      skus.add(sku);
    }

    const barcode = cleanString(variant.barcode);
    if (barcode) {
      if (barcodes.has(barcode)) return "Ürün ve varyant barkodları benzersiz olmalıdır.";
      barcodes.add(barcode);
    }
  }

  return null;
}

export async function categoryTemplateKey(
  admin: YonetimIstemcisi,
  storeId: string,
  categoryId: string,
) {
  if (!categoryId) return "generic";
  const rich = await admin
    .from("product_categories")
    .select("id,product_template_key")
    .eq("id", categoryId)
    .eq("store_id", storeId)
    .maybeSingle();
  if (rich.error || !rich.data) return null;
  const key = cleanString(rich.data.product_template_key) || "generic";
  return productTemplateByKey(key) ? key : null;
}

/**
 * Marka zorunlu ama esnafin markasi olmayabilir (butik, ev yapimi uretim).
 * Profesyonel platformlarin yaptigi gibi bos birakilirsa magaza adi yazilir.
 */
export function markaVeyaMagazaAdi(
  ham: unknown,
  templateKey: string,
  storeName: unknown,
): string | null {
  const girilen = cleanString(ham);
  if (girilen) return girilen;
  const otomatik = productAttributesForTemplate(templateKey).some(
    (attribute) => attribute.key === "brand" && attribute.autoFill === "storeName",
  );
  return otomatik ? cleanString(storeName) : null;
}

export function metadataForTemplate(value: unknown, templateKey: string): ProductMetadata | null {
  const template = productTemplateByKey(templateKey);
  if (!template) return null;
  const normalized = normalizeProductMetadata(value);

  if (template.itemKind === "service") {
    return {
      ...normalized,
      schemaVersion: PRODUCT_ATTRIBUTE_SCHEMA.version,
      itemKind: "service",
      templateKey,
      service: normalized.service,
      attributes: normalized.attributes || [],
    };
  }

  return {
    ...normalized,
    schemaVersion: PRODUCT_ATTRIBUTE_SCHEMA.version,
    itemKind: "physical",
    templateKey,
    attributes: normalized.attributes || [],
  };
}

export function variantsForTemplate(
  value: unknown,
  templateKey: string,
  productImageUrls: string[],
): ProductVariant[] {
  const template = productTemplateByKey(templateKey);
  if (!template) return [];

  const availableImages = new Set(productImageUrls);
  const variants = normalizeProductVariants(value).map((variant) => ({
    ...variant,
    imageUrls: variant.imageUrls?.filter((url) => availableImages.has(url)),
  }));
  const allowedKeys = new Set(
    productAttributesForTemplate(templateKey)
      .filter((definition) => definition.variantEligible)
      .map((definition) => definition.key),
  );

  if (allowedKeys.size === 0) return variants;

  return variants
    .map((variant) => ({
      ...variant,
      options: Object.fromEntries(
        Object.entries(variant.options).filter(
          ([key, optionValue]) => allowedKeys.has(key) && optionValue.trim().length > 0,
        ),
      ),
    }))
    .filter((variant) => Object.keys(variant.options).length > 0);
}

export interface HazirUrunGirdisi {
  name: string;
  description: string;
  priceText: string;
  priceAmount: number | null;
  imageUrls: string[];
  categoryId: string;
  brand: string | null;
  barcode: string | null;
  stockQuantity: number | null;
  stockStatus: string | null;
  metadata: ProductMetadata;
  variants: ProductVariant[];
}

export type UrunGirdiSonucu =
  | { durum: "hazir"; girdi: HazirUrunGirdisi }
  | { durum: "taslak"; girdi: HazirUrunGirdisi; eksik: string }
  | { durum: "reddedildi"; sebep: string };

export async function urunGirdisiniHazirla(args: {
  admin: YonetimIstemcisi;
  storeId: string;
  storeName: unknown;
  govde: Record<string, unknown>;
  gorselPolitikasi?: "sahip" | "toplu";
}): Promise<UrunGirdiSonucu> {
  const { admin, storeId, storeName, govde } = args;

  const name = cleanString(govde.name) || "";
  if (!name) return { durum: "reddedildi", sebep: "Ürün adı zorunludur." };

  const toplu = args.gorselPolitikasi === "toplu";
  const imageValidation = toplu
    ? validateExternalProductImageUrls(govde.imageUrls)
    : validateProductImageUrls(govde.imageUrls);

  let gorselEksigi: string | null = null;
  let imageUrls = imageValidation.imageUrls;

  if (!imageValidation.ok) {
    const sayi = normalizeProductImageUrls(govde.imageUrls).length;
    const yalnizcaAzFotograf = toplu && sayi < MIN_PRODUCT_IMAGES && sayi <= MAX_PRODUCT_IMAGES;
    if (!yalnizcaAzFotograf) {
      return { durum: "reddedildi", sebep: imageValidation.error ?? "Ürün fotoğrafları geçersiz." };
    }
    gorselEksigi = `Ürün için en az ${MIN_PRODUCT_IMAGES} fotoğraf gerekiyor; şu an ${sayi} tane var.`;
    imageUrls = normalizeProductImageUrls(govde.imageUrls);
  }

  const categoryId = cleanString(govde.categoryId) || "";
  const templateKey = await categoryTemplateKey(admin, storeId, categoryId);
  if (!templateKey) {
    return { durum: "reddedildi", sebep: "Kategori bu vitrine ait değil veya ürün tipi geçersiz." };
  }
  const template = productTemplateByKey(templateKey);
  if (!template) return { durum: "reddedildi", sebep: "Ürün tipi geçersiz." };

  const isService = template.itemKind === "service";
  const metadata = metadataForTemplate(govde.metadata, templateKey);
  if (!metadata) {
    return { durum: "reddedildi", sebep: "Ürün detayları kategori tipiyle uyuşmuyor." };
  }

  const variants = variantsForTemplate(govde.variants, templateKey, imageUrls);
  const barcode = isService ? null : cleanString(govde.barcode);
  const brand = isService ? null : markaVeyaMagazaAdi(govde.brand, templateKey, storeName);

  const variantError = validateVariantSet(variants, barcode);
  if (variantError) return { durum: "reddedildi", sebep: variantError };

  const priceText = typeof govde.priceText === "string" ? govde.priceText.trim() : "";
  const girdi: HazirUrunGirdisi = {
    name,
    description: typeof govde.description === "string" ? govde.description.trim() : "",
    priceText,
    priceAmount: cleanAmount(govde.priceAmount) ?? parseProductPriceNumber(priceText),
    imageUrls,
    categoryId,
    brand,
    barcode,
    stockQuantity: isService ? null : cleanNonNegativeInt(govde.stockQuantity),
    stockStatus: isService ? null : cleanString(govde.stockStatus) || "Mevcut",
    metadata,
    variants,
  };

  const eksikMesaji = eksikZorunluAlanMesaji(
    eksikZorunluAlanlar({ templateKey, brand, metadata, variants }),
  );
  const eksikler = [eksikMesaji, gorselEksigi].filter(Boolean) as string[];
  if (eksikler.length > 0) return { durum: "taslak", girdi, eksik: eksikler.join(" ") };

  return { durum: "hazir", girdi };
}
