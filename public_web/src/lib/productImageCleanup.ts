import type { SupabaseClient } from "@supabase/supabase-js";
import { normalizeProductImageUrls } from "@/lib/productImagePolicy";

const PRODUCT_IMAGE_BUCKET = "shelf-images";
const PUBLIC_OBJECT_MARKER = `/storage/v1/object/public/${PRODUCT_IMAGE_BUCKET}/`;

function safeStoreSlug(value: string): string {
  return value.replace(/[^a-zA-Z0-9-]/g, "");
}

/**
 * Yalnız Vixrex'in aynı Supabase projesindeki ürün klasörlerini Storage yolu
 * olarak kabul eder. Dış CDN, başka vitrin veya logo/owner klasörleri silme
 * adayı olamaz.
 */
export function managedProductStoragePath(
  imageUrl: string,
  storeSlug: string,
  supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL,
): string | null {
  const expectedOriginText = String(supabaseUrl || "").trim();
  const cleanSlug = safeStoreSlug(storeSlug);
  if (!expectedOriginText || !cleanSlug) return null;

  try {
    const parsed = new URL(imageUrl);
    const expectedOrigin = new URL(expectedOriginText);
    if (parsed.origin !== expectedOrigin.origin) return null;

    const decodedPath = decodeURIComponent(parsed.pathname);
    const markerIndex = decodedPath.indexOf(PUBLIC_OBJECT_MARKER);
    if (markerIndex < 0) return null;

    const objectPath = decodedPath.slice(markerIndex + PUBLIC_OBJECT_MARKER.length);
    const expectedPrefix = `${cleanSlug}/products/`;
    if (!objectPath.startsWith(expectedPrefix)) return null;
    if (objectPath.includes("\\") || objectPath.split("/").some((part) => part === "..")) {
      return null;
    }
    return objectPath;
  } catch {
    return null;
  }
}

export async function cleanupUnreferencedProductImages(args: {
  admin: SupabaseClient;
  storeId: string;
  storeSlug: string;
  candidateUrls: string[];
}): Promise<number> {
  const candidatePaths = new Set<string>();
  for (const url of normalizeProductImageUrls(args.candidateUrls)) {
    const path = managedProductStoragePath(url, args.storeSlug);
    if (path) candidatePaths.add(path);
  }
  if (candidatePaths.size === 0) return 0;

  try {
    const { data, error } = await args.admin
      .from("products")
      .select("image_urls")
      .eq("store_id", args.storeId);
    if (error) {
      console.error("[product-image-cleanup] reference read failed:", error.message);
      return 0;
    }

    const referencedPaths = new Set<string>();
    for (const row of data || []) {
      const imageUrls = normalizeProductImageUrls(
        (row as { image_urls?: unknown }).image_urls,
      );
      for (const url of imageUrls) {
        const path = managedProductStoragePath(url, args.storeSlug);
        if (path) referencedPaths.add(path);
      }
    }

    const removable = Array.from(candidatePaths).filter(
      (path) => !referencedPaths.has(path),
    );
    if (removable.length === 0) return 0;

    const { error: removeError } = await args.admin.storage
      .from(PRODUCT_IMAGE_BUCKET)
      .remove(removable);
    if (removeError) {
      console.error("[product-image-cleanup] storage remove failed:", removeError.message);
      return 0;
    }
    return removable.length;
  } catch (error) {
    console.error(
      "[product-image-cleanup] unexpected failure:",
      error instanceof Error ? error.message : error,
    );
    return 0;
  }
}
