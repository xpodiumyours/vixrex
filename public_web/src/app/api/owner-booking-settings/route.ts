import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

/**
 * Sahibin randevu ayarlarını güncellemesi için API route.
 * Flutter Web'deki booking settings yönetimine karşılık gelir.
 *
 * Güncellenebilir alanlar:
 *   - is_enabled: boolean
 *   - capacity: number (1-5)
 *   - working_hours: JSONB (7 gün, her biri start/end/active)
 *   - lunch_break: JSONB (start/end/active)
 *
 * Oturum: HttpOnly owner_session cookie ile doğrulanır.
 */

export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
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

  const admin = getSupabaseAdmin();

  // Mevcut booking_settings'i çek
  const { data: mevcut, error: okumaHata } = await admin
    .from("booking_settings")
    .select("*")
    .eq("store_slug", slug)
    .single();

  if (okumaHata && okumaHata.code !== "PGRST116") {
    return NextResponse.json(
      { hata: "Randevu ayarları okunamadı." },
      { status: 500 }
    );
  }

  // Güncellenecek alanları topla
  const guncelleme: Record<string, unknown> = {};

  if (typeof govde.is_enabled === "boolean") {
    guncelleme.is_enabled = govde.is_enabled;
  }

  if (typeof govde.capacity === "number") {
    const cap = Math.max(1, Math.min(5, Math.round(govde.capacity)));
    guncelleme.capacity = cap;
  }

  if (govde.working_hours && typeof govde.working_hours === "object") {
    // Flutter Web modeli: 1-7 arası key, her biri {start, end, active}
    const wh = govde.working_hours as Record<string, unknown>;
    const gunKeys = ["1","2","3","4","5","6","7"];
    const temiz: Record<string, { start: string; end: string; active: boolean }> = {};
    for (const k of gunKeys) {
      const gun = wh[k];
      if (gun && typeof gun === "object") {
        const g = gun as Record<string, unknown>;
        temiz[k] = {
          start: typeof g.start === "string" ? g.start : "09:00",
          end: typeof g.end === "string" ? g.end : "19:00",
          active: g.active === true,
        };
      }
    }
    guncelleme.working_hours = temiz;
  }

  if (govde.lunch_break && typeof govde.lunch_break === "object") {
    const lb = govde.lunch_break as Record<string, unknown>;
    guncelleme.lunch_break = {
      start: typeof lb.start === "string" ? lb.start : "12:00",
      end: typeof lb.end === "string" ? lb.end : "13:00",
      active: lb.active === true,
    };
  }

  if (Object.keys(guncelleme).length === 0) {
    return NextResponse.json({ hata: "Güncellenecek alan belirtilmedi." }, { status: 400 });
  }

  guncelleme.updated_at = new Date().toISOString();

  if (mevcut) {
    // Güncelle
    const { error } = await admin
      .from("booking_settings")
      .update(guncelleme)
      .eq("store_slug", slug);

    if (error) {
      console.error("[owner-booking-settings] update failed:", error.message);
      return NextResponse.json({ hata: "Kaydedilemedi." }, { status: 500 });
    }
  } else {
    // Yeni oluştur
    const { error } = await admin
      .from("booking_settings")
      .insert({ store_slug: slug, ...guncelleme });

    if (error) {
      console.error("[owner-booking-settings] insert failed:", error.message);
      return NextResponse.json({ hata: "Kaydedilemedi." }, { status: 500 });
    }
  }

  return NextResponse.json({ tamam: true, guncellenen: Object.keys(guncelleme) });
}
