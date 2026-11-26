import { NextRequest, NextResponse } from "next/server";
import { revalidateTag, revalidatePath } from "next/cache";

/**
 * POST /api/revalidate
 *
 * Flutter'dan ve Supabase webhook'larından gelen ISR geçersizleştirme isteklerini
 * işler. Kimlik doğrulaması iki yoldan yapılır (2026-11-26 güvenlik düzeltmesi):
 *
 *   1) Mobil uygulama (Flutter / vixrex-app): kullanıcının kendi doğrulanmış
 *      Supabase oturum token'i (`Authorization: Bearer <access_token>`) ile
 *      yetkilendirilir — sunucu sırrı gömülmez.
 *   2) Sunucu içi tetikleyiciler (Supabase webhook / operasyon): `x-revalidate-secret`
 *      başlığı, `REVALIDATION_SECRET` ortam değişkeniyle karşılaştırılır (fail-closed).
 *
 * Body (JSON):
 *   { "tag": "store-nova-kuafor" }          → revalidateTag kullanır
 *   { "tags": ["store-x", "products-x"] }   → çoklu tag yeniler
 *   { "path": "/v/nova-kuafor" }            → revalidatePath kullanır
 *   { "paths": ["/v/x/urun/y"] }            → çoklu path yeniler
 *
 * Header:
 *   Authorization: Bearer <supabase access token>   (kullanıcı oturumu)
 *   x-revalidate-secret: <REVALIDATION_SECRET>      (sunucu içi tetikleyici)
 */
export async function POST(req: NextRequest) {
  const bearerToken =
    req.headers.get("authorization")?.startsWith("Bearer ") === true
      ? (req.headers.get("authorization") as string).slice(7).trim()
      : "";

  let userAuthorized = false;
  if (bearerToken) {
    const supabaseUrl =
      process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || "";
    const supabaseKey =
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
      process.env.SUPABASE_PUBLISHABLE_KEY ||
      "";
    if (supabaseUrl && supabaseKey) {
      const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
        headers: {
          apikey: supabaseKey,
          Authorization: `Bearer ${bearerToken}`,
        },
      });
      userAuthorized = userResponse.ok;
    }
  }

  const localSecret = process.env.REVALIDATION_SECRET;
  const headerSecret = req.headers.get("x-revalidate-secret");
  const internalAuthorized =
    Boolean(localSecret) && headerSecret === localSecret;

  if (!userAuthorized && !internalAuthorized) {
    return NextResponse.json({ message: "Invalid secret token" }, { status: 401 });
  }

  try {
    const body = await req.json() as Record<string, unknown>;
    const tags = new Set<string>();
    const paths = new Set<string>();

    if (typeof body.tag === "string" && body.tag.trim()) {
      tags.add(body.tag.trim());
    }

    if (Array.isArray(body.tags)) {
      for (const item of body.tags) {
        if (typeof item === "string" && item.trim()) tags.add(item.trim());
      }
    }

    if (typeof body.path === "string" && body.path.trim()) {
      paths.add(body.path.trim());
    }

    if (Array.isArray(body.paths)) {
      for (const item of body.paths) {
        if (typeof item === "string" && item.trim()) paths.add(item.trim());
      }
    }

    if (tags.size === 0 && paths.size === 0) {
      return NextResponse.json(
        { message: "Missing 'tag', 'tags', 'path' or 'paths' in request body" },
        { status: 400 }
      );
    }

    const revalidated: string[] = [];

    for (const tag of tags) {
      // Next.js 16: expire: 0 etiketi hemen stale yapar; sonraki istek
      // eski değeri sunmadan kaynağı yeniden doğrular. Flutter değişikliği
      // sonrası web vitrininin ilk istekte eski cache göstermesini engeller.
      revalidateTag(tag, { expire: 0 });
      revalidated.push(`tag:${tag}`);
    }

    for (const path of paths) {
      revalidatePath(path, "page");
      revalidated.push(`path:${path}`);
    }

    return NextResponse.json({ revalidated, now: Date.now() });
  } catch (err: unknown) {
    console.error("Revalidation error:", err);
    return NextResponse.json({ message: "Revalidation failed" }, { status: 500 });
  }
}
