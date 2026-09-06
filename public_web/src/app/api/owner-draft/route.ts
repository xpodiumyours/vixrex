import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { validateField } from "@/lib/vitrinFieldValidation";
import { broadcastTaslakGuncellendi } from "@/lib/workingDraftBroadcast";

// Sahip çalışma taslağında tek MANUEL alan günceller
// (implementation_plan.md Commit 8).
//
// Akıllı Motor mutation'ları bu route'tan GEÇMEZ. 5.5/5.6 authoritative
// yolunda expectedDraftVersion + commandId + actionId + audit/idempotency
// zorunludur ve /api/owner-smart-engine-action üzerinden çalışır. Böylece
// eski/bonus bir çağrı `source:"smart_engine"` yollasa bile legacy
// update_working_draft_field RPC'sine düşüp concurrency korumasını atlayamaz.
//
// Manuel zincir:
//   istek {slug, anahtar, deger}
//   → HttpOnly sahip çerezi doğrulanır (gövdeden token ALINMAZ)
//   → değer şemaya göre doğrulanır (vitrinFieldValidation)
//   → Oran sınırı: consume_assistant_request (store-slug bazlı)
//   → update_working_draft_field RPC'si çağrılır
//   → veritabanı kendi bağımsız yetki kontrolünü yapar
//
// Alan başına dallanma YOKTUR. Yeni alan eklemek için bu dosya değişmez;
// yalnız vitrinFieldSchema.ts'e satır eklenir.
//
// Başarılı kayıt sonrası Supabase Realtime Broadcast ile `draft:${slug}`
// kanalına "alan_guncellendi" sinyali gönderilir — diğer açık sekme/uygulama
// bunu görüp kendi sayfasını tazeler (router.refresh()).
// Broadcast fire-and-forget: başarısız olursa kayıt yine de geçerlidir.
//
// GÜVENLİK: bu kanala sahip oturumu OLMADAN da bağlanılabilir (public
// anon key yeterli — Supabase Broadcast varsayılan açık kanal). Bu yüzden
// payload'da alan adı/değeri TAŞINMAZ, yalnız boş bir sinyal gönderilir.
// Gerçek değer yalnız sahip çerezi sunucuda tekrar doğrulanarak okunur
// (code-review, 2026-08-10 — ilk sürüm değeri payload'da taşıyordu, taslak
// verisi yetkisiz herkese sızıyordu).

export const dynamic = "force-dynamic";

const HATA_METNI: Record<string, string> = {
  INVALID_SESSION_TOKEN: "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç.",
  DEMO_STORE_IMMUTABLE: "Bu örnek vitrin düzenlenemez.",
  FIELD_NOT_EDITABLE: "Bu alan düzenlenemez.",
  UNKNOWN_FIELD: "Bilinmeyen alan.",
  INVALID_FIELD_KEY: "Alan adı eksik.",
  WORKING_DRAFT_NOT_FOUND: "Çalışma taslağı bulunamadı. Önizlemeyi tekrar açın.",
};

// Oran sınırı: store başına dakikada 60 istek, saatte 500 istek
// (aşırı yazma / taslak bozulması / maliyet koruması)
const DRAFT_LIMIT_PER_MINUTE = 60;
const DRAFT_LIMIT_PER_HOUR = 500;

function supabaseAnon() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || "",
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
      process.env.SUPABASE_PUBLISHABLE_KEY ||
      ""
  );
}

/**
 * Preview ortamında servis anahtarı secret'ı tanımlı değilse eski kod
 * getSupabaseAdmin() içinde throw ediyor, Next.js HTML 500 dönüyor ve istemci
 * bunu JSON sanıp parse etmeye çalışınca yalnız "Bağlantı kurulamadı" görüyordu.
 *
 * Üretimde fail-closed davranışı KORUNUR: service role yoksa kayıt açılmaz.
 * Preview'da ise yalnız rate-limit katmanı atlanır; kayıt yine iki ayrı kapıdan
 * geçer: imzalı HttpOnly owner çerezi + update_working_draft_field içindeki
 * session-token/store yetkisi. Böylece PR Preview fonksiyonel test edilebilir,
 * production güvenlik davranışı değişmez.
 */
function rateLimitAdmin(): SupabaseClient | null {
  try {
    return getSupabaseAdmin();
  } catch (error) {
    if (process.env.VERCEL_ENV === "preview") {
      console.warn("[owner-draft] preview rate limit skipped: service role unavailable");
      return null;
    }
    throw error;
  }
}

export async function POST(request: NextRequest) {
  let govde: {
    slug?: unknown;
    anahtar?: unknown;
    deger?: unknown;
    clientId?: unknown;
    source?: unknown;
  };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const anahtar = typeof govde.anahtar === "string" ? govde.anahtar.trim() : "";
  const smartEngineRequest = govde.source === "smart_engine";
  // Yalnız kendi yankısını atlamak için kullanılan opak bir etiket — yetki
  // veya kimlik anlamı taşımaz, doğrulanmasına gerek yok.
  const clientId = typeof govde.clientId === "string" ? govde.clientId : null;

  if (!slug || !anahtar) {
    return NextResponse.json({ hata: "Vitrin veya alan belirtilmedi." }, { status: 400 });
  }

  // Legacy assistant mutation burada fail-closed olur. Manuel yol etkilenmez.
  if (smartEngineRequest) {
    return NextResponse.json(
      {
        hata: "Akıllı Motor kaydı authoritative işlem yolundan gönderilmeli.",
        kod: "SMART_ENGINE_AUTHORITATIVE_ROUTE_REQUIRED",
      },
      { status: 409 }
    );
  }

  // Oturum YALNIZ çerezden okunur. Gövdeden gelen bir token kabul edilmez.
  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);

  if (!ownerSession) {
    return NextResponse.json(
      { hata: HATA_METNI.INVALID_SESSION_TOKEN },
      { status: 401 }
    );
  }

  // Şema doğrulaması — tek fonksiyon, alan başına dallanma yok.
  const sonuc = validateField(anahtar, govde.deger);
  if (!sonuc.ok) {
    return NextResponse.json({ hata: sonuc.hata }, { status: 422 });
  }

  // Oran sınırı: store slug bazlı (ownerSession.slug doğrulanmış).
  // Production'da service-role zorunlu. Preview'da secret yoksa yukarıdaki
  // açıklanan dar istisna ile yalnız bu katman atlanır.
  let admin: SupabaseClient | null;
  try {
    admin = rateLimitAdmin();
  } catch (error) {
    console.error("[owner-draft] rate limit admin unavailable", error);
    return NextResponse.json(
      { hata: "Kaydetme servisi şu anda kullanılamıyor. Lütfen tekrar dene." },
      { status: 503 }
    );
  }

  if (admin) {
    // Dakikalık pencere
    const { data: minuteRows, error: minuteError } = await admin.rpc("consume_assistant_request", {
      p_client_key: `owner_draft:${ownerSession.slug}:min`,
      p_max_requests: DRAFT_LIMIT_PER_MINUTE,
      p_window_seconds: 60,
    });
    if (minuteError) {
      console.error("[owner-draft] minute rate limit failed:", minuteError.message);
      return NextResponse.json({ hata: "Kaydedilemedi. Lütfen tekrar dene." }, { status: 500 });
    }
    const minuteResult = Array.isArray(minuteRows) ? minuteRows[0] : minuteRows;
    if (minuteResult && !minuteResult.allowed) {
      return NextResponse.json(
        { hata: `Çok sık güncelleme. ${minuteResult.retry_after_seconds} saniye sonra tekrar dene.` },
        { status: 429 }
      );
    }

    // Saatlik pencere
    const { data: hourRows, error: hourError } = await admin.rpc("consume_assistant_request", {
      p_client_key: `owner_draft:${ownerSession.slug}:hour`,
      p_max_requests: DRAFT_LIMIT_PER_HOUR,
      p_window_seconds: 3600,
    });
    if (hourError) {
      console.error("[owner-draft] hourly rate limit failed:", hourError.message);
      return NextResponse.json({ hata: "Kaydedilemedi. Lütfen tekrar dene." }, { status: 500 });
    }
    const hourResult = Array.isArray(hourRows) ? hourRows[0] : hourRows;
    if (hourResult && !hourResult.allowed) {
      return NextResponse.json(
        { hata: `Saatlik güncelleme limitine ulaştın. ${hourResult.retry_after_seconds} saniye sonra tekrar dene.` },
        { status: 429 }
      );
    }
  }

  const { error, data } = await supabaseAnon().rpc("update_working_draft_field", {
    p_session_token: ownerSession.sessionToken,
    p_key: sonuc.alan.kolon,
    p_value: sonuc.deger,
  });

  if (error) {
    const metin = HATA_METNI[error.message] ?? "Kaydedilemedi. Lütfen tekrar dene.";
    // Hata mesajı loglanır; oturum tokenı ve alan değeri loglanmaz.
    console.error("[owner-draft] update failed:", error.message);
    const durum = error.message === "INVALID_SESSION_TOKEN" ? 401 : 400;
    return NextResponse.json({ hata: metin }, { status: durum });
  }

  broadcastTaslakGuncellendi(slug, clientId);

  return NextResponse.json({
    tamam: true,
    anahtar: sonuc.alan.anahtar,
    etiket: sonuc.alan.etiket,
    deger: sonuc.deger,
    taslakSurumu: (data as { draft_version?: number } | null)?.draft_version ?? null,
  });
}
