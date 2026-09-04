import { NextResponse, type NextRequest } from "next/server";
import type { SupabaseClient } from "@supabase/supabase-js";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

export type PlatformAdminAuthResult =
  | { ok: true; admin: SupabaseClient; userId: string }
  | { ok: false; response: NextResponse };

/**
 * Platform-yönetici uçları için açık kimlik kapısı.
 * Owner-session kabul etmez; yalnız Supabase Bearer oturumu + admins kaydı.
 */
export async function platformAdminDogrula(
  request: NextRequest,
): Promise<PlatformAdminAuthResult> {
  const authorization = request.headers.get("authorization") ?? "";
  const token = authorization.startsWith("Bearer ")
    ? authorization.slice("Bearer ".length).trim()
    : "";
  if (!token) {
    return {
      ok: false,
      response: NextResponse.json({ hata: "Yönetici oturumu gerekli." }, { status: 401 }),
    };
  }

  let admin: SupabaseClient;
  try {
    admin = getSupabaseAdmin();
  } catch {
    return {
      ok: false,
      response: NextResponse.json({ hata: "Sunucu yapılandırması eksik." }, { status: 500 }),
    };
  }

  const {
    data: { user },
    error: authError,
  } = await admin.auth.getUser(token);
  if (authError || !user || user.is_anonymous) {
    return {
      ok: false,
      response: NextResponse.json({ hata: "Yönetici oturumu geçersiz." }, { status: 401 }),
    };
  }

  const { data: adminRow, error: adminError } = await admin
    .from("admins")
    .select("user_id")
    .eq("user_id", user.id)
    .maybeSingle();

  if (adminError) {
    console.error("[platform-admin] admin lookup failed:", adminError.message);
    return {
      ok: false,
      response: NextResponse.json({ hata: "Yönetici yetkisi doğrulanamadı." }, { status: 500 }),
    };
  }

  if (!adminRow) {
    return {
      ok: false,
      response: NextResponse.json({ hata: "Bu işlem için yönetici yetkisi gerekli." }, { status: 403 }),
    };
  }

  return { ok: true, admin, userId: user.id };
}
