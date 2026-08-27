import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

/**
 * Blog yazı CRUD API'si — owner session ile korunuyor.
 *
 * POST: Yeni yazı oluştur
 * PATCH: Yazıyı güncelle
 * DELETE: Yazıyı sil
 *
 * Flutter'daki ArticleService ile aynı Supabase tablosunu kullanır.
 * RLS: store_articles tablosunda owner kontrolü store_slug üzerinden yapılır.
 */

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const url = new URL(request.url);
  const slug = url.searchParams.get("slug")?.trim() ?? "";
  if (!slug) {
    return NextResponse.json(
      { hata: "Vitrin belirtilmedi." },
      { status: 400 }
    );
  }

  const auth = await verifyOwner(slug);
  if (!auth.ok) {
    return NextResponse.json({ hata: auth.error }, { status: 401 });
  }

  const admin = getSupabaseAdmin();

  const { data, error } = await admin
    .from("store_articles")
    .select(
      "id, title, slug, summary, status, article_type, seo_score, cover_image_url, created_at, updated_at, published_at"
    )
    .eq("store_slug", slug)
    .order("created_at", { ascending: false });

  if (error) {
    console.error("[articles] list failed:", error.message);
    return NextResponse.json(
      { hata: "Yazılar getirilemedi." },
      { status: 500 }
    );
  }

  return NextResponse.json({ tamam: true, yaziListesi: data ?? [] });
}

function generateArticleSlug(title: string): string {
  return title
    .toLowerCase()
    .replace(/[çğıöşü]/g, (c) =>
      ({ ç: "c", ğ: "g", ı: "i", ö: "o", ş: "s", ü: "u" }[c] ?? c)
    )
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 60);
}

async function verifyOwner(slug: string): Promise<{ ok: boolean; error?: string }> {
  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);
  if (!ownerSession) {
    return { ok: false, error: "Oturumun geçersiz veya süresi dolmuş." };
  }
  return { ok: true };
}

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  // Alan adı üç API'de aynı: `slug`. Burada `storeSlug` yazıyordu —
  // aynı kavramın iki farklı adı arayüzü yazan kişiyi yanıltır.
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const title = typeof govde.title === "string" ? govde.title.trim() : "";
  if (!slug || !title) {
    return NextResponse.json(
      { hata: "Vitrin ve başlık zorunludur." },
      { status: 422 }
    );
  }

  const auth = await verifyOwner(slug);
  if (!auth.ok) {
    return NextResponse.json({ hata: auth.error }, { status: 401 });
  }

  const admin = getSupabaseAdmin();

  // Slug çakışmasını önle
  let articleSlug = generateArticleSlug(title);
  const { data: existing } = await admin
    .from("store_articles")
    .select("id")
    .eq("store_slug", slug)
    .eq("slug", articleSlug)
    .maybeSingle();
  if (existing) {
    articleSlug = `${articleSlug}-${Date.now().toString(36)}`;
  }

  const payload = {
    store_slug: slug,
    title,
    summary: typeof govde.summary === "string" ? govde.summary.trim() : "",
    content: typeof govde.content === "string" ? govde.content.trim() : "",
    cover_image_url: typeof govde.coverImageUrl === "string" ? govde.coverImageUrl.trim() : null,
    article_type: typeof govde.articleType === "string" ? govde.articleType : "standard",
    target_topic: typeof govde.targetTopic === "string" ? govde.targetTopic.trim() : "",
    target_city: typeof govde.targetCity === "string" ? govde.targetCity.trim() : "",
    seo_score: typeof govde.seoScore === "number" ? govde.seoScore : 0,
    seo_errors: Array.isArray(govde.seoErrors) ? govde.seoErrors : [],
    status: "draft",
    slug: articleSlug,
  };

  const { error } = await admin.from("store_articles").insert(payload);
  if (error) {
    console.error("[articles] create failed:", error.message);
    return NextResponse.json(
      { hata: "Yazı oluşturulamadı." },
      { status: 500 }
    );
  }

  return NextResponse.json({ tamam: true, slug: articleSlug });
}

export async function PATCH(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const articleId = typeof govde.articleId === "string" ? govde.articleId.trim() : "";
  // Alan adı üç API'de aynı: `slug`. Burada `storeSlug` yazıyordu —
  // aynı kavramın iki farklı adı arayüzü yazan kişiyi yanıltır.
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!articleId || !slug) {
    return NextResponse.json(
      { hata: "Yazı ID ve vitrin zorunludur." },
      { status: 422 }
    );
  }

  const auth = await verifyOwner(slug);
  if (!auth.ok) {
    return NextResponse.json({ hata: auth.error }, { status: 401 });
  }

  const admin = getSupabaseAdmin();

  const updatePayload: Record<string, unknown> = {};
  if (typeof govde.title === "string") updatePayload.title = govde.title.trim();
  if (typeof govde.summary === "string") updatePayload.summary = govde.summary.trim();
  if (typeof govde.content === "string") updatePayload.content = govde.content.trim();
  if (typeof govde.coverImageUrl === "string") updatePayload.cover_image_url = govde.coverImageUrl.trim();
  if (typeof govde.articleType === "string") updatePayload.article_type = govde.articleType;
  if (typeof govde.targetTopic === "string") updatePayload.target_topic = govde.targetTopic.trim();
  if (typeof govde.targetCity === "string") updatePayload.target_city = govde.targetCity.trim();
  if (typeof govde.seoScore === "number") updatePayload.seo_score = govde.seoScore;
  if (Array.isArray(govde.seoErrors)) updatePayload.seo_errors = govde.seoErrors;
  if (typeof govde.status === "string") updatePayload.status = govde.status;

  if (Object.keys(updatePayload).length === 0) {
    return NextResponse.json({ hata: "Güncellenecek alan belirtilmedi." }, { status: 422 });
  }

  const { error } = await admin
    .from("store_articles")
    .update(updatePayload)
    .eq("id", articleId)
    .eq("store_slug", slug);

  if (error) {
    console.error("[articles] update failed:", error.message);
    return NextResponse.json(
      { hata: "Yazı güncellenemedi." },
      { status: 500 }
    );
  }

  return NextResponse.json({ tamam: true });
}

export async function DELETE(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const articleId = typeof govde.articleId === "string" ? govde.articleId.trim() : "";
  // Alan adı üç API'de aynı: `slug`. Burada `storeSlug` yazıyordu —
  // aynı kavramın iki farklı adı arayüzü yazan kişiyi yanıltır.
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!articleId || !slug) {
    return NextResponse.json(
      { hata: "Yazı ID ve vitrin zorunludur." },
      { status: 422 }
    );
  }

  const auth = await verifyOwner(slug);
  if (!auth.ok) {
    return NextResponse.json({ hata: auth.error }, { status: 401 });
  }

  const admin = getSupabaseAdmin();

  const { error } = await admin
    .from("store_articles")
    .delete()
    .eq("id", articleId)
    .eq("store_slug", slug);

  if (error) {
    console.error("[articles] delete failed:", error.message);
    return NextResponse.json(
      { hata: "Yazı silinemedi." },
      { status: 500 }
    );
  }

  return NextResponse.json({ tamam: true });
}
