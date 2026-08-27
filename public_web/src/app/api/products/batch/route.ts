import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

/**
 * Toplu ürün oluşturma API'si.
 *
 * POST: Birden fazla ürünü tek seferde oluşturur.
 *
 * Zincir:
 *   HttpOnly sahip çerezi doğrulanır
 *   → store id + edit_token bulunur
 *   → batch_create_products RPC çağrılır (SECURITY DEFINER)
 *   → sonuç döndürülür
 */

export const dynamic = "force-dynamic";

interface ProductBatchItem {
  name: string;
  description?: string;
  price_text?: string;
  category_id?: string;
  image_urls?: string[];
  source_type?: string;
  sort_order?: number;
  isVisible?: boolean;
}

export async function POST(request: NextRequest) {
  let govde: { slug?: unknown; products?: unknown };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 422 });
  }

  if (!Array.isArray(govde.products) || govde.products.length === 0) {
    return NextResponse.json({ hata: "En az bir ürün belirtilmeli." }, { status: 422 });
  }

  if (govde.products.length > 100) {
    return NextResponse.json({ hata: "Tek seferde en fazla 100 ürün yüklenebilir." }, { status: 422 });
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

  // Ürünleri batch_create_products RPC'sine gönder
  const products = govde.products.map((p: ProductBatchItem, index: number) => ({
    name: (p.name || "").trim(),
    description: (p.description || "").trim(),
    price_text: (p.price_text || "").trim(),
    category_id: (p.category_id || "").trim() || null,
    image_urls: Array.isArray(p.image_urls) ? p.image_urls : [],
    source_type: (p.source_type || "bulk_import").trim(),
    sort_order: typeof p.sort_order === "number" ? p.sort_order : index,
    isVisible: p.isVisible !== false,
  }));

  try {
    const { data, error } = await admin.rpc("batch_create_products", {
      p_store_id: store.id,
      p_edit_token: store.edit_token,
      p_products: JSON.stringify(products),
    });

    if (error) {
      console.error("[products/batch] RPC failed:", error.message);
      return NextResponse.json(
        { hata: "Toplu ekleme başarısız oldu. Lütfen tekrar dene." },
        { status: 500 }
      );
    }

    const result = data as {
      success?: boolean;
      total?: number;
      inserted?: number;
      errors?: number;
      error_details?: Array<{ index?: number; error?: string }>;
    };

    return NextResponse.json({
      tamam: true,
      toplam: result?.total ?? 0,
      eklenen: result?.inserted ?? 0,
      hatali: result?.errors ?? 0,
      hataDetaylari: result?.error_details ?? [],
    });
  } catch (err) {
    console.error("[products/batch] failed:", err);
    return NextResponse.json(
      { hata: "Toplu ekleme başarısız oldu." },
      { status: 500 }
    );
  }
}
