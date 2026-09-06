import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { smartEngineBlogServerEnabled } from "@/lib/smartEngineFlagsServer";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

export const dynamic = "force-dynamic";

const LIMIT = 3;

interface LibraryArticle {
  id: string;
  title: string;
  slug: string;
  summary: string | null;
  primary_topic: string | null;
  purpose: string | null;
  tags: string[] | null;
  published_at: string | null;
}

function normalize(input: string): string {
  return input
    .toLocaleLowerCase("tr-TR")
    .replace(/[ıİ]/g, "i")
    .replace(/[şŞ]/g, "s")
    .replace(/[ğĞ]/g, "g")
    .replace(/[üÜ]/g, "u")
    .replace(/[öÖ]/g, "o")
    .replace(/[çÇ]/g, "c")
    .replace(/[^a-z0-9]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function queryTokens(query: string): string[] {
  const stop = new Set(["hakkinda", "icin", "ile", "ve", "bir", "nasil"]);
  return normalize(query)
    .split(" ")
    .filter((token) => token.length >= 3 && !stop.has(token));
}

function articleScore(article: LibraryArticle, tokens: readonly string[]): number {
  if (tokens.length === 0) return 1;
  const title = normalize(article.title);
  const topic = normalize(article.primary_topic ?? "");
  const purpose = normalize(article.purpose ?? "");
  const summary = normalize(article.summary ?? "");
  const tags = normalize((article.tags ?? []).join(" "));

  let score = 0;
  for (const token of tokens) {
    if (title.includes(token)) score += 5;
    if (topic.includes(token)) score += 4;
    if (tags.includes(token)) score += 3;
    if (purpose.includes(token)) score += 2;
    if (summary.includes(token)) score += 1;
  }
  return score;
}

export async function POST(request: NextRequest) {
  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof body.slug === "string" ? body.slug.trim() : "";
  const query = typeof body.query === "string" ? body.query.trim() : "";
  if (!slug) {
    return NextResponse.json({ hata: "Vitrin zorunludur." }, { status: 422 });
  }

  const cookieStore = await cookies();
  const ownerCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  if (!verifyOwnerSession(ownerCookie, slug)) {
    return NextResponse.json({ hata: "Sahiplik oturumu doğrulanamadı." }, { status: 401 });
  }

  if (!(await smartEngineBlogServerEnabled())) {
    return NextResponse.json(
      { hata: "Vixrex Blog komutları şu anda kapalı.", kod: "SMART_ENGINE_BLOG_DISABLED" },
      { status: 503 },
    );
  }

  const admin = getSupabaseAdmin();
  const { data, error } = await admin
    .from("vixrex_blog_articles")
    .select("id,title,slug,summary,primary_topic,purpose,tags,published_at")
    .eq("status", "published")
    .order("published_at", { ascending: false })
    .limit(50);

  if (error) {
    console.error("[blog-assistant] library search failed:", error.message);
    return NextResponse.json({ hata: "Blog kütüphanesi aranamadı." }, { status: 500 });
  }

  const tokens = queryTokens(query);
  const ranked = ((data ?? []) as LibraryArticle[])
    .map((article) => ({ article, score: articleScore(article, tokens) }))
    .filter(({ score }) => tokens.length === 0 || score > 0)
    .sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score;
      return String(b.article.published_at ?? "").localeCompare(
        String(a.article.published_at ?? ""),
      );
    })
    .slice(0, LIMIT)
    .map(({ article, score }) => ({
      id: article.id,
      title: article.title,
      slug: article.slug,
      summary: article.summary,
      primaryTopic: article.primary_topic,
      purpose: article.purpose,
      score,
    }));

  return NextResponse.json({ tamam: true, sonuclar: ranked });
}
