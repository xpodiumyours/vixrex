import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { isLikelyBotUserAgent } from "@/lib/vitrinBotFilter";

function clean(value: unknown, max: number) {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

export async function POST(request: NextRequest) {
  try {
    const userAgent = clean(request.headers.get("user-agent"), 300);
    if (isLikelyBotUserAgent(userAgent)) {
      return new NextResponse(null, { status: 204 });
    }

    const body = await request.json().catch(() => null) as Record<string, unknown> | null;
    const storeSlug = clean(body?.storeSlug, 120);
    const productSlug = clean(body?.productSlug, 120);
    const sessionKey = clean(body?.sessionKey, 160);
    const eventType = clean(body?.eventType, 40);

    // Bu kapı yalnız pasif ürün görüntülemesi içindir. Beğeni, yorum, sepet
    // ve iletişim gibi niyetli hareketler kendi yetki/işlem yollarını kullanır.
    if (
      eventType !== "product_view" ||
      !storeSlug ||
      !productSlug ||
      sessionKey.length < 16
    ) {
      return new NextResponse(null, { status: 204 });
    }

    const { error } = await getSupabaseAdmin().rpc("record_vitrin_engagement_v2", {
      p_store_slug: storeSlug,
      p_event_type: "product_view",
      p_session_key: sessionKey,
      p_product_slug: productSlug,
      p_quantity: null,
      p_metadata: { surface: "product_detail", web_bot_filtered: true },
    });

    if (error && process.env.NODE_ENV !== "production") {
      console.warn("[vitrin-engagement] ürün görüntüleme kaydedilemedi:", error.message);
    }
  } catch (error) {
    if (process.env.NODE_ENV !== "production") {
      console.warn("[vitrin-engagement] pasif ölçüm işlenemedi:", error);
    }
  }

  return new NextResponse(null, { status: 204 });
}
