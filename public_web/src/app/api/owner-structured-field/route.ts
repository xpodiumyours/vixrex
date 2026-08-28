import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

/**
 * Yapılandırılmış JSONB alanları için API route.
 * faq_items, about_values gibi VITRIN_FIELDS şemasında olmayan
 * ama stores tablosunda JSONB kolon olarak mevcut alanları kaydeder.
 *
 * Zincir:
 *   istek {slug, kolon, deger}
 *   → HttpOnly sahip çerezi doğrulanır
 *   → kolon izin listesinde mi kontrol edilir
 *   → değer JSONB olarak doğrulanır
 *   → update_working_draft_field RPC'si çağrılır
 */

export const dynamic = "force-dynamic";

// İzin verilen yapılandırılmış JSONB kolonları
const ALLOWED_COLUMNS = new Set([
  "faq_items",
  "about_values",
]);

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const kolon = typeof govde.kolon === "string" ? govde.kolon.trim() : "";
  const deger = govde.deger;

  if (!slug || !kolon) {
    return NextResponse.json(
      { hata: "Vitrin veya alan belirtilmedi." },
      { status: 400 }
    );
  }

  if (!ALLOWED_COLUMNS.has(kolon)) {
    return NextResponse.json(
      { hata: "Bu alan düzenlenemez." },
      { status: 403 }
    );
  }

  // Oturum doğrulaması
  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);

  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Oturumunuz geçersiz veya süresi dolmuş." },
      { status: 401 }
    );
  }

  // Değer JSONB olmalı
  if (deger !== null && typeof deger !== "object") {
    return NextResponse.json(
      { hata: "Geçersiz veri formatı." },
      { status: 400 }
    );
  }

  const admin = getSupabaseAdmin();

  const { error } = await admin.rpc("update_working_draft_field", {
    p_session_token: ownerSession.sessionToken,
    p_key: kolon,
    p_value: deger === null ? null : JSON.stringify(deger),
  });

  if (error) {
    console.error("[owner-structured-field] update failed:", error.message);
    const metin =
      error.message === "INVALID_SESSION_TOKEN"
        ? "Oturumunuz geçersiz."
        : "Kaydedilemedi. Lütfen tekrar dene.";
    const durum = error.message === "INVALID_SESSION_TOKEN" ? 401 : 400;
    return NextResponse.json({ hata: metin }, { status: durum });
  }

  return NextResponse.json({ tamam: true, kolon });
}
