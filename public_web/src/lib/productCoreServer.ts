import type { SupabaseClient } from "@supabase/supabase-js";

export interface CoreProductRow {
  id: string;
  slug: string;
  name: string;
  description?: string | null;
  price_text?: string | null;
  image_urls?: string[] | null;
  category_id?: string | null;
  stock_status?: string | null;
  created_at?: string | null;
  product_categories?: { name?: string | null } | null;
}

export interface CreatedCoreProduct {
  id: string;
  slug: string;
  created: boolean;
}

function rpcError(error: { message?: string } | null, fallback: string) {
  throw new Error(error?.message || fallback);
}

export async function findCoreProductByExternalId(args: {
  admin: SupabaseClient;
  storeId: string;
  sourceType: string;
  externalProductId: string;
}): Promise<CoreProductRow | null> {
  const { data, error } = await args.admin
    .from("products")
    .select(
      "id,slug,name,description,price_text,image_urls,category_id,stock_status,created_at,product_categories(name)",
    )
    .eq("store_id", args.storeId)
    .eq("source_type", args.sourceType)
    .eq("external_product_id", args.externalProductId)
    .maybeSingle();

  if (error) rpcError(error, "PRODUCT_CORE_READ_FAILED");
  return (data as CoreProductRow | null) ?? null;
}

export async function upsertCoreCategory(args: {
  admin: SupabaseClient;
  storeId: string;
  editToken: string;
  name: string;
}) {
  const { data, error } = await args.admin.rpc("upsert_store_category", {
    p_store_id: args.storeId,
    p_edit_token: args.editToken,
    p_name: args.name,
  });

  if (error) rpcError(error, "PRODUCT_CATEGORY_WRITE_FAILED");
  const id = String(data?.id || "").trim();
  if (!id || data?.success !== true) {
    throw new Error("PRODUCT_CATEGORY_WRITE_FAILED");
  }
  return id;
}

export async function createCoreProduct(args: {
  admin: SupabaseClient;
  storeId: string;
  editToken: string;
  name: string;
  description: string;
  priceText: string;
  imageUrls: string[];
  categoryId: string;
  sourceType: string;
  externalProductId: string;
}): Promise<CreatedCoreProduct> {
  const { data, error } = await args.admin.rpc("create_store_product_v2", {
    p_store_id: args.storeId,
    p_edit_token: args.editToken,
    p_name: args.name,
    p_description: args.description,
    p_price_text: args.priceText,
    p_image_urls: args.imageUrls,
    p_category_id: args.categoryId,
    p_source_type: args.sourceType,
    p_external_product_id: args.externalProductId,
  });

  if (error) rpcError(error, "PRODUCT_CORE_CREATE_FAILED");
  const id = String(data?.id || "").trim();
  const slug = String(data?.slug || "").trim();
  if (!id || !slug || data?.success !== true) {
    throw new Error("PRODUCT_CORE_CREATE_FAILED");
  }

  return { id, slug, created: data?.created !== false };
}

export async function updateCoreProduct(args: {
  admin: SupabaseClient;
  productId: string;
  editToken: string;
  name: string;
  description: string;
  priceText: string;
  imageUrls: string[];
  categoryId: string;
  stockStatus: string;
}) {
  const { data, error } = await args.admin.rpc("update_store_product", {
    p_product_id: args.productId,
    p_edit_token: args.editToken,
    p_name: args.name,
    p_description: args.description,
    p_price_text: args.priceText,
    p_image_urls: args.imageUrls,
    p_category_id: args.categoryId,
    p_stock_status: args.stockStatus,
  });

  if (error || data?.success !== true) {
    rpcError(error, "PRODUCT_CORE_UPDATE_FAILED");
  }
}

/**
 * Server-side Product CORE cleanup used only after the store edit token has
 * been verified. Keeping this write here prevents API routes from maintaining
 * a second product-storage implementation.
 */
export async function deleteCoreProductsBySource(args: {
  admin: SupabaseClient;
  storeId: string;
  sourceType: string;
}) {
  const { error } = await args.admin
    .from("products")
    .delete()
    .eq("store_id", args.storeId)
    .eq("source_type", args.sourceType);

  if (error) rpcError(error, "PRODUCT_CORE_DELETE_FAILED");
}
