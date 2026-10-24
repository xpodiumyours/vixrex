import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { supabase } from "@/lib/supabase";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

export const dynamic = "force-dynamic";

/**
 * /app için dar sahiplik köprüsü.
 *
 * Hesaba bağlı store bulunamadığında tarayıcıda geçerli bir HttpOnly
 * vixrex_owner_session olabilir (örn. kiralık/misafir vitrin). İstemci bu
 * çerezi okuyamaz; bu rota yalnız imzalı çerezi doğrular, aynı session-token
 * ile mevcut working_draft + katalog RPC'lerini okur ve tokenı ASLA dönmez.
 */
function cookieSlugHint(token: string): string {
  const separatorIndex = token.indexOf(".");
  if (separatorIndex <= 0) return "";
  try {
    const payload = JSON.parse(
      Buffer.from(token.slice(0, separatorIndex), "base64url").toString("utf8")
    ) as { slug?: unknown };
    return typeof payload.slug === "string" ? payload.slug.trim() : "";
  } catch {
    return "";
  }
}

export async function GET() {
  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  if (!ownerSessionCookie) {
    return NextResponse.json({ tamam: false, sebep: "NO_OWNER_SESSION" }, {
      status: 404,
      headers: { "cache-control": "no-store" },
    });
  }

  // Slug ipucu güvenilir kabul edilmez; yalnız mevcut doğrulayıcıya beklenen
  // slug olarak verilir. HMAC, süre ve sessionToken biçimi verifyOwnerSession
  // içinde yeniden doğrulanır.
  const hintedSlug = cookieSlugHint(ownerSessionCookie);
  const ownerSession = hintedSlug
    ? verifyOwnerSession(ownerSessionCookie, hintedSlug)
    : null;

  if (!ownerSession) {
    return NextResponse.json({ tamam: false, sebep: "INVALID_OWNER_SESSION" }, {
      status: 401,
      headers: { "cache-control": "no-store" },
    });
  }

  const { data: draftData, error: draftError } = await supabase.rpc(
    "get_working_draft_for_session",
    { p_session_token: ownerSession.sessionToken }
  );

  if (draftError || !draftData) {
    if (draftError?.message === "INVALID_SESSION_TOKEN") {
      return NextResponse.json({ tamam: false, sebep: "INVALID_OWNER_SESSION" }, {
        status: 401,
        headers: { "cache-control": "no-store" },
      });
    }
    console.error(
      "[owner-workspace/current] working draft okunamadı",
      draftError?.message ?? "NO_DRAFT"
    );
    return NextResponse.json({ tamam: false, sebep: "DRAFT_UNAVAILABLE" }, {
      status: 409,
      headers: { "cache-control": "no-store" },
    });
  }

  const draft = draftData as {
    store_id?: unknown;
    slug?: unknown;
    draft_data?: Record<string, unknown> | null;
    draft_version?: unknown;
    base_live_version?: unknown;
  };
  const slug = typeof draft.slug === "string" ? draft.slug.trim() : "";
  if (!slug || slug !== ownerSession.slug) {
    return NextResponse.json({ tamam: false, sebep: "SLUG_MISMATCH" }, {
      status: 409,
      headers: { "cache-control": "no-store" },
    });
  }

  const storeId = typeof draft.store_id === "string" ? draft.store_id : "";
  if (!storeId || storeId !== ownerSession.storeId) {
    return NextResponse.json({ tamam: false, sebep: "STORE_MISMATCH" }, {
      status: 409,
      headers: { "cache-control": "no-store" },
    });
  }

  let store: Record<string, unknown>;
  try {
    const { data, error } = await getSupabaseAdmin()
      .from("stores")
      .select("id, slug, name, is_published, kategori, business_type, updated_at, products(id, slug, name, description, price_text, price_amount, currency, image_urls, category_id, stock_status, stock_quantity, brand, barcode, metadata, variants, old_price_amount, badge_tag, fulfillment_region, is_visible, source_type, product_categories(name, product_template_key)), product_categories(id, name, product_template_key)")
      .eq("id", storeId)
      .eq("slug", slug)
      .maybeSingle();

    if (error) throw new Error("WORKSPACE_UNAVAILABLE");
    if (!data) {
      return NextResponse.json({ tamam: false, sebep: "STORE_NOT_FOUND" }, {
        status: 404,
        headers: { "cache-control": "no-store" },
      });
    }
    store = data as unknown as Record<string, unknown>;
  } catch {
    return NextResponse.json({ tamam: false, sebep: "WORKSPACE_UNAVAILABLE" }, {
      status: 503,
      headers: { "cache-control": "no-store" },
    });
  }

  const workingDraft = draft.draft_data ?? {};
  const products = Array.isArray(store.products) ? store.products : [];
  const categories = Array.isArray(store.product_categories) ? store.product_categories : [];

  return NextResponse.json(
    {
      tamam: true,
      store: {
        id: storeId,
        slug,
        name: String(store.name ?? ""),
        is_published: store.is_published === true,
        kategori:
          typeof store.kategori === "string" ? store.kategori : null,
        business_type:
          typeof store.business_type === "string" ? store.business_type : null,
        updated_at:
          typeof store.updated_at === "string" ? store.updated_at : null,
        products,
        product_categories: categories,
      },
      working_draft: {
        draft_data: workingDraft,
        draft_version: draft.draft_version ?? null,
        base_live_version: draft.base_live_version ?? null,
      },
    },
    {
      headers: { "cache-control": "private, no-store" },
    }
  );
}
