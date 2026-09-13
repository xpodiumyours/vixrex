export const MIN_PRODUCT_IMAGES = 3;
export const MAX_PRODUCT_IMAGES = 10;

export interface ProductImageValidationResult {
  ok: boolean;
  imageUrls: string[];
  error?: string;
}

export function validateProductImageUrls(value: unknown): ProductImageValidationResult {
  if (!Array.isArray(value)) {
    return {
      ok: false,
      imageUrls: [],
      error: `Bir ürün için en az ${MIN_PRODUCT_IMAGES} fotoğraf zorunludur.`,
    };
  }

  const imageUrls = Array.from(
    new Set(
      value
        .filter((item): item is string => typeof item === "string")
        .map((item) => item.trim())
        .filter(Boolean),
    ),
  );

  if (imageUrls.length < MIN_PRODUCT_IMAGES) {
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

  if (imageUrls.some((url) => !/^https?:\/\//i.test(url))) {
    return {
      ok: false,
      imageUrls,
      error: "Ürün fotoğrafı bağlantıları http:// veya https:// ile başlamalıdır.",
    };
  }

  return { ok: true, imageUrls };
}
