import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { supabase } from "@/lib/supabase";
import { sahipYetkisi } from "@/lib/faturaYetki";
import { vitrinOnbelleginiYenile } from "@/lib/vitrinYayinDogrula";
import {
  fetchSupplierPermissionRequest,
  SUPPLIER_PERMISSION_TOKEN_RE,
  SUPPLIER_PERMISSION_UUID_RE,
} from "@/lib/supplierPermissionRequest";

export const dynamic = "force-dynamic";

function extractUuidList(value: unknown): string[] | null {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value)) return null;
  const valid: string[] = [];
  for (const item of value) {
    if (typeof item !== "string") return null;
    const trimmed = item.trim();
    if (!SUPPLIER_PERMISSION_UUID_RE.test(trimmed)) return null;
    valid.push(trimmed);
  }
  return [...new Set(valid)];
}

export async function POST(request: NextRequest) {
  let body: {
    slug?: unknown;
    editToken?: unknown;
    supplierName?: unknown;
    brand?: unknown;
    lineIds?: unknown;
    productIds?: unknown;
  };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof body.slug === "string" ? body.slug.trim() : "";
  const brand = typeof body.brand === "string" ? body.brand.trim() : "";
  const supplierName =
    typeof body.supplierName === "string" && body.supplierName.trim()
      ? body.supplierName.trim()
      : brand;

  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 422 });
  }
  if (!brand) {
    return NextResponse.json({ hata: "Marka bilgisi belirtilmedi." }, { status: 422 });
  }

  const lineIds = extractUuidList(body.lineIds);
  const productIds = extractUuidList(body.productIds);
  if (lineIds === null || productIds === null) {
    return NextResponse.json({ hata: "Satır veya ürün kimlikleri geçersiz." }, { status: 422 });
  }
  if (lineIds.length === 0 && productIds.length === 0) {
    return NextResponse.json(
      { hata: "İzin istenecek en az bir satır veya ürün belirtilmelidir." },
      { status: 422 },
    );
  }
  if (lineIds.length > 200 || productIds.length > 200) {
    return NextResponse.json(
      { hata: "Tek seferde en fazla 200 kayıt için izin istenebilir." },
      { status: 422 },
    );
  }

  const headerEditToken =
    (request.headers.get("x-vixrex-edit-token") ?? "").trim() ||
    (typeof body.editToken === "string" ? body.editToken.trim() : "");

  const yetki = await sahipYetkisi(slug, headerEditToken);
  if (!yetki.tamam) {
    return NextResponse.json({ hata: yetki.hata }, { status: yetki.durum });
  }

  const admin = getSupabaseAdmin();
  let resolvedEditToken = headerEditToken;
  if (!resolvedEditToken) {
    const { data: storeRow } = await admin
      .from("stores")
      .select("edit_token")
      .eq("id", yetki.storeId)
      .maybeSingle();
    resolvedEditToken = typeof storeRow?.edit_token === "string" ? storeRow.edit_token : "";
  }
  if (!resolvedEditToken) {
    return NextResponse.json({ hata: "Vitrin yetkisi doğrulanamadı." }, { status: 401 });
  }

  const { data: token, error } = await admin.rpc("create_supplier_permission_request", {
    p_store_id: yetki.storeId,
    p_edit_token: resolvedEditToken,
    p_supplier_name: supplierName,
    p_brand: brand,
    p_line_ids: lineIds,
    p_product_ids: productIds,
  });

  if (error || typeof token !== "string" || !SUPPLIER_PERMISSION_TOKEN_RE.test(token)) {
    return NextResponse.json(
      { hata: "İzin talebi bağlantısı oluşturulamadı." },
      { status: 500 },
    );
  }

  return NextResponse.json(
    { token, url: `/izin-talebi/${token}` },
    { status: 201, headers: { "Cache-Control": "private, no-store" } },
  );
}

export async function GET(request: NextRequest) {
  const token = (request.nextUrl.searchParams.get("token") ?? "").trim().toLowerCase();
  if (!SUPPLIER_PERMISSION_TOKEN_RE.test(token)) {
    return NextResponse.json({ hata: "Geçersiz izin talebi bağlantısı." }, { status: 400 });
  }

  const data = await fetchSupplierPermissionRequest(token);
  if (!data) {
    return NextResponse.json(
      { hata: "İzin talebi bulunamadı veya süresi doldu." },
      { status: 404 },
    );
  }

  return NextResponse.json(data, {
    status: 200,
    headers: { "Cache-Control": "private, no-store" },
  });
}

export async function PUT(request: NextRequest) {
  let body: { token?: unknown };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const token = typeof body.token === "string" ? body.token.trim().toLowerCase() : "";
  if (!SUPPLIER_PERMISSION_TOKEN_RE.test(token)) {
    return NextResponse.json({ hata: "Geçersiz izin talebi bağlantısı." }, { status: 400 });
  }

  const { data, error } = await supabase.rpc("approve_supplier_permission_request", {
    p_token: token,
  });

  if (error || !data || typeof data !== "object") {
    return NextResponse.json(
      { hata: "İzin onayı işlenemedi." },
      { status: 500 },
    );
  }

  const result = data as {
    success?: boolean;
    error?: string;
    status?: string;
    already_approved?: boolean;
    updated_rights_count?: number;
  };

  if (!result.success) {
    if (result.error === "TOKEN_EXPIRED") {
      return NextResponse.json({ hata: "İzin talebinin süresi dolmuş." }, { status: 410 });
    }
    if (result.error === "REQUEST_REJECTED") {
      return NextResponse.json({ hata: "Bu izin talebi daha önce reddedilmiş." }, { status: 409 });
    }
    if (result.error === "INVALID_TOKEN" || result.error === "NOT_FOUND") {
      return NextResponse.json({ hata: "İzin talebi bulunamadı." }, { status: 404 });
    }
    return NextResponse.json({ hata: "İzin onayı tamamlanamadı." }, { status: 400 });
  }

  try {
    const admin = getSupabaseAdmin();
    const { data: talep } = await admin
      .from("supplier_permission_requests")
      .select("store_id")
      .eq("token", token)
      .maybeSingle();
    const storeId = typeof talep?.store_id === "string" ? talep.store_id : "";
    if (storeId) {
      const { data: magaza } = await admin
        .from("stores")
        .select("slug")
        .eq("id", storeId)
        .maybeSingle();
      const storeSlug = typeof magaza?.slug === "string" ? magaza.slug.trim() : "";
      if (storeSlug) {
        vitrinOnbelleginiYenile(storeSlug);
      }
    }
  } catch {
  }

  return NextResponse.json(
    {
      success: true,
      status: result.status ?? "onaylandi",
      alreadyApproved: Boolean(result.already_approved),
      updatedRightsCount: Number(result.updated_rights_count ?? 0),
    },
    { status: 200, headers: { "Cache-Control": "private, no-store" } },
  );
}
