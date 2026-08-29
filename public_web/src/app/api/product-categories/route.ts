import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

export const dynamic = "force-dynamic";

// POST: yeni kategori oluştur { slug, name }
export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try { govde = await request.json(); } catch { return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 }); }
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const name = typeof govde.name === "string" ? govde.name.trim() : "";
  if (!slug || !name) return NextResponse.json({ hata: "Vitrin ve kategori adı zorunludur." }, { status: 422 });
  if (name.length > 40) return NextResponse.json({ hata: "Kategori adı en fazla 40 karakter." }, { status: 422 });

  const cookieStore = await cookies();
  const ownerSession = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);
  if (!ownerSession) return NextResponse.json({ hata: "Oturumun geçersiz." }, { status: 401 });

  const admin = getSupabaseAdmin();
  const { data: store } = await admin.from("stores").select("id, edit_token").eq("id", ownerSession.storeId).single();
  if (!store?.edit_token) return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });

  // duplicate check
  const { data: existing } = await admin.from("product_categories").select("id").eq("store_id", store.id).ilike("name", name).maybeSingle();
  if (existing) return NextResponse.json({ hata: "Bu kategori zaten mevcut." }, { status: 409 });

  const { data, error } = await admin.rpc("upsert_store_category", {
    p_store_id: store.id,
    p_edit_token: store.edit_token,
    p_name: name,
  });
  if (error || !data?.id) {
    return NextResponse.json({ hata: "Kategori oluşturulamadı." }, { status: 500 });
  }
  return NextResponse.json({ tamam: true, id: data.id, name });
}

// PATCH: yeniden adlandır veya sırala
// body: { slug, categoryId, name }  -> rename
// body: { slug, categoryIds: string[] } -> reorder
export async function PATCH(request: NextRequest) {
  let govde: Record<string, unknown>;
  try { govde = await request.json(); } catch { return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 }); }
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!slug) return NextResponse.json({ hata: "Vitrin zorunludur." }, { status: 422 });

  const cookieStore = await cookies();
  const ownerSession = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);
  if (!ownerSession) return NextResponse.json({ hata: "Oturumun geçersiz." }, { status: 401 });

  const admin = getSupabaseAdmin();
  const { data: store } = await admin.from("stores").select("id, edit_token").eq("id", ownerSession.storeId).single();
  if (!store?.id) return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });

  // Reorder branch
  if (Array.isArray(govde.categoryIds)) {
    const ids = (govde.categoryIds as unknown[]).filter((v) => typeof v === "string" && (v as string).trim()).map((v) => (v as string).trim());
    for (let i = 0; i < ids.length; i++) {
      const { error } = await admin.from("product_categories").update({ sort_order: i }).eq("id", ids[i]).eq("store_id", store.id);
      if (error) return NextResponse.json({ hata: "Sıralama güncellenemedi." }, { status: 500 });
    }
    return NextResponse.json({ tamam: true });
  }

  const categoryId = typeof govde.categoryId === "string" ? govde.categoryId.trim() : "";
  const name = typeof govde.name === "string" ? govde.name.trim() : "";
  if (!categoryId || !name) return NextResponse.json({ hata: "Kategori ID ve adı zorunludur." }, { status: 422 });
  if (name.length > 40) return NextResponse.json({ hata: "Kategori adı en fazla 40 karakter." }, { status: 422 });

  const { data: dup } = await admin.from("product_categories").select("id").eq("store_id", store.id).ilike("name", name).neq("id", categoryId).maybeSingle();
  if (dup) return NextResponse.json({ hata: "Bu kategori zaten mevcut." }, { status: 409 });

  const { error } = await admin.from("product_categories").update({ name }).eq("id", categoryId).eq("store_id", store.id);
  if (error) return NextResponse.json({ hata: "Kategori güncellenemedi." }, { status: 500 });
  return NextResponse.json({ tamam: true });
}

// DELETE: { slug, categoryId, replacementId }
export async function DELETE(request: NextRequest) {
  let govde: Record<string, unknown>;
  try { govde = await request.json(); } catch { return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 }); }
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const categoryId = typeof govde.categoryId === "string" ? govde.categoryId.trim() : "";
  const replacementId = typeof govde.replacementId === "string" ? govde.replacementId.trim() : "";
  if (!slug || !categoryId) return NextResponse.json({ hata: "Vitrin ve kategori zorunludur." }, { status: 422 });

  const cookieStore = await cookies();
  const ownerSession = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);
  if (!ownerSession) return NextResponse.json({ hata: "Oturumun geçersiz." }, { status: 401 });

  const admin = getSupabaseAdmin();
  const { data: store } = await admin.from("stores").select("id").eq("id", ownerSession.storeId).single();
  if (!store?.id) return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });

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
