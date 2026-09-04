import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";

export const dynamic = "force-dynamic";

type ImportMode = "linked_excerpt" | "adaptable_draft";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function supabaseAnon() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || "",
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
      process.env.SUPABASE_PUBLISHABLE_KEY ||
      "",
  );
}

function rpcHatasi(errorMessage: string) {
  if (
    errorMessage.includes("STORE_NOT_AUTHORIZED") ||
    errorMessage.includes("INVALID_SESSION_TOKEN")
  ) {
    return NextResponse.json(
      { hata: "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç." },
      { status: 401 },
    );
  }
  if (errorMessage.includes("SOURCE_NOT_PUBLISHED")) {
    return NextResponse.json(
      { hata: "Bu Vixrex yazısı yayında değil veya bulunamadı." },
      { status: 404 },
    );
  }
  if (errorMessage.includes("STORE_NOT_FOUND")) {
    return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
  }
  if (errorMessage.includes("DEMO_STORE_IMMUTABLE")) {
    return NextResponse.json(
      { hata: "Örnek vitrine yazı eklenemez." },
      { status: 403 },
    );
  }
  if (
    errorMessage.includes("INVALID_IMPORT_MODE") ||
    errorMessage.includes("INVALID_SOURCE_ARTICLE") ||
    errorMessage.includes("INVALID_STORE_SLUG")
  ) {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 422 });
  }

  console.error("[vixrex-blog-import] rpc failed:", errorMessage);
  return NextResponse.json(
    { hata: "Yazı vitrininize eklenemedi. Lütfen tekrar deneyin." },
    { status: 500 },
  );
}

/**
 * Merkezi Vixrex yazısını mevcut vitrin bloguna TASLAK olarak çeker.
 *
 * İki kapılı yetki:
 * 1. İmzalı HttpOnly owner cookie burada hedef slug için doğrulanır.
 * 2. Açık sessionToken DB RPC'ye verilir; DB owner_sessions kaydını ve
 *    hedef store_id eşleşmesini yeniden doğrular.
 *
 * Bu route hiçbir zaman doğrudan published store article oluşturmaz.
 */
export async function POST(request: NextRequest) {
  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof body.slug === "string" ? body.slug.trim() : "";
  const sourceArticleId =
    typeof body.sourceArticleId === "string" ? body.sourceArticleId.trim() : "";
  const mode = typeof body.mode === "string" ? body.mode.trim() : "";

  if (!slug || !UUID_RE.test(sourceArticleId)) {
    return NextResponse.json(
      { hata: "Vitrin ve kaynak yazı zorunludur." },
      { status: 422 },
    );
  }

  if (mode !== "linked_excerpt" && mode !== "adaptable_draft") {
    return NextResponse.json(
      { hata: "Yazı ekleme biçimi geçersiz." },
      { status: 422 },
    );
  }

  const cookieStore = await cookies();
  const ownerCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerCookie, slug);
  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç." },
      { status: 401 },
    );
  }

  const { data, error } = await supabaseAnon().rpc(
    "import_vixrex_blog_article_to_store",
    {
      p_store_slug: slug,
      p_source_article_id: sourceArticleId,
      p_mode: mode as ImportMode,
      p_session_token: ownerSession.sessionToken,
    },
  );

  if (error) return rpcHatasi(error.message);

  const result = data as {
    created?: boolean;
    article_id?: string;
    article_slug?: string;
    source_slug?: string;
    mode?: ImportMode;
  } | null;

  if (!result?.article_id || !result.article_slug) {
    return NextResponse.json(
      { hata: "Yazı vitrininize eklenemedi. Lütfen tekrar deneyin." },
      { status: 500 },
    );
  }

  return NextResponse.json({
    tamam: true,
    olusturuldu: result.created === true,
    yaziId: result.article_id,
    yaziSlug: result.article_slug,
    kaynakSlug: result.source_slug ?? null,
    mod: result.mode ?? mode,
  });
}
