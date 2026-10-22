import { NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

export const dynamic = "force-dynamic";

/** Anahtar veya özel iş bilgisi açılmaz; gerçek işleyici kurulumu da kontrol edilir. */
export async function GET() {
  let hazir = false;
  if (process.env.OPENROUTER_API_KEY) {
    try {
      const { data, error } = await getSupabaseAdmin().rpc("invoice_provider_ready");
      hazir = !error && data === true;
    } catch { hazir = false; }
  }
  return NextResponse.json({ hazir }, { headers: { "Cache-Control": "no-store" } });
}
