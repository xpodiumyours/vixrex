import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

/**
 * Randevu yönetim API'si.
 *
 * GET  — vitrinin randevularını listeler (sahip çerezi yeterli).
 * POST — randevuya yanıt verir: onayla / reddet / değişiklik.
 *
 * İKİ FARKLI YETKİ YOLU VAR, KARIŞTIRMA (2026-08-27'de ölçüldü):
 *
 * Ürün ve yazı API'leri sahip çerezini kullanıp işi vitrinin `edit_token`'ı
 * üzerinden RPC'ye yaptırıyor. Randevu RPC'si ise `respond_to_appointment`
 * ve yetkiyi ŞÖYLE kuruyor (canlı gövdeden okundu):
 *
 *     SELECT EXISTS (SELECT 1 FROM stores
 *                    WHERE slug = v_appt.store_slug AND user_id = auth.uid())
 *     IF NOT v_is_owner THEN RAISE 'UNAUTHORIZED';
 *
 * Yani Supabase oturumu (`auth.uid()`) gerektiriyor, `edit_token` kabul
 * etmiyor. İlk hâlde bu RPC `service_role` istemcisiyle çağrılıyordu;
 * orada `auth.uid()` NULL olduğu için karşılaştırma hiçbir zaman
 * tutmuyordu ve HER çağrI 'UNAUTHORIZED' ile düşüyordu. Güvenlik açığı
 * değildi — kapı fazla sıkı kapanmıştı, özellik hiç çalışmıyordu.
 *
 * Artık POST, çağıranın Supabase erişim jetonunu (`Authorization: Bearer`)
 * istiyor ve RPC'yi kullanıcının KENDİ istemcisiyle çağırıyor. Sahip
 * çerezi kontrolü de yerinde duruyor: çerez slug kapsamını, RPC ise
 * randevunun gerçekten o hesaba ait olduğunu doğruluyor.
 *
 * Flutter'daki BookingService aynı tabloyu ve aynı RPC'yi kullanıyor.
 */

export const dynamic = "force-dynamic";

/** Çağıranın kendi oturumuyla konuşan istemci — `auth.uid()` bunu ister. */
function kullaniciIstemcisi(bearerToken: string): SupabaseClient | null {
  const url =
    process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || "";
  const anonKey =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
    process.env.SUPABASE_PUBLISHABLE_KEY ||
    "";
  if (!url || !anonKey) return null;

  return createClient(url, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${bearerToken}` } },
  });
}

async function verifyOwner(slug: string): Promise<{ ok: boolean; storeId?: string; error?: string }> {
  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);
  if (!ownerSession) {
    return { ok: false, error: "Oturumun geçersiz veya süresi dolmuş." };
  }
  return { ok: true, storeId: ownerSession.storeId };
}

export async function GET(request: NextRequest) {
  const url = new URL(request.url);
  const slug = url.searchParams.get("slug")?.trim() ?? "";
  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }

  const auth = await verifyOwner(slug);
  if (!auth.ok) {
    return NextResponse.json({ hata: auth.error }, { status: 401 });
  }

  const admin = getSupabaseAdmin();

  const { data, error } = await admin
    .from("appointments")
    .select("*, appointment_reschedule_requests(*)")
    .eq("store_slug", slug)
    .order("appointment_time", { ascending: true });

  if (error) {
    console.error("[appointments] list failed:", error.message);
    return NextResponse.json(
      { hata: "Randevular getirilemedi." },
      { status: 500 }
    );
  }

  return NextResponse.json({ tamam: true, randevular: data ?? [] });
}

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const appointmentId = typeof govde.appointmentId === "string" ? govde.appointmentId.trim() : "";
  if (!slug || !appointmentId) {
    return NextResponse.json(
      { hata: "Vitrin ve randevu ID zorunludur." },
      { status: 422 }
    );
  }

  const auth = await verifyOwner(slug);
  if (!auth.ok) {
    return NextResponse.json({ hata: auth.error }, { status: 401 });
  }

  const action = typeof govde.action === "string" ? govde.action : null;
  const rescheduleAction =
    typeof govde.rescheduleAction === "string" ? govde.rescheduleAction : null;

  if (!action && !rescheduleAction) {
    return NextResponse.json(
      { hata: "İşlem belirtilmedi (action veya rescheduleAction)." },
      { status: 422 }
    );
  }

  // RPC `auth.uid()` istiyor — yönetici istemcisiyle çağrılamaz.
  const bearerToken = request.headers
    .get("authorization")
    ?.replace("Bearer ", "")
    .trim();

  if (!bearerToken) {
    return NextResponse.json(
      { hata: "Oturum bulunamadı. Lütfen tekrar giriş yap." },
      { status: 401 }
    );
  }

  const supabaseUser = kullaniciIstemcisi(bearerToken);
  if (!supabaseUser) {
    return NextResponse.json(
      { hata: "Sunucu yapılandırması eksik." },
      { status: 500 }
    );
  }

  const { error } = await supabaseUser.rpc("respond_to_appointment", {
    p_appointment_id: appointmentId,
    p_action: action,
    p_reschedule_action: rescheduleAction,
  });

  if (error) {
    console.error("[appointments] respond failed:", error.message);

    // RPC randevunun sahibi değilsen 'UNAUTHORIZED' fırlatıyor. Bunu 500
    // ile örtmek yanlış olur — çağıran taraf yetki sorununu ayırt
    // edebilmeli, yoksa "sunucu bozuk" sanır.
    if (error.message.includes("UNAUTHORIZED")) {
      return NextResponse.json(
        { hata: "Bu randevu senin vitrinine ait değil." },
        { status: 403 }
      );
    }
    if (error.message.includes("APPOINTMENT_NOT_FOUND")) {
      return NextResponse.json({ hata: "Randevu bulunamadı." }, { status: 404 });
    }

    return NextResponse.json(
      { hata: "Randevu güncellenemedi." },
      { status: 500 }
    );
  }

  return NextResponse.json({ tamam: true });
}
