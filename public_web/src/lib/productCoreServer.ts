import "server-only";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { ProductRichMetadata, ProductVariantData } from "@/lib/productRichData";

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

export interface RichProductWriteFields {
  brand?: string | null;
  barcode?: string | null;
  vatRate?: number | null;
  stockQuantity?: number | null;
  stockStatus?: string | null;
  metadata?: ProductRichMetadata;
  variants?: ProductVariantData[];
}

function rpcError(error: { message?: string } | null, fallback: string) {
  throw new Error(error?.message || fallback);
}

async function writeRichProductFields(args: {
  admin: SupabaseClient;
  storeId: string;
  productId: string;
  rich: RichProductWriteFields;
}) {
  const payload = {
    brand: args.rich.brand?.trim() || null,
    barcode: args.rich.barcode?.trim() || null,
    vat_rate: args.rich.vatRate ?? null,
    stock_quantity: args.rich.stockQuantity ?? null,
    stock_status: args.rich.stockStatus?.trim() || null,
    metadata: args.rich.metadata ?? {},
    variants: args.rich.variants ?? [],
  };

  const { data, error } = await args.admin
    .from("products")
    .update(payload)
    .eq("id", args.productId)
    .eq("store_id", args.storeId)
    .select("id")
    .maybeSingle();

  if (error || !data?.id) rpcError(error, "PRODUCT_RICH_WRITE_FAILED");
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
  if (!id || data?.success !== true) throw new Error("PRODUCT_CATEGORY_WRITE_FAILED");
  return id;
}

export async function createCoreProduct(args: {
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
  rich?: RichProductWriteFields;
}): Promise<CreatedCoreProduct> {
  const { data, error } = await args.admin.rpc("create_store_product_v2", {
    p_store_id: args.storeId,
    p_edit_token: args.editToken,
    p_name: args.name,
    p_description: args.description,
    p_price_text: args.priceText,
    p_price_amount: args.priceAmount ?? null,
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
  if (!id || !slug || data?.success !== true) throw new Error("PRODUCT_CORE_CREATE_FAILED");

  const created = data?.created !== false;
  if (created && args.rich) {
    await writeRichProductFields({
      admin: args.admin,
      storeId: args.storeId,
      productId: id,
      rich: args.rich,
    });
  }
  return { id, slug, created };
}

export async function updateCoreProduct(args: {
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
  oldPriceAmount?: number | null;
  badgeTag?: string | null;
  fulfillmentRegion?: string | null;
  storeId?: string;
  rich?: RichProductWriteFields;
}) {
  const rpcParams: Record<string, unknown> = {
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
  };

  // Eski istemciler price_amount göndermez. Bu durumda mevcut sayısal fiyatı
  // koru; yalnız alan açıkça gönderildiğinde yaz veya temizle.
  if (args.priceAmount !== undefined) {
    rpcParams.p_price_amount = args.priceAmount;
    rpcParams.p_clear_price_amount = args.priceAmount === null;
  }

  const { data, error } = await args.admin.rpc("update_store_product", rpcParams);
  if (error || data?.success !== true) rpcError(error, "PRODUCT_CORE_UPDATE_FAILED");

  if (args.rich) {
    if (!args.storeId) throw new Error("PRODUCT_RICH_STORE_REQUIRED");
    await writeRichProductFields({
      admin: args.admin,
      storeId: args.storeId,
      productId: args.productId,
      rich: args.rich,
    });
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
