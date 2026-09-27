import { NextResponse, type NextRequest } from "next/server";
import { revalidateTag } from "next/cache";
import { sahipDogrula } from "@/lib/ownerGuard";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { blogSeoAnalizi, blogYayinEngelleri, type BlogSeoInput } from "@/lib/blogSeo";
import { blogSlugUret } from "@/lib/blogSlug";

/**
 * Blog yazı CRUD API'si — owner session ile korunuyor.
 *
 * POST: Yeni yazı oluştur
 * PATCH: Yazıyı güncelle
 * DELETE: Yazıyı sil
 *
 * Flutter'daki ArticleService ile aynı Supabase tablosunu kullanır.
 * RLS: store_articles tablosunda owner kontrolü store_slug üzerinden yapılır.
 *
 * SEO puanı ve öneriler SUNUCUDA hesaplanır; istemciden gelen seoScore /
 * seoErrors yok sayılır. Aksi hâlde puanı tarayıcı belirler ve saklanan
 * "standart" hiçbir şeyi ölçmez.
 */

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const url = new URL(request.url);
  const slug = url.searchParams.get("slug")?.trim() ?? "";
  const articleSlug = url.searchParams.get("articleSlug")?.trim() ?? "";
  if (!slug) {
    return NextResponse.json(
      { hata: "Vitrin belirtilmedi." },
      { status: 400 }
    );
  }

  const auth = await sahipDogrula(slug);
  if (!auth.ok) {
    return NextResponse.json({ hata: auth.error }, { status: 401 });
  }

  const admin = getSupabaseAdmin();

  if (articleSlug) {
    const { data, error } = await admin
      .from("store_articles")
      .select(
        "id, store_slug, title, slug, summary, content, cover_image_url, article_type, target_topic, target_city, seo_score, seo_errors, status, published_at, created_at, updated_at"
      )
      .eq("store_slug", slug)
      .eq("slug", articleSlug)
      .maybeSingle();

    if (error) {
      console.error("[articles] detail failed:", error.message);
      return NextResponse.json(
        { hata: "Yazı getirilemedi." },
        { status: 500 }
      );
    }
    if (!data) {
      return NextResponse.json({ hata: "Yazı bulunamadı." }, { status: 404 });
    }

    return NextResponse.json({ tamam: true, yazi: data });
  }

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

const SEO_ALANLARI =
  "title, summary, content, cover_image_url, target_topic, target_city";

function seoGirdisi(alanlar: {
  title?: unknown;
  summary?: unknown;
  content?: unknown;
  cover_image_url?: unknown;
  target_topic?: unknown;
  target_city?: unknown;
}): BlogSeoInput {
  const metin = (deger: unknown) => (typeof deger === "string" ? deger : "");
  return {
    title: metin(alanlar.title),
    summary: metin(alanlar.summary),
    content: metin(alanlar.content),
    topic: metin(alanlar.target_topic),
    city: metin(alanlar.target_city),
    hasCover: metin(alanlar.cover_image_url).length > 0,
  };
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

  const auth = await sahipDogrula(slug);
  if (!auth.ok) {
    return NextResponse.json({ hata: auth.error }, { status: 401 });
  }

  const admin = getSupabaseAdmin();

  // Slug çakışmasını önle
  let articleSlug = blogSlugUret(title);
  const { data: existing } = await admin
    .from("store_articles")
    .select("id")
    .eq("store_slug", slug)
    .eq("slug", articleSlug)
    .maybeSingle();
  if (existing) {
    articleSlug = `${articleSlug}-${Date.now().toString(36)}`;
  }

  const alanlar = {
    title,
    summary: typeof govde.summary === "string" ? govde.summary.trim() : "",
    content: typeof govde.content === "string" ? govde.content.trim() : "",
    cover_image_url:
      typeof govde.coverImageUrl === "string" ? govde.coverImageUrl.trim() : "",
    target_topic: typeof govde.targetTopic === "string" ? govde.targetTopic.trim() : "",
    target_city: typeof govde.targetCity === "string" ? govde.targetCity.trim() : "",
  };
  const analiz = blogSeoAnalizi(seoGirdisi(alanlar));

  const payload = {
    store_slug: slug,
    title,
    summary: alanlar.summary,
    content: alanlar.content,
    cover_image_url: alanlar.cover_image_url || null,
    article_type: typeof govde.articleType === "string" ? govde.articleType : "standard",
    target_topic: alanlar.target_topic,
    target_city: alanlar.target_city,
    seo_score: analiz.score,
    seo_errors: analiz.recommendations,
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
  const articleSlug =
    typeof govde.articleSlug === "string" ? govde.articleSlug.trim() : "";
  // Alan adı üç API'de aynı: `slug`. Burada `storeSlug` yazıyordu —
  // aynı kavramın iki farklı adı arayüzü yazan kişiyi yanıltır.
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!articleId || !slug) {
    return NextResponse.json(
      { hata: "Yazı ID ve vitrin zorunludur." },
      { status: 422 }
    );
  }

  const auth = await sahipDogrula(slug);
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
  if (typeof govde.status === "string") {
    const status = govde.status.trim();
    if (status !== "draft" && status !== "published") {
      return NextResponse.json(
        { hata: "Yazı yalnız taslak veya yayında olabilir." },
        { status: 422 }
      );
    }
    updatePayload.status = status;
  }

  if (Object.keys(updatePayload).length === 0) {
    return NextResponse.json({ hata: "Güncellenecek alan belirtilmedi." }, { status: 422 });
  }

  const { data: mevcut, error: okumaHatasi } = await admin
    .from("store_articles")
    .select(SEO_ALANLARI)
    .eq("id", articleId)
    .eq("store_slug", slug)
    .maybeSingle();
  if (okumaHatasi) {
    console.error("[articles] score read failed:", okumaHatasi.message);
    return NextResponse.json({ hata: "Yazı doğrulanamadı." }, { status: 500 });
  }
  if (!mevcut) {
    return NextResponse.json({ hata: "Yazı bulunamadı." }, { status: 404 });
  }

  const birlestir = (alan: keyof typeof mevcut) =>
    typeof updatePayload[alan] === "string"
      ? (updatePayload[alan] as string)
      : ((mevcut[alan] ?? "") as string);
  const girdi = seoGirdisi({
    title: birlestir("title"),
    summary: birlestir("summary"),
    content: birlestir("content"),
    cover_image_url: birlestir("cover_image_url"),
    target_topic: birlestir("target_topic"),
    target_city: birlestir("target_city"),
  });
  const analiz = blogSeoAnalizi(girdi);
  updatePayload.seo_score = analiz.score;
  updatePayload.seo_errors = analiz.recommendations;

  if (updatePayload.status === "published") {
    const engeller = blogYayinEngelleri(girdi);
    if (engeller.length) {
      return NextResponse.json(
        {
          hata: `Yayın standardı tamamlanmadı. ${engeller.join(" ")}`,
          engeller,
          seoScore: analiz.score,
        },
        { status: 422 }
      );
    }
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

  if (typeof updatePayload.status === "string") {
    revalidateTag(`store-${slug}`, { expire: 0 });
    if (articleSlug) {
      revalidateTag(`article-${slug}-${articleSlug}`, { expire: 0 });
    }
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

  const auth = await sahipDogrula(slug);
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
