import type { SupabaseClient } from "@supabase/supabase-js";
import type { ProductMetadata, ProductVariant } from "@/lib/productRichData";

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
  oldPriceAmount?: number | null;
  badgeTag?: string | null;
  fulfillmentRegion?: string | null;
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
    p_old_price_amount: args.oldPriceAmount ?? null,
    p_badge_tag: args.badgeTag ?? null,
    p_fulfillment_region: args.fulfillmentRegion ?? null,
  });

  if (error) rpcError(error, "PRODUCT_CORE_CREATE_FAILED");
  const id = String(data?.id || "").trim();
  const slug = String(data?.slug || "").trim();
  if (!id || !slug || data?.success !== true) {
    throw new Error("PRODUCT_CORE_CREATE_FAILED");
  }

  return { id, slug, created: data?.created !== false };
}

export async function createRichCoreProduct(args: {
  admin: SupabaseClient;
  storeId: string;
  editToken: string;
  name: string;
  description: string;
  priceText: string;
  priceAmount?: number | null;
  imageUrls: string[];
  categoryId: string;
  sourceType: string;
  externalProductId: string;
  oldPriceAmount?: number | null;
  badgeTag?: string | null;
  fulfillmentRegion?: string | null;
  brand?: string | null;
  barcode?: string | null;
  stockQuantity?: number | null;
  stockStatus?: string | null;
  metadata: ProductMetadata;
  variants: ProductVariant[];
  isVisible?: boolean;
  sortOrder?: number;
}): Promise<CreatedCoreProduct> {
  const { data, error } = await args.admin.rpc("create_store_product_v3", {
    p_store_id: args.storeId,
    p_edit_token: args.editToken,
    p_name: args.name,
    p_description: args.description,
    p_price_text: args.priceText,
    p_price_amount: args.priceAmount ?? null,
    p_image_urls: args.imageUrls,
    p_category_id: args.categoryId || null,
    p_source_type: args.sourceType,
    p_external_product_id: args.externalProductId || null,
    p_is_visible: args.isVisible ?? true,
    p_sort_order: args.sortOrder ?? 0,
    p_old_price_amount: args.oldPriceAmount ?? null,
    p_badge_tag: args.badgeTag ?? null,
    p_fulfillment_region: args.fulfillmentRegion ?? null,
    p_brand: args.brand ?? null,
    p_barcode: args.barcode ?? null,
    p_stock_quantity: args.stockQuantity ?? null,
    p_stock_status: args.stockStatus ?? null,
    p_metadata: args.metadata,
    p_variants: args.variants,
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
  oldPriceAmount?: number | null;
  badgeTag?: string | null;
  fulfillmentRegion?: string | null;
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
    p_old_price_amount: args.oldPriceAmount ?? null,
    p_badge_tag: args.badgeTag ?? null,
    p_fulfillment_region: args.fulfillmentRegion ?? null,
    p_clear_old_price_amount: args.oldPriceAmount == null,
    p_clear_badge_tag: !args.badgeTag,
    p_clear_fulfillment_region: !args.fulfillmentRegion,
  });

  if (error || data?.success !== true) {
    rpcError(error, "PRODUCT_CORE_UPDATE_FAILED");
  }
}

export async function updateRichCoreProduct(args: {
  admin: SupabaseClient;
  productId: string;
  editToken: string;
  name: string;
  description: string;
  priceText: string;
  priceAmount?: number | null;
  imageUrls: string[];
  categoryId: string;
  stockStatus: string;
  stockQuantity?: number | null;
  oldPriceAmount?: number | null;
  badgeTag?: string | null;
  fulfillmentRegion?: string | null;
  brand?: string | null;
  barcode?: string | null;
  metadata: ProductMetadata;
  variants: ProductVariant[];
}) {
  const { data, error } = await args.admin.rpc("update_store_product_v2", {
    p_product_id: args.productId,
    p_edit_token: args.editToken,
    p_name: args.name,
    p_description: args.description,
    p_price_text: args.priceText,
    p_price_amount: args.priceAmount ?? null,
    p_image_urls: args.imageUrls,
    p_category_id: args.categoryId || null,
    p_stock_quantity: args.stockQuantity ?? null,
    p_stock_status: args.stockStatus,
    p_old_price_amount: args.oldPriceAmount ?? null,
    p_badge_tag: args.badgeTag ?? null,
    p_fulfillment_region: args.fulfillmentRegion ?? null,
    p_brand: args.brand ?? null,
    p_barcode: args.barcode ?? null,
    p_metadata: args.metadata,
    p_variants: args.variants,
    p_clear_category: !args.categoryId,
    p_clear_price_amount: args.priceAmount == null,
    p_clear_stock_quantity: args.stockQuantity == null,
    p_clear_stock_status: !args.stockStatus,
    p_clear_old_price_amount: args.oldPriceAmount == null,
    p_clear_badge_tag: !args.badgeTag,
    p_clear_fulfillment_region: !args.fulfillmentRegion,
    p_clear_brand: !args.brand,
    p_clear_barcode: !args.barcode,
    p_clear_metadata: false,
    p_clear_variants: false,
  });

  if (error || data?.success !== true) {
    rpcError(error, "PRODUCT_CORE_UPDATE_FAILED");
  }
}

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
