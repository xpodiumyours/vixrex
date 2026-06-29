import { revalidateTag } from "next/cache";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  retainManualProducts,
  safeParseJson,
  type ProductItem,
} from "@/lib/products";

function asProductArray(value: unknown) {
  return Array.isArray(value) ? safeParseJson<ProductItem>(value) : null;
}

export async function loadStoreProducts(
  admin: SupabaseClient,
  args: {
    storeSlug: string;
    products?: unknown;
    allowStoreFetchFallback?: boolean;
  },
) {
  const inlineProducts = asProductArray(args.products);
  if (inlineProducts) return inlineProducts;
  if (!args.allowStoreFetchFallback) return null;

  const { data: storeData } = await admin
    .from("stores")
    .select("products")
    .eq("slug", args.storeSlug)
    .maybeSingle();

  return asProductArray(storeData?.products);
}

export async function persistRetainedProducts(
  admin: SupabaseClient,
  args: {
    storeSlug: string;
    products: ProductItem[];
    importedSlugs?: readonly string[];
  },
) {
  const nextProducts = retainManualProducts(args.products, args.importedSlugs);
  const { error } = await admin
    .from("stores")
    .update({
      products: nextProducts,
      updated_at: new Date().toISOString(),
    })
    .eq("slug", args.storeSlug);

  if (error) throw error;
}

export async function removeInstagramStorageFiles(
  admin: SupabaseClient,
  storeSlug: string,
  logContext: string,
) {
  const { data: files, error: listError } = await admin.storage
    .from("shelf-images")
    .list(`${storeSlug}/instagram`, { limit: 1000 });

  if (listError || !files?.length) return;

  const pathsToRemove = files.map((file) => `${storeSlug}/instagram/${file.name}`);
  const { error: removeError } = await admin.storage
    .from("shelf-images")
    .remove(pathsToRemove);

  if (removeError) {
    console.error(`Failed to remove storage files during ${logContext}:`, removeError);
  }
}

export async function markInstagramConnectionDisconnected(
  admin: SupabaseClient,
  connectionId: string,
) {
  await admin
    .from("store_instagram_connections")
    .update({
      status: "disconnected",
      state_nonce: null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", connectionId);
}

export function revalidateInstagramCleanup(storeSlug: string) {
  revalidateTag(`store-${storeSlug}`, "max");
  revalidateTag(`products-${storeSlug}`, "max");
  revalidateTag("sitemap", "max");
}
