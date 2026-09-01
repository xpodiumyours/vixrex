import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import {
  OWNER_SESSION_COOKIE,
  verifyOwnerSessionCookie,
} from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { PUBLIC_STORE_SELECT } from "@/lib/publicStoreSelect";

export const dynamic = "force-dynamic";

export async function GET() {
  const cookieStore = await cookies();
  const ownerSession = verifyOwnerSessionCookie(
    cookieStore.get(OWNER_SESSION_COOKIE)?.value
  );

  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Sahip oturumu bulunamadı veya süresi dolmuş." },
      { status: 401, headers: { "cache-control": "no-store" } }
    );
  }

  const admin = getSupabaseAdmin();
  const { data: workingDraft, error: draftError } = await admin.rpc(
    "get_working_draft_for_session",
    { p_session_token: ownerSession.sessionToken }
  );

  if (draftError || !workingDraft) {
    console.error(
      "[owner-dashboard] working draft failed:",
      draftError?.message ?? "INVALID_SESSION_TOKEN"
    );
    return NextResponse.json(
      { hata: "Sahip oturumu geçersiz veya süresi dolmuş." },
      { status: 401, headers: { "cache-control": "no-store" } }
    );
  }

  const [storeResult, productsResult, categoriesResult] = await Promise.all([
    admin
      .from("stores")
      .select(`${PUBLIC_STORE_SELECT},updated_at`)
      .eq("id", ownerSession.storeId)
      .eq("slug", ownerSession.slug)
      .maybeSingle(),
    admin
      .from("products")
      .select(
        "id, slug, name, description, price_text, image_urls, category_id, stock_status, product_categories(name)"
      )
      .eq("store_id", ownerSession.storeId),
    admin
      .from("product_categories")
      .select("id, name")
      .eq("store_id", ownerSession.storeId),
  ]);

  if (
    storeResult.error ||
    !storeResult.data ||
    productsResult.error ||
    categoriesResult.error
  ) {
    console.error(
      "[owner-dashboard] store bundle failed:",
      storeResult.error?.message ??
        productsResult.error?.message ??
        categoriesResult.error?.message ??
        "STORE_NOT_FOUND"
    );
    return NextResponse.json(
      { hata: "Vitrin bilgileri yüklenemedi." },
      { status: 500, headers: { "cache-control": "no-store" } }
    );
  }

  const draftData =
    typeof workingDraft === "object" &&
    workingDraft !== null &&
    "draft_data" in workingDraft
      ? (workingDraft as { draft_data?: Record<string, unknown> }).draft_data
      : null;

  return NextResponse.json(
    {
      store: {
        ...storeResult.data,
        products: productsResult.data ?? [],
        product_categories: categoriesResult.data ?? [],
      },
      workingDraft: draftData ?? storeResult.data,
    },
    { headers: { "cache-control": "no-store" } }
  );
}
