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
 *   { "path": "/v/nova-kuafor" }            → revalidatePath kullanır (geriye dönük uyumluluk)
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
    const tag = typeof body.tag === "string" ? body.tag.trim() : "";
    const path = typeof body.path === "string" ? body.path.trim() : "";

    if (!tag && !path) {
      return NextResponse.json(
        { message: "Missing 'tag' or 'path' in request body" },
        { status: 400 }
      );
    }

    const revalidated: string[] = [];

    if (tag) {
      // "max" profili: tag'i anında geçersiz kıl (bu Next.js sürümünde 2. argüman zorunlu)
      revalidateTag(tag, "max");
      revalidated.push(`tag:${tag}`);
    }

    if (path) {
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
