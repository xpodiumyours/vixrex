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
  category_name?: string;
  image_urls?: string[];
  source_type?: string;
  sort_order?: number;
  isVisible?: boolean;
  stock_status?: string;
  stock_quantity?: number;
  brand?: string;
  barcode?: string;
  sku?: string;
}

function cleanString(value: unknown): string | null {
  return typeof value === "string" ? value.trim() || null : null;
}

export async function POST(request: NextRequest) {
  let govde: { slug?: unknown; products?: unknown };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde?.slug === "string" ? govde.slug.trim() : "";
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
  const products = govde.products.map((value: unknown, index: number) => {
    if (!value || typeof value !== "object" || Array.isArray(value)) return value;
    const p = value as ProductBatchItem;
    return {
      ...p,
      name: cleanString(p.name) ?? "",
      description: cleanString(p.description) ?? "",
      price_text: cleanString(p.price_text) ?? "",
      category_id: cleanString(p.category_id),
      category_name: cleanString(p.category_name),
      image_urls: p.image_urls ?? [],
      source_type: cleanString(p.source_type) ?? "bulk_import",
      sort_order: p.sort_order ?? index,
      isVisible: p.isVisible !== false,
      stock_status: cleanString(p.stock_status),
      stock_quantity: p.stock_quantity ?? null,
      brand: cleanString(p.brand),
      barcode: cleanString(p.barcode),
      sku: cleanString(p.sku),
    };
  });

  try {
    const { data, error } = await admin.rpc("batch_create_products", {
      p_store_id: store.id,
      p_edit_token: store.edit_token,
      p_products: products,
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
