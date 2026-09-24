import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import {
  createRichCoreProduct,
  updateRichCoreProduct,
} from "@/lib/productCoreServer";
import {
  normalizeProductImageUrls,
  validateProductImageUrls,
} from "@/lib/productImagePolicy";
import { productTemplateByKey } from "@/lib/productAttributeSchema";
import { parseProductPriceNumber } from "@/lib/productPrice";
import { eksikZorunluAlanlar, eksikZorunluAlanMesaji } from "@/lib/productRequiredFields";
import {
  categoryTemplateKey,
  cleanAmount,
  cleanNonNegativeInt,
  cleanString,
  markaVeyaMagazaAdi,
  metadataForTemplate,
  urunGirdisiniHazirla,
  validateVariantSet,
  variantsForTemplate,
} from "@/lib/productIntake";

export const dynamic = "force-dynamic";

function hasOwn(value: Record<string, unknown>, key: string): boolean {
  return Object.prototype.hasOwnProperty.call(value, key);
}

function sameStringList(left: string[], right: string[]) {
  return left.length === right.length && left.every((value, index) => value === right[index]);
}

async function ownerContext(slug: string) {
  const cookieStore = await cookies();
  const ownerSession = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);
  if (!ownerSession) return null;
  const admin = getSupabaseAdmin();
  const { data: store } = await admin
    .from("stores")
    .select("id, edit_token, name")
    .eq("id", ownerSession.storeId)
    .single();
  if (!store?.id || !store.edit_token) return null;
  return { admin, store };
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

  const owned = await ownerContext(slug);
  if (!owned) return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });

  const imageValidation = validateProductImageUrls(govde.imageUrls);
  if (!imageValidation.ok) {
    return NextResponse.json({ hata: imageValidation.error ?? "Ürün fotoğrafları geçersiz." }, { status: 422 });
  }

  const categoryId = cleanString(govde.categoryId) || "";
  const templateKey = await categoryTemplateKey(owned.admin, owned.store.id, categoryId);
  if (!templateKey) return NextResponse.json({ hata: "Kategori bu vitrine ait değil veya ürün tipi geçersiz." }, { status: 422 });
  const template = productTemplateByKey(templateKey);
  if (!template) return NextResponse.json({ hata: "Ürün tipi geçersiz." }, { status: 422 });
  const isService = template.itemKind === "service";
  const metadata = metadataForTemplate(govde.metadata, templateKey);
  if (!metadata) return NextResponse.json({ hata: "Ürün detayları kategori tipiyle uyuşmuyor." }, { status: 422 });
  const variants = variantsForTemplate(govde.variants, templateKey, imageValidation.imageUrls);
  const barcode = isService ? null : cleanString(govde.barcode);
  const brand = isService
    ? null
    : markaVeyaMagazaAdi(govde.brand, templateKey, owned.store.name);
  const variantError = validateVariantSet(variants, barcode);
  if (variantError) return NextResponse.json({ hata: variantError }, { status: 422 });

  const priceText = typeof govde.priceText === "string" ? govde.priceText.trim() : "";
  const stockQuantity = isService ? null : cleanNonNegativeInt(govde.stockQuantity);
  const eksikMesaji = eksikZorunluAlanMesaji(
    eksikZorunluAlanlar({
      templateKey,
      brand,
      metadata,
      variants,
    }),
  );
  if (eksikMesaji) return NextResponse.json({ hata: eksikMesaji }, { status: 422 });
  try {
    const result = await createRichCoreProduct({
      admin: owned.admin,
      storeId: owned.store.id,
      editToken: owned.store.edit_token,
      name,
      description: typeof govde.description === "string" ? govde.description.trim() : "",
      priceText,
      priceAmount: cleanAmount(govde.priceAmount) ?? parseProductPriceNumber(priceText),
      imageUrls: imageValidation.imageUrls,
      categoryId,
      sourceType: "manual",
      externalProductId: "",
      oldPriceAmount: cleanAmount(govde.oldPriceAmount),
      badgeTag: cleanString(govde.badgeTag),
      fulfillmentRegion: cleanString(govde.fulfillmentRegion),
      brand,
      barcode,
      stockQuantity,
      stockStatus: isService ? null : cleanString(govde.stockStatus) || "Mevcut",
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

  const owned = await ownerContext(slug);
  if (!owned) return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });

  const { data: current } = await owned.admin
    .from("products")
    .select("name,description,price_text,price_amount,category_id,metadata,variants,brand,barcode,stock_quantity,stock_status,image_urls,old_price_amount,badge_tag,fulfillment_region")
    .eq("id", productId)
    .eq("store_id", owned.store.id)
    .maybeSingle();
  if (!current) return NextResponse.json({ hata: "Ürün bulunamadı." }, { status: 404 });

  const currentImageUrls = normalizeProductImageUrls(current.image_urls);
  const requestedImageUrls = hasOwn(govde, "imageUrls")
    ? normalizeProductImageUrls(govde.imageUrls)
    : currentImageUrls;
  const imageListChanged = !sameStringList(requestedImageUrls, currentImageUrls);
  let imageUrls = currentImageUrls;
  if (imageListChanged) {
    const imageValidation = validateProductImageUrls(govde.imageUrls);
    if (!imageValidation.ok) {
      return NextResponse.json({ hata: imageValidation.error ?? "Ürün fotoğrafları geçersiz." }, { status: 422 });
    }
    imageUrls = imageValidation.imageUrls;
  }

  const categoryId = hasOwn(govde, "categoryId")
    ? cleanString(govde.categoryId) || ""
    : cleanString(current.category_id) || "";
  const templateKey = await categoryTemplateKey(owned.admin, owned.store.id, categoryId);
  if (!templateKey) return NextResponse.json({ hata: "Kategori bu vitrine ait değil veya ürün tipi geçersiz." }, { status: 422 });
  const template = productTemplateByKey(templateKey);
  if (!template) return NextResponse.json({ hata: "Ürün tipi geçersiz." }, { status: 422 });
  const isService = template.itemKind === "service";

  const metadataInput = hasOwn(govde, "metadata") ? govde.metadata : current.metadata;
  const metadata = metadataForTemplate(metadataInput, templateKey);
  if (!metadata) return NextResponse.json({ hata: "Ürün detayları kategori tipiyle uyuşmuyor." }, { status: 422 });
  const variantInput = hasOwn(govde, "variants") ? govde.variants : current.variants;
  const variants = variantsForTemplate(variantInput, templateKey, imageUrls);

  const name = hasOwn(govde, "name") ? cleanString(govde.name) || "" : cleanString(current.name) || "";
  if (!name) return NextResponse.json({ hata: "Ürün adı zorunludur." }, { status: 422 });
  const description = hasOwn(govde, "description")
    ? typeof govde.description === "string" ? govde.description.trim() : ""
    : typeof current.description === "string" ? current.description.trim() : "";
  const priceText = hasOwn(govde, "priceText")
    ? typeof govde.priceText === "string" ? govde.priceText.trim() : ""
    : typeof current.price_text === "string" ? current.price_text.trim() : "";
  const priceAmount = hasOwn(govde, "priceAmount")
    ? cleanAmount(govde.priceAmount)
    : hasOwn(govde, "priceText")
      ? parseProductPriceNumber(priceText)
      : cleanAmount(current.price_amount);
  const stockQuantity = isService
    ? null
    : hasOwn(govde, "stockQuantity")
      ? cleanNonNegativeInt(govde.stockQuantity)
      : cleanNonNegativeInt(current.stock_quantity);
  const stockStatus = isService
    ? ""
    : hasOwn(govde, "stockStatus")
      ? cleanString(govde.stockStatus) || "Mevcut"
      : cleanString(current.stock_status) || "Mevcut";
  const brand = isService
    ? null
    : markaVeyaMagazaAdi(
        hasOwn(govde, "brand") ? govde.brand : current.brand,
        templateKey,
        owned.store.name,
      );
  const barcode = isService
    ? null
    : hasOwn(govde, "barcode")
      ? cleanString(govde.barcode)
      : cleanString(current.barcode);
  const oldPriceAmount = hasOwn(govde, "oldPriceAmount")
    ? cleanAmount(govde.oldPriceAmount)
    : cleanAmount(current.old_price_amount);
  const badgeTag = hasOwn(govde, "badgeTag")
    ? cleanString(govde.badgeTag)
    : cleanString(current.badge_tag);
  const fulfillmentRegion = hasOwn(govde, "fulfillmentRegion")
    ? cleanString(govde.fulfillmentRegion)
    : cleanString(current.fulfillment_region);
  const variantError = validateVariantSet(variants, barcode);
  if (variantError) return NextResponse.json({ hata: variantError }, { status: 422 });

  const eksikMesaji = eksikZorunluAlanMesaji(
    eksikZorunluAlanlar({ templateKey, brand, metadata, variants }),
  );
  if (eksikMesaji) return NextResponse.json({ hata: eksikMesaji }, { status: 422 });

  try {
    await updateRichCoreProduct({
      admin: owned.admin,
      productId,
      editToken: owned.store.edit_token,
      name,
      description,
      priceText,
      priceAmount,
      imageUrls,
      categoryId,
      stockStatus,
      stockQuantity,
      oldPriceAmount,
      badgeTag,
      fulfillmentRegion,
      brand,
      barcode,
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
