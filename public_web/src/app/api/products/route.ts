import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";
import { createCoreProduct, updateCoreProduct } from "@/lib/productCoreServer";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import {
  isProductProfileKey,
  normalizeProductMetadata,
  normalizeProductVariants,
} from "@/lib/productRichData";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

export const dynamic = "force-dynamic";

class ApiError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
  }
}

function hasOwn(body: Record<string, unknown>, key: string) {
  return Object.prototype.hasOwnProperty.call(body, key);
}

function text(value: unknown, max: number, label: string): string | null {
  if (value == null || value === "") return null;
  if (typeof value !== "string") throw new ApiError(`${label} geçersiz.`, 422);
  const normalized = value.trim();
  if (normalized.length > max) throw new ApiError(`${label} çok uzun.`, 422);
  return normalized || null;
}

function num(
  value: unknown,
  label: string,
  min = 0,
  max?: number,
  integer = false,
): number | null {
  if (value == null || value === "") return null;
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new ApiError(`${label} geçersiz.`, 422);
  }
  if (integer && !Number.isInteger(value)) throw new ApiError(`${label} tam sayı olmalı.`, 422);
  if (value < min || (max != null && value > max)) throw new ApiError(`${label} aralık dışında.`, 422);
  return value;
}

function rich(body: Record<string, unknown>) {
  const hasRichPayload = [
    "brand",
    "barcode",
    "vatRate",
    "stockQuantity",
    "metadata",
    "variants",
  ].some((key) => hasOwn(body, key));
  if (!hasRichPayload) return undefined;
  if (!hasOwn(body, "metadata")) {
    throw new ApiError("Zengin ürün bilgileri için ürün tipi zorunludur.", 422);
  }

  const rawMetadata = body.metadata;
  if (rawMetadata == null || typeof rawMetadata !== "object" || Array.isArray(rawMetadata)) {
    throw new ApiError("Ürün detayları geçersiz.", 422);
  }
  const profileKey = (rawMetadata as Record<string, unknown>).profileKey;
  if (!isProductProfileKey(profileKey)) {
    throw new ApiError("Ürün tipi geçersiz.", 422);
  }
  if (body.variants != null && !Array.isArray(body.variants)) {
    throw new ApiError("Ürün seçenekleri geçersiz.", 422);
  }

  const metadata = normalizeProductMetadata(rawMetadata);
  if (!metadata.profileKey) {
    throw new ApiError("Ürün tipi geçersiz.", 422);
  }
  const variants = normalizeProductVariants(body.variants, metadata.profileKey);
  if (Array.isArray(body.variants) && variants.length !== body.variants.length) {
    throw new ApiError("Ürün seçeneklerinden biri seçilen ürün tipiyle uyumsuz.", 422);
  }
  if (JSON.stringify(metadata).length > 20000 || JSON.stringify(variants).length > 50000) {
    throw new ApiError("Ürün detayları izin verilen boyutu aşıyor.", 422);
  }

  return {
    brand: text(body.brand, 120, "Marka"),
    barcode: text(body.barcode, 32, "Barkod / GTIN"),
    vatRate: num(body.vatRate, "KDV oranı", 0, 100, true),
    stockQuantity: num(body.stockQuantity, "Stok adedi", 0, undefined, true),
    stockStatus: text(body.stockStatus, 40, "Stok durumu") ?? "Mevcut",
    metadata,
    variants,
  };
}

async function ownerStore(slug: string) {
  const ownerSession = verifyOwnerSession(
    (await cookies()).get(OWNER_SESSION_COOKIE)?.value,
    slug,
  );
  if (!ownerSession) throw new ApiError("Oturumun geçersiz veya süresi dolmuş.", 401);

  const admin = getSupabaseAdmin();
  const { data: store } = await admin
    .from("stores")
    .select("id, edit_token")
    .eq("id", ownerSession.storeId)
    .single();
  if (!store?.edit_token) throw new ApiError("Vitrin bulunamadı.", 404);
  return { admin, store };
}

function fail(error: unknown, fallback: string) {
  if (error instanceof ApiError) {
    return NextResponse.json({ hata: error.message }, { status: error.status });
  }
  console.error(`[products] ${fallback}:`, error);
  return NextResponse.json({ hata: fallback }, { status: 500 });
}

async function bodyOf(request: NextRequest) {
  try {
    return (await request.json()) as Record<string, unknown>;
  } catch {
    throw new ApiError("Geçersiz istek.", 400);
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await bodyOf(request);
    const slug = text(body.slug, 160, "Vitrin") ?? "";
    const name = text(body.name, 80, "Ürün adı") ?? "";
    if (!slug || !name) throw new ApiError("Vitrin ve ürün adı zorunludur.", 422);
    const { admin, store } = await ownerStore(slug);
    const richFields = rich(body);
    const result = await createCoreProduct({
      admin,
      storeId: store.id,
      editToken: store.edit_token,
      name,
      description: text(body.description, 500, "Açıklama") ?? "",
      priceText: text(body.priceText, 30, "Fiyat") ?? "",
      priceAmount: num(body.priceAmount, "Fiyat"),
      imageUrls: Array.isArray(body.imageUrls) ? body.imageUrls.map(String).slice(0, 4) : [],
      categoryId: typeof body.categoryId === "string" ? body.categoryId : "",
      sourceType: "manual",
      externalProductId: "",
      oldPriceAmount: num(body.oldPriceAmount, "Eski fiyat"),
      badgeTag: text(body.badgeTag, 20, "Rozet"),
      fulfillmentRegion: text(body.fulfillmentRegion, 80, "Teslim bölgesi"),
      rich: richFields,
    });
    return NextResponse.json({ tamam: true, id: result.id, slug: result.slug });
  } catch (error) {
    return fail(error, "Ürün oluşturulamadı.");
  }
}

export async function PATCH(request: NextRequest) {
  try {
    const body = await bodyOf(request);
    const productId = text(body.productId, 80, "Ürün ID") ?? "";
    const slug = text(body.slug, 160, "Vitrin") ?? "";
    if (!productId || !slug) throw new ApiError("Ürün ID ve vitrin zorunludur.", 422);
    const { admin, store } = await ownerStore(slug);
    const richFields = rich(body);
    const priceAmount = hasOwn(body, "priceAmount")
      ? num(body.priceAmount, "Fiyat")
      : undefined;
    await updateCoreProduct({
      admin,
      productId,
      storeId: store.id,
      editToken: store.edit_token,
      name: text(body.name, 80, "Ürün adı") ?? "",
      description: text(body.description, 500, "Açıklama") ?? "",
      priceText: text(body.priceText, 30, "Fiyat") ?? "",
      priceAmount,
      imageUrls: Array.isArray(body.imageUrls) ? body.imageUrls.map(String).slice(0, 4) : [],
      categoryId: typeof body.categoryId === "string" ? body.categoryId : "",
      stockStatus: text(body.stockStatus, 40, "Stok durumu") ?? "Mevcut",
      oldPriceAmount: num(body.oldPriceAmount, "Eski fiyat"),
      badgeTag: text(body.badgeTag, 20, "Rozet"),
      fulfillmentRegion: text(body.fulfillmentRegion, 80, "Teslim bölgesi"),
      rich: richFields,
    });
    return NextResponse.json({ tamam: true });
  } catch (error) {
    return fail(error, "Ürün güncellenemedi.");
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const body = await bodyOf(request);
    const productId = text(body.productId, 80, "Ürün ID") ?? "";
    const slug = text(body.slug, 160, "Vitrin") ?? "";
    if (!productId || !slug) throw new ApiError("Ürün ID ve vitrin zorunludur.", 422);
    const { admin, store } = await ownerStore(slug);
    const { error } = await admin.rpc("delete_store_product", {
      p_product_id: productId,
      p_edit_token: store.edit_token,
    });
    if (error) throw error;
    return NextResponse.json({ tamam: true });
  } catch (error) {
    return fail(error, "Ürün silinemedi.");
  }
}
