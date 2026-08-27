import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import {
  createCoreProduct,
  updateCoreProduct,
} from "@/lib/productCoreServer";

/**
 * Ürün CRUD API'si — owner session ile korunuyor.
 *
 * POST: Yeni ürün oluştur
 * PATCH: Ürün güncelle
 * DELETE: Ürün sil
 *
 * Zincir:
 *   HttpOnly sahip çerezi doğrulanır
 *   → Supabase admin client ile RPC çağrılır
 *   → Sonuç döndürülür
 */

export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const name = typeof govde.name === "string" ? govde.name.trim() : "";
  if (!slug || !name) {
    return NextResponse.json(
      { hata: "Vitrin ve ürün adı zorunludur." },
      { status: 422 }
    );
  }

  // Oturum doğrulaması
  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);
  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Oturumun geçersiz veya süresi dolmuş." },
      { status: 401 }
    );
  }

  const admin = getSupabaseAdmin();

  // edit_token'ı owner session'dan al — store'un edit_token'ını bul
  // Basitleştirme: owner session store_id taşıyor, onu kullanarak store'u bul
  const { data: store } = await admin
    .from("stores")
    .select("id, edit_token")
    .eq("id", ownerSession.storeId)
    .single();

  if (!store?.edit_token) {
    return NextResponse.json(
      { hata: "Vitrin bulunamadı." },
      { status: 404 }
    );
  }

  try {
    const result = await createCoreProduct({
      admin,
      storeId: store.id,
      editToken: store.edit_token,
      name,
      description: typeof govde.description === "string" ? govde.description : "",
      priceText: typeof govde.priceText === "string" ? govde.priceText : "",
      imageUrls: Array.isArray(govde.imageUrls) ? govde.imageUrls : [],
      categoryId: typeof govde.categoryId === "string" ? govde.categoryId : "",
      sourceType: "manual",
      externalProductId: "",
    });

    return NextResponse.json({ tamam: true, id: result.id, slug: result.slug });
  } catch (err) {
    console.error("[products] create failed:", err);
    return NextResponse.json(
      { hata: "Ürün oluşturulamadı." },
      { status: 500 }
    );
  }
}

export async function PATCH(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const productId = typeof govde.productId === "string" ? govde.productId.trim() : "";
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!productId || !slug) {
    return NextResponse.json(
      { hata: "Ürün ID ve vitrin zorunludur." },
      { status: 422 }
    );
  }

  // Oturum doğrulaması
  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);
  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Oturumun geçersiz veya süresi dolmuş." },
      { status: 401 }
    );
  }

  const admin = getSupabaseAdmin();

  const { data: store } = await admin
    .from("stores")
    .select("id, edit_token")
    .eq("id", ownerSession.storeId)
    .single();

  if (!store?.edit_token) {
    return NextResponse.json(
      { hata: "Vitrin bulunamadı." },
      { status: 404 }
    );
  }

  try {
    await updateCoreProduct({
      admin,
      productId,
      editToken: store.edit_token,
      name: typeof govde.name === "string" ? govde.name : "",
      description: typeof govde.description === "string" ? govde.description : "",
      priceText: typeof govde.priceText === "string" ? govde.priceText : "",
      imageUrls: Array.isArray(govde.imageUrls) ? govde.imageUrls : [],
      categoryId: typeof govde.categoryId === "string" ? govde.categoryId : "",
      stockStatus: typeof govde.stockStatus === "string" ? govde.stockStatus : "Mevcut",
    });

    return NextResponse.json({ tamam: true });
  } catch (err) {
    console.error("[products] update failed:", err);
    return NextResponse.json(
      { hata: "Ürün güncellenemedi." },
      { status: 500 }
    );
  }
}

export async function DELETE(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const productId = typeof govde.productId === "string" ? govde.productId.trim() : "";
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!productId || !slug) {
    return NextResponse.json(
      { hata: "Ürün ID ve vitrin zorunludur." },
      { status: 422 }
    );
  }

  // Oturum doğrulaması
  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);
  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Oturumun geçersiz veya süresi dolmuş." },
      { status: 401 }
    );
  }

  const admin = getSupabaseAdmin();

  const { data: store } = await admin
    .from("stores")
    .select("id, edit_token")
    .eq("id", ownerSession.storeId)
    .single();

  if (!store?.edit_token) {
    return NextResponse.json(
      { hata: "Vitrin bulunamadı." },
      { status: 404 }
    );
  }

  try {
    const { error } = await admin.rpc("delete_store_product", {
      p_product_id: productId,
      p_edit_token: store.edit_token,
    });

    if (error) {
      console.error("[products] delete failed:", error.message);
      return NextResponse.json(
        { hata: "Ürün silinemedi." },
        { status: 500 }
      );
    }

    return NextResponse.json({ tamam: true });
  } catch (err) {
    console.error("[products] delete failed:", err);
    return NextResponse.json(
      { hata: "Ürün silinemedi." },
      { status: 500 }
    );
  }
}
