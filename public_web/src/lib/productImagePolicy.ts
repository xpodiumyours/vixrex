import policyJson from "../../../shared/product_image_policy.json";

export const MIN_PRODUCT_IMAGES = policyJson.minImages;
export const FATURA_MIN_PRODUCT_IMAGES = policyJson.faturaMinImages;
export const MAX_PRODUCT_IMAGES = policyJson.maxImages;
export const MAX_PRODUCT_IMAGE_SOURCE_MEGABYTES = policyJson.maxSourceMegabytes;
export const MAX_PRODUCT_IMAGE_SOURCE_BYTES = MAX_PRODUCT_IMAGE_SOURCE_MEGABYTES * 1024 * 1024;
export const MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE = policyJson.minSourceShortEdge;
export const FATURA_MIN_SOURCE_SHORT_EDGE = policyJson.faturaMinSourceShortEdge;

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
  options: { httpsOnly: boolean; ignoreMinCount?: boolean },
): ProductImageValidationResult {
  if (!Array.isArray(value)) {
    return {
      ok: false,
      imageUrls: [],
      error: `Bir ürün için en az ${MIN_PRODUCT_IMAGES} fotoğraf zorunludur.`,
    };
  }

  const imageUrls = normalizeProductImageUrls(value);
  if (!options.ignoreMinCount && imageUrls.length < MIN_PRODUCT_IMAGES) {
    return {
      ok: false,
      imageUrls,
      error: `Bir ürün için en az ${MIN_PRODUCT_IMAGES} fotoğraf zorunludur.`,
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

export function yonetilenR2Originleri(): Set<string> {
  const originler = new Set<string>();
  const adaylar = [
    process.env.R2_PUBLIC_URL,
    process.env.NEXT_PUBLIC_R2_PUBLIC_URL,
  ];
  for (const ham of adaylar) {
    const temiz = String(ham || "").trim();
    if (!temiz) continue;
    try {
      const parsed = new URL(temiz);
      if (parsed.protocol === "https:" && !parsed.username && !parsed.password) {
        originler.add(parsed.origin);
      }
    } catch {
      continue;
    }
  }
  return originler;
}

export function yonetilenUrunGorseliMi(url: string): boolean {
  return managedProductImageUrl(url);
}

function managedProductImageUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== "https:") return false;

    const rawPath = parsed.pathname;
    if (rawPath.includes("..") || /%2e/i.test(rawPath)) return false;
    const path = decodeURIComponent(rawPath);
    if (path.includes("..") || path.includes("\\")) return false;

    const isSupabasePath =
      path.includes("/storage/v1/object/public/shelf-images/") &&
      path.includes("/products/");
    if (isSupabasePath) {
      const configuredOrigin = String(process.env.NEXT_PUBLIC_SUPABASE_URL || "").trim();
      if (configuredOrigin) {
        const expected = new URL(configuredOrigin);
        if (parsed.origin !== expected.origin) return false;
      }
      return true;
    }

    const r2Originleri = yonetilenR2Originleri();
    if (r2Originleri.has(parsed.origin)) {
      return /\/products\/[^/]+/.test(path);
    }

    return false;
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
 */
export function validateExternalProductImageUrls(value: unknown): ProductImageValidationResult {
  return validateCountAndUrls(value, { httpsOnly: false });
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
