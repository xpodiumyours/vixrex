import { NextRequest, NextResponse } from "next/server";
import { revalidateTag, revalidatePath } from "next/cache";

/**
 * POST /api/revalidate
 *
 * Flutter'dan ve Supabase webhook'larından gelen ISR geçersizleştirme isteklerini
 * işler. Secret, query param yerine header üzerinden okunur (URL log sızıntısı önlemi).
 *
 * Body (JSON):
 *   { "tag": "store-nova-kuafor" }          → revalidateTag kullanır
 *   { "tags": ["store-x", "products-x"] }   → çoklu tag yeniler
 *   { "path": "/v/nova-kuafor" }            → revalidatePath kullanır (geriye dönük uyumluluk)
 *   { "paths": ["/v/x/urun/y"] }            → çoklu path yeniler
 *
 * Header:
 *   x-revalidate-secret: <REVALIDATION_SECRET>
 */
export async function POST(req: NextRequest) {
  const localSecret = process.env.REVALIDATION_SECRET;

  // Secret header üzerinden okunur — query param'da sızmaz
  const headerSecret = req.headers.get("x-revalidate-secret");

  if (!localSecret || headerSecret !== localSecret) {
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
      // "max" profili: tag'i anında geçersiz kıl (bu Next.js sürümünde 2. argüman zorunlu)
      revalidateTag(tag, "max");
      revalidated.push(`tag:${tag}`);
    }

    for (const path of paths) {
      // Geriye dönük uyumluluk: path bazlı revalidation da desteklenir
      revalidatePath(path, "page");
      revalidated.push(`path:${path}`);
    }

    return NextResponse.json({ revalidated, now: Date.now() });
  } catch (err: unknown) {
    console.error("Revalidation error:", err);
    const errMsg = err instanceof Error ? err.message : "Revalidation failed";
    return NextResponse.json({ message: errMsg }, { status: 500 });
  }
}
