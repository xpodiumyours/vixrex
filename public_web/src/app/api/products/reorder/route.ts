import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

/**
 * Ürün sıralama API'si.
 *
 * POST: Ürünlerin sırasını günceller.
 *
 * Zincir:
 *   HttpOnly sahip çerezi doğrulanır
 *   → store id + edit_token bulunur
 *   → reorder_store_products RPC çağrılır
 *   → sonuç döndürülür
 */

export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  let govde: { slug?: unknown; productIds?: unknown };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 422 });
  }

  if (!Array.isArray(govde.productIds) || govde.productIds.length === 0) {
    return NextResponse.json({ hata: "Sıralanacak ürün listesi boş." }, { status: 422 });
  }

  // Tüm ID'lerin string olduğundan emin ol
  const productIds = govde.productIds
    .map((id: unknown) => (typeof id === "string" ? id.trim() : ""))
    .filter((id: string) => id.length > 0);

  if (productIds.length === 0) {
    return NextResponse.json({ hata: "Geçerli ürün ID'si bulunamadı." }, { status: 422 });
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

  // Store bilgilerini bul
  const { data: store } = await admin
    .from("stores")
    .select("id, edit_token")
    .eq("id", ownerSession.storeId)
    .single();

  if (!store?.edit_token) {
    return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
  }

  try {
    const { error } = await admin.rpc("reorder_store_products", {
      p_store_id: store.id,
      p_edit_token: store.edit_token,
      p_product_ids: productIds,
    });

    if (error) {
      console.error("[products/reorder] RPC failed:", error.message);
      return NextResponse.json(
        { hata: "Sıralama güncellenemedi. Lütfen tekrar dene." },
        { status: 500 }
      );
    }

    return NextResponse.json({ tamam: true });
  } catch (err) {
    console.error("[products/reorder] failed:", err);
    return NextResponse.json(
      { hata: "Sıralama güncellenemedi." },
      { status: 500 }
    );
  }
}
