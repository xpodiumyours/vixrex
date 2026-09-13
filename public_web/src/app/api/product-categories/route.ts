import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { PRODUCT_TEMPLATE_BY_KEY } from "@/lib/productAttributeSchema";

export const dynamic = "force-dynamic";

function templateKeyFrom(value: unknown) {
  const key = typeof value === "string" ? value.trim() : "";
  if (!key) return "generic";
  return PRODUCT_TEMPLATE_BY_KEY.has(key) ? key : null;
}

async function ownerStore(slug: string) {
  const cookieStore = await cookies();
  const ownerSession = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);
  if (!ownerSession) return null;
  const admin = getSupabaseAdmin();
  const { data: store } = await admin
    .from("stores")
    .select("id, edit_token")
    .eq("id", ownerSession.storeId)
    .single();
  if (!store?.id) return null;
  return { admin, store };
}

export async function GET(request: NextRequest) {
  const slug = request.nextUrl.searchParams.get("slug")?.trim() || "";
  if (!slug) return NextResponse.json({ hata: "Vitrin zorunludur." }, { status: 422 });

  const owned = await ownerStore(slug);
  if (!owned) return NextResponse.json({ hata: "Oturumun geçersiz." }, { status: 401 });
  const { admin, store } = owned;

  const rich = await admin
    .from("product_categories")
    .select("id,name,sort_order,product_template_key")
    .eq("store_id", store.id)
    .eq("is_active", true)
    .order("sort_order");

  if (!rich.error) {
    return NextResponse.json({
      tamam: true,
      categories: (rich.data || []).map((item) => ({
        ...item,
        product_template_key: templateKeyFrom(item.product_template_key) || "generic",
      })),
    });
  }

  // Migration henüz uygulanmamış preview ortamlarında mevcut kategori ekranı
  // çalışmaya devam eder; isimden ürün tipi tahmini yapılmaz, generic döner.
  const legacy = await admin
    .from("product_categories")
    .select("id,name,sort_order")
    .eq("store_id", store.id)
    .eq("is_active", true)
    .order("sort_order");
  if (legacy.error) {
    return NextResponse.json({ hata: "Kategoriler yüklenemedi." }, { status: 500 });
  }
  return NextResponse.json({
    tamam: true,
    categories: (legacy.data || []).map((item) => ({
      ...item,
      product_template_key: "generic",
    })),
  });
}

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try { govde = await request.json(); } catch { return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 }); }
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const name = typeof govde.name === "string" ? govde.name.trim() : "";
  const templateKey = templateKeyFrom(govde.templateKey);
  if (!slug || !name) return NextResponse.json({ hata: "Vitrin ve kategori adı zorunludur." }, { status: 422 });
  if (!templateKey) return NextResponse.json({ hata: "Ürün tipi geçersiz." }, { status: 422 });
  if (name.length > 40) return NextResponse.json({ hata: "Kategori adı en fazla 40 karakter." }, { status: 422 });

  const owned = await ownerStore(slug);
  if (!owned?.store.edit_token) return NextResponse.json({ hata: "Oturumun geçersiz." }, { status: 401 });
  const { admin, store } = owned;

  const { data: existing } = await admin.from("product_categories").select("id").eq("store_id", store.id).ilike("name", name).maybeSingle();
  if (existing) return NextResponse.json({ hata: "Bu kategori zaten mevcut." }, { status: 409 });

  const { data, error } = await admin.rpc("upsert_store_category_v2", {
    p_store_id: store.id,
    p_edit_token: store.edit_token,
    p_name: name,
    p_template_key: templateKey,
  });
  if (error || !data?.id) {
    return NextResponse.json({ hata: "Kategori oluşturulamadı." }, { status: 500 });
  }
  return NextResponse.json({ tamam: true, id: data.id, name, product_template_key: templateKey });
}

export async function PATCH(request: NextRequest) {
  let govde: Record<string, unknown>;
  try { govde = await request.json(); } catch { return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 }); }
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!slug) return NextResponse.json({ hata: "Vitrin zorunludur." }, { status: 422 });

  const owned = await ownerStore(slug);
  if (!owned?.store.edit_token) return NextResponse.json({ hata: "Oturumun geçersiz." }, { status: 401 });
  const { admin, store } = owned;

  if (Array.isArray(govde.categoryIds)) {
    const ids = (govde.categoryIds as unknown[]).filter((v) => typeof v === "string" && (v as string).trim()).map((v) => (v as string).trim());
    for (let i = 0; i < ids.length; i++) {
      const { error } = await admin.rpc("update_store_category_v2", {
        p_category_id: ids[i],
        p_edit_token: store.edit_token,
        p_sort_order: i,
      });
      if (error) return NextResponse.json({ hata: "Sıralama güncellenemedi." }, { status: 500 });
    }
    return NextResponse.json({ tamam: true });
  }

  const categoryId = typeof govde.categoryId === "string" ? govde.categoryId.trim() : "";
  const hasName = typeof govde.name === "string";
  const name = hasName ? (govde.name as string).trim() : "";
  const hasTemplateKey = typeof govde.templateKey === "string";
  const templateKey = hasTemplateKey ? templateKeyFrom(govde.templateKey) : undefined;
  if (!categoryId || (!hasName && !hasTemplateKey)) {
    return NextResponse.json({ hata: "Kategori ve değişiklik zorunludur." }, { status: 422 });
  }
  if (hasName && !name) return NextResponse.json({ hata: "Kategori adı zorunludur." }, { status: 422 });
  if (hasName && name.length > 40) return NextResponse.json({ hata: "Kategori adı en fazla 40 karakter." }, { status: 422 });
  if (hasTemplateKey && !templateKey) return NextResponse.json({ hata: "Ürün tipi geçersiz." }, { status: 422 });

  if (hasName) {
    const { data: dup } = await admin.from("product_categories").select("id").eq("store_id", store.id).ilike("name", name).neq("id", categoryId).maybeSingle();
    if (dup) return NextResponse.json({ hata: "Bu kategori zaten mevcut." }, { status: 409 });
  }

  const { error } = await admin.rpc("update_store_category_v2", {
    p_category_id: categoryId,
    p_edit_token: store.edit_token,
    ...(hasName ? { p_name: name } : {}),
    ...(hasTemplateKey ? { p_template_key: templateKey } : {}),
  });
  if (error) return NextResponse.json({ hata: "Kategori güncellenemedi." }, { status: 500 });
  return NextResponse.json({ tamam: true });
}

export async function DELETE(request: NextRequest) {
  let govde: Record<string, unknown>;
  try { govde = await request.json(); } catch { return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 }); }
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const categoryId = typeof govde.categoryId === "string" ? govde.categoryId.trim() : "";
  const replacementId = typeof govde.replacementId === "string" ? govde.replacementId.trim() : "";
  if (!slug || !categoryId) return NextResponse.json({ hata: "Vitrin ve kategori zorunludur." }, { status: 422 });

  const owned = await ownerStore(slug);
  if (!owned) return NextResponse.json({ hata: "Oturumun geçersiz." }, { status: 401 });
  const { admin, store } = owned;

  const { data: all } = await admin.from("product_categories").select("id").eq("store_id", store.id);
  if (!all || all.length <= 1) return NextResponse.json({ hata: "En az bir kategori kalmalı." }, { status: 422 });

  if (replacementId) {
    const { error: moveErr } = await admin.from("products").update({ category_id: replacementId }).eq("store_id", store.id).eq("category_id", categoryId);
    if (moveErr) return NextResponse.json({ hata: "Ürünler taşınamadı." }, { status: 500 });
  } else {
    const { error: clearErr } = await admin.from("products").update({ category_id: null }).eq("store_id", store.id).eq("category_id", categoryId);
    if (clearErr) return NextResponse.json({ hata: "Ürünler temizlenemedi." }, { status: 500 });
  }

  const { error } = await admin.from("product_categories").delete().eq("id", categoryId).eq("store_id", store.id);
  if (error) return NextResponse.json({ hata: "Kategori silinemedi." }, { status: 500 });
  return NextResponse.json({ tamam: true });
}
