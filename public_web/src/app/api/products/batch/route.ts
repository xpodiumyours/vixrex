import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { validateExternalProductImageUrlsForImport } from "@/lib/productImagePolicy";

/**
 * Toplu ürün oluşturma/güncelleme API'si.
 *
 * Bir satırın bozuk olması bütün partiyi iptal etmez. Geçerli satırlar aynı
 * batch Product CORE yoluna gönderilir, satır hataları kendi gerçek sıra
 * numaralarıyla sonuçta birleştirilir.
 */

export const dynamic = "force-dynamic";

interface ProductBatchItem {
  name?: unknown;
  description?: unknown;
  price_text?: unknown;
  category_id?: unknown;
  category_name?: unknown;
  image_urls?: unknown;
  source_type?: unknown;
  external_product_id?: unknown;
  sort_order?: unknown;
  isVisible?: unknown;
  stock_status?: unknown;
  stock_quantity?: unknown;
  brand?: unknown;
  barcode?: unknown;
  sku?: unknown;
}

interface BatchErrorDetail {
  index?: number;
  error?: string;
}

function cleanString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed || null;
}

function cleanStockQuantity(value: unknown): {
  ok: boolean;
  value: number | null;
} {
  if (value === undefined || value === null || value === "") {
    return { ok: true, value: null };
  }
  if (typeof value !== "number" || !Number.isInteger(value) || value < 0) {
    return { ok: false, value: null };
  }
  return { ok: true, value };
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
    return NextResponse.json(
      { hata: "Tek seferde en fazla 100 ürün yüklenebilir." },
      { status: 422 },
    );
  }

  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);
  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Oturumun geçersiz veya süresi dolmuş." },
      { status: 401 },
    );
  }

  const admin = getSupabaseAdmin();
  const { data: store } = await admin
    .from("stores")
    .select("id, edit_token")
    .eq("id", ownerSession.storeId)
    .single();

  if (!store?.edit_token) {
    return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
  }

  const rowErrors: BatchErrorDetail[] = [];
  const validRows: Array<{
    originalIndex: number;
    product: Record<string, unknown>;
  }> = [];

  govde.products.forEach((raw, index) => {
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
      rowErrors.push({ index: index + 1, error: "Ürün satırı geçersiz." });
      return;
    }

    const item = raw as ProductBatchItem;
    const name = cleanString(item.name);
    if (!name) {
      rowErrors.push({ index: index + 1, error: "Ürün adı boş." });
      return;
    }

    const imageValidation = validateExternalProductImageUrlsForImport(
      item.image_urls,
    );
    if (!imageValidation.ok) {
      rowErrors.push({
        index: index + 1,
        error: imageValidation.error ?? "Ürün fotoğrafları geçersiz.",
      });
      return;
    }

    const stockQuantity = cleanStockQuantity(item.stock_quantity);
    if (!stockQuantity.ok) {
      rowErrors.push({ index: index + 1, error: "Stok adedi geçersiz." });
      return;
    }

    validRows.push({
      originalIndex: index,
      product: {
        name,
        description: cleanString(item.description) ?? "",
        price_text: cleanString(item.price_text) ?? "",
        category_id: cleanString(item.category_id),
        category_name: cleanString(item.category_name),
        image_urls: imageValidation.imageUrls,
        source_type: cleanString(item.source_type) ?? "bulk_import",
        external_product_id: cleanString(item.external_product_id),
        sort_order:
          typeof item.sort_order === "number" && Number.isInteger(item.sort_order)
            ? item.sort_order
            : undefined,
        isVisible: typeof item.isVisible === "boolean" ? item.isVisible : undefined,
        stock_status: cleanString(item.stock_status),
        stock_quantity: stockQuantity.value,
        brand: cleanString(item.brand),
        barcode: cleanString(item.barcode),
        sku: cleanString(item.sku),
      },
    });
  });

  if (validRows.length === 0) {
    return NextResponse.json({
      tamam: true,
      toplam: govde.products.length,
      eklenen: 0,
      guncellenen: 0,
      degismeyen: 0,
      hatali: rowErrors.length,
      hataDetaylari: rowErrors,
    });
  }

  try {
    const { data, error } = await admin.rpc("batch_create_products", {
      p_store_id: store.id,
      p_edit_token: store.edit_token,
      p_products: JSON.stringify(validRows.map((row) => row.product)),
    });

    if (error) {
      console.error("[products/batch] RPC failed:", error.message);
      return NextResponse.json(
        { hata: "Toplu ekleme başarısız oldu. Lütfen tekrar dene." },
        { status: 500 },
      );
    }

    const result = data as {
      success?: boolean;
      total?: number;
      inserted?: number;
      updated?: number;
      unchanged?: number;
      errors?: number;
      error_details?: BatchErrorDetail[];
    };

    const rpcErrors = Array.isArray(result?.error_details)
      ? result.error_details
      : [];
    const mappedRpcErrors = rpcErrors.map((detail) => {
      const rpcIndex =
        typeof detail.index === "number" && Number.isInteger(detail.index)
          ? detail.index
          : null;
      const original =
        rpcIndex !== null && rpcIndex >= 1
          ? validRows[rpcIndex - 1]?.originalIndex
          : undefined;
      return {
        index: original === undefined ? undefined : original + 1,
        error: detail.error ?? "Ürün kaydedilemedi.",
      };
    });

    const rpcErrorCount =
      typeof result?.errors === "number" && result.errors >= 0
        ? result.errors
        : mappedRpcErrors.length;

    return NextResponse.json({
      tamam: true,
      toplam: govde.products.length,
      eklenen: result?.inserted ?? 0,
      guncellenen: result?.updated ?? 0,
      degismeyen: result?.unchanged ?? 0,
      hatali: rowErrors.length + rpcErrorCount,
      hataDetaylari: [...rowErrors, ...mappedRpcErrors],
    });
  } catch (err) {
    console.error("[products/batch] failed:", err);
    return NextResponse.json(
      { hata: "Toplu ekleme başarısız oldu." },
      { status: 500 },
    );
  }
}
