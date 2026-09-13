import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import {
  createRichCoreProduct,
  updateRichCoreProduct,
} from "@/lib/productCoreServer";
import { validateProductImageUrls } from "@/lib/productImagePolicy";
import {
  normalizeProductMetadata,
  normalizeProductVariants,
  type ProductMetadata,
  type ProductVariant,
} from "@/lib/productRichData";
import { productTemplateByKey } from "@/lib/productAttributeSchema";

export const dynamic = "force-dynamic";

function cleanString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed || null;
}

function cleanNonNegativeInt(value: unknown): number | null {
  return typeof value === "number" && Number.isInteger(value) && value >= 0 ? value : null;
}

function cleanAmount(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) && value >= 0 ? value : null;
}

function amountFromPriceText(value: unknown): number | null {
  if (typeof value !== "string") return null;
  let cleaned = value.trim().replaceAll(/[^0-9.,]/g, "");
  if (!cleaned) return null;
  if (cleaned.includes(",") && cleaned.includes(".")) {
    cleaned = cleaned.replaceAll(".", "").replaceAll(",", ".");
  } else if (cleaned.includes(",")) {
    cleaned = cleaned.replaceAll(",", ".");
  }
  const amount = Number(cleaned);
  return Number.isFinite(amount) && amount >= 0 ? amount : null;
}

async function ownerContext(slug: string) {
  const cookieStore = await cookies();
  const ownerSession = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);
  if (!ownerSession) return null;
  const admin = getSupabaseAdmin();
  const { data: store } = await admin
    .from("stores")
    .select("id, edit_token")
    .eq("id", ownerSession.storeId)
    .single();
  if (!store?.id || !store.edit_token) return null;
  return { admin, store };
}

async function categoryTemplateKey(
  admin: ReturnType<typeof getSupabaseAdmin>,
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

function metadataForTemplate(value: unknown, templateKey: string): ProductMetadata | null {
  const template = productTemplateByKey(templateKey);
  if (!template) return null;
  const normalized = normalizeProductMetadata(value);
  if (normalized.templateKey && normalized.templateKey !== templateKey) return null;
  return {
    ...normalized,
    schemaVersion: normalized.schemaVersion ?? 1,
    itemKind: template.itemKind,
    templateKey,
  };
}

export async function GET(request: NextRequest) {
  const slug = request.nextUrl.searchParams.get("slug")?.trim() || "";
  const productId = request.nextUrl.searchParams.get("productId")?.trim() || "";
  if (!slug || !productId) {
    return NextResponse.json({ hata: "Vitrin ve ürün ID zorunludur." }, { status: 422 });
  }
  const owned = await ownerContext(slug);
  if (!owned) return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });

  const { data, error } = await owned.admin
    .from("products")
    .select("id,slug,name,description,price_text,price_amount,currency,image_urls,category_id,stock_status,stock_quantity,brand,barcode,metadata,variants,old_price_amount,badge_tag,fulfillment_region,product_categories(name,product_template_key)")
    .eq("id", productId)
    .eq("store_id", owned.store.id)
    .maybeSingle();
  if (error || !data) return NextResponse.json({ hata: "Ürün bulunamadı." }, { status: 404 });
  return NextResponse.json({ tamam: true, product: data });
}

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try { govde = await request.json(); } catch { return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 }); }

  const slug = cleanString(govde.slug) || "";
  const name = cleanString(govde.name) || "";
  if (!slug || !name) return NextResponse.json({ hata: "Vitrin ve ürün adı zorunludur." }, { status: 422 });

  const imageValidation = validateProductImageUrls(govde.imageUrls);
  if (!imageValidation.ok) {
    return NextResponse.json({ hata: imageValidation.error ?? "Ürün fotoğrafları geçersiz." }, { status: 422 });
  }

  const owned = await ownerContext(slug);
  if (!owned) return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });

  const categoryId = cleanString(govde.categoryId) || "";
  const templateKey = await categoryTemplateKey(owned.admin, owned.store.id, categoryId);
  if (!templateKey) return NextResponse.json({ hata: "Kategori bu vitrine ait değil veya ürün tipi geçersiz." }, { status: 422 });
  const metadata = metadataForTemplate(govde.metadata, templateKey);
  if (!metadata) return NextResponse.json({ hata: "Ürün detayları kategori tipiyle uyuşmuyor." }, { status: 422 });
  const variants = normalizeProductVariants(govde.variants);

  const priceText = typeof govde.priceText === "string" ? govde.priceText.trim() : "";
  const stockQuantity = cleanNonNegativeInt(govde.stockQuantity);
  try {
    const result = await createRichCoreProduct({
      admin: owned.admin,
      storeId: owned.store.id,
      editToken: owned.store.edit_token,
      name,
      description: typeof govde.description === "string" ? govde.description.trim() : "",
      priceText,
      priceAmount: cleanAmount(govde.priceAmount) ?? amountFromPriceText(priceText),
      imageUrls: imageValidation.imageUrls,
      categoryId,
      sourceType: "manual",
      externalProductId: "",
      oldPriceAmount: cleanAmount(govde.oldPriceAmount),
      badgeTag: cleanString(govde.badgeTag),
      fulfillmentRegion: cleanString(govde.fulfillmentRegion),
      brand: cleanString(govde.brand),
      barcode: cleanString(govde.barcode),
      stockQuantity,
      stockStatus: cleanString(govde.stockStatus) || "Mevcut",
      metadata,
      variants,
    });
    return NextResponse.json({ tamam: true, id: result.id, slug: result.slug });
  } catch (err) {
    console.error("[products] create failed:", err);
    return NextResponse.json({ hata: "Ürün oluşturulamadı." }, { status: 500 });
  }
}

export async function PATCH(request: NextRequest) {
  let govde: Record<string, unknown>;
  try { govde = await request.json(); } catch { return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 }); }

  const productId = cleanString(govde.productId) || "";
  const slug = cleanString(govde.slug) || "";
  if (!productId || !slug) return NextResponse.json({ hata: "Ürün ID ve vitrin zorunludur." }, { status: 422 });

  const imageValidation = validateProductImageUrls(govde.imageUrls);
  if (!imageValidation.ok) {
    return NextResponse.json({ hata: imageValidation.error ?? "Ürün fotoğrafları geçersiz." }, { status: 422 });
  }

  const owned = await ownerContext(slug);
  if (!owned) return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });

  const { data: current } = await owned.admin
    .from("products")
    .select("category_id,metadata,variants,brand,barcode,stock_quantity,price_amount")
    .eq("id", productId)
    .eq("store_id", owned.store.id)
    .maybeSingle();
  if (!current) return NextResponse.json({ hata: "Ürün bulunamadı." }, { status: 404 });

  const categoryId = cleanString(govde.categoryId) || cleanString(current.category_id) || "";
  const templateKey = await categoryTemplateKey(owned.admin, owned.store.id, categoryId);
  if (!templateKey) return NextResponse.json({ hata: "Kategori bu vitrine ait değil veya ürün tipi geçersiz." }, { status: 422 });

  const metadataInput = Object.prototype.hasOwnProperty.call(govde, "metadata") ? govde.metadata : current.metadata;
  const metadata = metadataForTemplate(metadataInput, templateKey);
  if (!metadata) return NextResponse.json({ hata: "Ürün detayları kategori tipiyle uyuşmuyor." }, { status: 422 });
  const variants: ProductVariant[] = Object.prototype.hasOwnProperty.call(govde, "variants")
    ? normalizeProductVariants(govde.variants)
    : normalizeProductVariants(current.variants);

  const priceText = typeof govde.priceText === "string" ? govde.priceText.trim() : "";
  try {
    await updateRichCoreProduct({
      admin: owned.admin,
      productId,
      editToken: owned.store.edit_token,
      name: typeof govde.name === "string" ? govde.name.trim() : "",
      description: typeof govde.description === "string" ? govde.description.trim() : "",
      priceText,
      priceAmount: cleanAmount(govde.priceAmount) ?? amountFromPriceText(priceText) ?? cleanAmount(current.price_amount),
      imageUrls: imageValidation.imageUrls,
      categoryId,
      stockStatus: cleanString(govde.stockStatus) || "Mevcut",
      stockQuantity: Object.prototype.hasOwnProperty.call(govde, "stockQuantity") ? cleanNonNegativeInt(govde.stockQuantity) : cleanNonNegativeInt(current.stock_quantity),
      oldPriceAmount: cleanAmount(govde.oldPriceAmount),
      badgeTag: cleanString(govde.badgeTag),
      fulfillmentRegion: cleanString(govde.fulfillmentRegion),
      brand: Object.prototype.hasOwnProperty.call(govde, "brand") ? cleanString(govde.brand) : cleanString(current.brand),
      barcode: Object.prototype.hasOwnProperty.call(govde, "barcode") ? cleanString(govde.barcode) : cleanString(current.barcode),
      metadata,
      variants,
    });
    return NextResponse.json({ tamam: true });
  } catch (err) {
    console.error("[products] update failed:", err);
    return NextResponse.json({ hata: "Ürün güncellenemedi." }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest) {
  let govde: Record<string, unknown>;
  try { govde = await request.json(); } catch { return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 }); }

  const productId = cleanString(govde.productId) || "";
  const slug = cleanString(govde.slug) || "";
  if (!productId || !slug) return NextResponse.json({ hata: "Ürün ID ve vitrin zorunludur." }, { status: 422 });

  const owned = await ownerContext(slug);
  if (!owned) return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });

  try {
    const { error } = await owned.admin.rpc("delete_store_product", {
      p_product_id: productId,
      p_edit_token: owned.store.edit_token,
    });
    if (error) return NextResponse.json({ hata: "Ürün silinemedi." }, { status: 500 });
    return NextResponse.json({ tamam: true });
  } catch (err) {
    console.error("[products] delete failed:", err);
    return NextResponse.json({ hata: "Ürün silinemedi." }, { status: 500 });
  }
}
