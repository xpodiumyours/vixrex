import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { supabase } from "@/lib/supabase";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";

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

  const [{ data: draftData, error: draftError }, { data: catalogData, error: catalogError }] =
    await Promise.all([
      supabase.rpc("get_working_draft_for_session", {
        p_session_token: ownerSession.sessionToken,
      }),
      supabase.rpc("get_owner_catalog_for_session", {
        p_session_token: ownerSession.sessionToken,
      }),
    ]);

  if (draftError || !draftData) {
    console.error(
      "[owner-workspace/current] working draft okunamadı",
      draftError?.message ?? "NO_DRAFT"
    );
    return NextResponse.json({ tamam: false, sebep: "DRAFT_UNAVAILABLE" }, {
      status: 409,
      headers: { "cache-control": "no-store" },
    });
  }

  if (catalogError) {
    console.error(
      "[owner-workspace/current] katalog okunamadı",
      catalogError.message
    );
  }

  const draft = draftData as {
    store_id?: unknown;
    slug?: unknown;
    draft_data?: Record<string, unknown> | null;
    draft_version?: unknown;
    base_live_version?: unknown;
  };
  const catalog = (catalogData ?? {}) as {
    products?: unknown;
    categories?: unknown;
  };
  const slug = typeof draft.slug === "string" ? draft.slug.trim() : "";
  if (!slug || slug !== ownerSession.slug) {
    return NextResponse.json({ tamam: false, sebep: "SLUG_MISMATCH" }, {
      status: 409,
      headers: { "cache-control": "no-store" },
    });
  }

  const workingDraft = draft.draft_data ?? {};
  const products = Array.isArray(catalog.products) ? catalog.products : [];
  const categories = Array.isArray(catalog.categories) ? catalog.categories : [];

  return NextResponse.json(
    {
      tamam: true,
      store: {
        id: String(draft.store_id ?? ownerSession.storeId),
        slug,
        name: String(workingDraft.name ?? ""),
        is_published: Boolean(workingDraft.is_published),
        kategori:
          typeof workingDraft.kategori === "string" ? workingDraft.kategori : null,
        updated_at:
          typeof workingDraft.updated_at === "string" ? workingDraft.updated_at : null,
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
