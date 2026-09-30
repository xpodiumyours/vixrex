import policyJson from "../../../shared/product_image_policy.json";

export const MIN_PRODUCT_IMAGES = policyJson.minImages;
export const MAX_PRODUCT_IMAGES = policyJson.maxImages;
/** Faturaya özel min 1; diğer girişler 3 kalır (MIN_PRODUCT_IMAGES). */
export const MIN_FATURA_IMAGES = 1;
export const MAX_PRODUCT_IMAGE_SOURCE_MEGABYTES = policyJson.maxSourceMegabytes;
export const MAX_PRODUCT_IMAGE_SOURCE_BYTES = MAX_PRODUCT_IMAGE_SOURCE_MEGABYTES * 1024 * 1024;
export const MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE = policyJson.minSourceShortEdge;

export interface ProductImageValidationResult {
  ok: boolean;
  imageUrls: string[];
  error?: string;
}

export interface ProductImageDimensionValidationResult {
  ok: boolean;
  error?: string;
}

export function normalizeProductImageUrls(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return Array.from(
    new Set(
      value
        .filter((item): item is string => typeof item === "string")
        .map((item) => item.trim())
        .filter(Boolean),
    ),
  );
}

export function validateProductImageDimensions(
  width: number,
  height: number,
): ProductImageDimensionValidationResult {
  if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0) {
    return { ok: false, error: "Ürün fotoğrafının ölçüleri okunamadı." };
  }
  if (Math.min(width, height) < MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE) {
    return {
      ok: false,
      error: `Ürün fotoğrafının kısa kenarı en az ${MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE} px olmalıdır.`,
    };
  }
  return { ok: true };
}

function validateCountAndUrls(
  value: unknown,
  options: { httpsOnly: boolean; ignoreMinCount?: boolean; faturaKaynakli?: boolean },
): ProductImageValidationResult {
  // Fatura dalı min 1, diğer girişler 3 kalır. ignoreMinCount benzeri fatura
  // bayrağı; manuel validateProductImageUrls yolu bu bayrağı kullanmaz.
  const minGerekli = options.faturaKaynakli ? MIN_FATURA_IMAGES : MIN_PRODUCT_IMAGES;
  if (!Array.isArray(value)) {
    return {
      ok: false,
      imageUrls: [],
      error: `Bir ürün için en az ${minGerekli} fotoğraf zorunludur.`,
    };
  }

  const imageUrls = normalizeProductImageUrls(value);
  if (!options.ignoreMinCount && imageUrls.length < minGerekli) {
    return {
      ok: false,
      imageUrls,
      error: `Bir ürün için en az ${minGerekli} fotoğraf zorunludur.`,
    };
  }
  if (imageUrls.length > MAX_PRODUCT_IMAGES) {
    return {
      ok: false,
      imageUrls,
      error: `Bir ürüne en fazla ${MAX_PRODUCT_IMAGES} fotoğraf eklenebilir.`,
    };
  }
  const urlPattern = options.httpsOnly ? /^https:\/\//i : /^https?:\/\//i;
  if (imageUrls.some((url) => !urlPattern.test(url))) {
    return {
      ok: false,
      imageUrls,
      error: options.httpsOnly
        ? "Ürün fotoğrafı bağlantıları güvenli https:// bağlantısı olmalıdır."
        : "Ürün fotoğrafı bağlantıları http:// veya https:// ile başlamalıdır.",
    };
  }
  return { ok: true, imageUrls };
}

function managedProductImageUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    const configuredOrigin = String(process.env.NEXT_PUBLIC_SUPABASE_URL || "").trim();
    if (configuredOrigin) {
      const expected = new URL(configuredOrigin);
      if (parsed.origin !== expected.origin) return false;
    }
    const path = decodeURIComponent(parsed.pathname);
    return (
      path.includes("/storage/v1/object/public/shelf-images/") &&
      path.includes("/products/")
    );
  } catch {
    return false;
  }
}

/**
 * Owner'ın manuel ürün akışı: fotoğraflar Vixrex'in ürün yükleme kapısından
 * geçmiş olmalı. Böylece 5 MB, gerçek dosya türü ve 1200 px kalite denetimi
 * URL yapıştırılarak atlanamaz.
 */
export function validateProductImageUrls(value: unknown): ProductImageValidationResult {
  const base = validateCountAndUrls(value, { httpsOnly: true });
  if (!base.ok) return base;
  if (base.imageUrls.some((url) => !managedProductImageUrl(url))) {
    return {
      ok: false,
      imageUrls: base.imageUrls,
      error: "Ürün fotoğraflarını Görsel ekle alanından yükleyin; dış bağlantı kullanılamaz.",
    };
  }
  return base;
}

/**
 * XML/toplu entegrasyonları mevcut tedarikçi CDN görsellerini korur. Owner'ın
 * manuel kalite kapısı bu uyumluluk istisnasından etkilenmez.
 * Faturaya özel: min 1 fotoğraf (diğer girişler 3 kalır); manuel yol bozulmaz.
 */
export function validateExternalProductImageUrls(
  value: unknown,
  options?: { faturaKaynakli?: boolean },
): ProductImageValidationResult {
  // Fatura dalı min 1; fatura dışı dış girişler faturaKaynakli:false ile 3
  // kalır. Varsayılan fatura (true) çünkü bu doğrulayıcı fatura/toplu dış
  // görseller içindir; manuel validateProductImageUrls yolu değişmez.
  return validateCountAndUrls(value, {
    httpsOnly: false,
    faturaKaynakli: options?.faturaKaynakli ?? false,
  });
}

export function validateProductImageUrlsAllowingFewerImages(
  value: unknown,
): ProductImageValidationResult {
  const base = validateCountAndUrls(value, { httpsOnly: true, ignoreMinCount: true });
  if (!base.ok) return base;
  if (base.imageUrls.some((url) => !managedProductImageUrl(url))) {
    return {
      ok: false,
      imageUrls: base.imageUrls,
      error: "Ürün fotoğraflarını Görsel ekle alanından yükleyin; dış bağlantı kullanılamaz.",
    };
  }
  return base;
}
