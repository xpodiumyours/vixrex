import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { validateField } from "@/lib/vitrinFieldValidation";
import { broadcastTaslakGuncellendi } from "@/lib/workingDraftBroadcast";

// Vixrex Assistant çok-alan kayıt kapısı.
//
// Manuel panelin /api/owner-draft tek-alan yolu DEĞİŞMEZ. Bu route yalnız
// Assistant'ın tek kullanıcı mesajından çıkardığı birden fazla alanı, kullanıcı
// açıkça onayladıktan sonra, tek Postgres transaction'ında kaydetmek içindir.
//
// İstemci kolon adı gönderemez: yalnız şemadaki `anahtar` gönderir. Kolon
// validateField() sonucundaki VITRIN_FIELDS kaydından sunucuda çözülür.

export const dynamic = "force-dynamic";

const MAX_BATCH_FIELDS = 20;
const DRAFT_LIMIT_PER_MINUTE = 60;
const DRAFT_LIMIT_PER_HOUR = 500;

const HATA_METNI: Record<string, string> = {
  INVALID_SESSION_TOKEN: "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç.",
  DEMO_STORE_IMMUTABLE: "Bu örnek vitrin düzenlenemez.",
  FIELD_NOT_EDITABLE: "Bu alan düzenlenemez.",
  UNKNOWN_FIELD: "Bilinmeyen alan.",
  INVALID_FIELD_KEY: "Alan adı eksik.",
  INVALID_CHANGES: "Kaydedilecek değişiklik bulunamadı.",
  TOO_MANY_FIELDS: "Tek işlemde çok fazla alan var.",
  WORKING_DRAFT_NOT_FOUND: "Çalışma taslağı bulunamadı. Önizlemeyi tekrar açın.",
};

interface HamDegisiklik {
  anahtar?: unknown;
  deger?: unknown;
}

function supabaseAnon() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || "",
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
      process.env.SUPABASE_PUBLISHABLE_KEY ||
      ""
  );
}

// Tek-alan owner-draft ile aynı davranış: production'da rate-limit için
// service role zorunlu; Vercel Preview'da service role yoksa yalnız rate-limit
// katmanı atlanır, owner cookie + RPC session yetkisi aynen korunur.
function rateLimitAdmin(): SupabaseClient | null {
  try {
    return getSupabaseAdmin();
  } catch (error) {
    if (process.env.VERCEL_ENV === "preview") {
      console.warn("[owner-draft-batch] preview rate limit skipped: service role unavailable");
      return null;
    }
    throw error;
  }
}

async function rateLimitKontrol(
  admin: SupabaseClient,
  slug: string,
): Promise<{ ok: true } | { ok: false; response: NextResponse }> {
  const { data: minuteRows, error: minuteError } = await admin.rpc(
    "consume_assistant_request",
    {
      p_client_key: `owner_draft:${slug}:min`,
      p_max_requests: DRAFT_LIMIT_PER_MINUTE,
      p_window_seconds: 60,
    }
  );
  if (minuteError) {
    console.error("[owner-draft-batch] minute rate limit failed:", minuteError.message);
    return {
      ok: false,
      response: NextResponse.json(
        { hata: "Kaydedilemedi. Lütfen tekrar dene." },
        { status: 500 }
      ),
    };
  }
  const minuteResult = Array.isArray(minuteRows) ? minuteRows[0] : minuteRows;
  if (minuteResult && !minuteResult.allowed) {
    return {
      ok: false,
      response: NextResponse.json(
        { hata: `Çok sık güncelleme. ${minuteResult.retry_after_seconds} saniye sonra tekrar dene.` },
        { status: 429 }
      ),
    };
  }

  const { data: hourRows, error: hourError } = await admin.rpc(
    "consume_assistant_request",
    {
      p_client_key: `owner_draft:${slug}:hour`,
      p_max_requests: DRAFT_LIMIT_PER_HOUR,
      p_window_seconds: 3600,
    }
  );
  if (hourError) {
    console.error("[owner-draft-batch] hourly rate limit failed:", hourError.message);
    return {
      ok: false,
      response: NextResponse.json(
        { hata: "Kaydedilemedi. Lütfen tekrar dene." },
        { status: 500 }
      ),
    };
  }
  const hourResult = Array.isArray(hourRows) ? hourRows[0] : hourRows;
  if (hourResult && !hourResult.allowed) {
    return {
      ok: false,
      response: NextResponse.json(
        { hata: `Saatlik güncelleme limitine ulaştın. ${hourResult.retry_after_seconds} saniye sonra tekrar dene.` },
        { status: 429 }
      ),
    };
  }

  return { ok: true };
}

export async function POST(request: NextRequest) {
  let govde: {
    slug?: unknown;
    degisiklikler?: unknown;
    clientId?: unknown;
  };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const clientId = typeof govde.clientId === "string" ? govde.clientId : null;
  const hamDegisiklikler = Array.isArray(govde.degisiklikler)
    ? (govde.degisiklikler as HamDegisiklik[])
    : [];

  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }
  if (hamDegisiklikler.length < 1) {
    return NextResponse.json({ hata: "Kaydedilecek değişiklik bulunamadı." }, { status: 400 });
  }
  if (hamDegisiklikler.length > MAX_BATCH_FIELDS) {
    return NextResponse.json({ hata: "Tek işlemde çok fazla alan var." }, { status: 422 });
  }

  // Yetki yalnız imzalı HttpOnly owner cookie'den gelir. Body içinden token,
  // store_id veya kolon kabul edilmez.
  const cookieStore = await cookies();
  const ownerSession = verifyOwnerSession(
    cookieStore.get(OWNER_SESSION_COOKIE)?.value,
    slug
  );
  if (!ownerSession) {
    return NextResponse.json(
      { hata: HATA_METNI.INVALID_SESSION_TOKEN },
      { status: 401 }
    );
  }

  const gorulenAnahtarlar = new Set<string>();
  const normalizeEdilenler: Array<{
    anahtar: string;
    kolon: string;
    etiket: string;
    deger: string | number | boolean | null;
  }> = [];

  // Bir alan bile geçersizse RPC HİÇ çağrılmaz. Böylece kullanıcı onayladığı
  // kartın yalnız bir kısmının kaydedilmesi mümkün olmaz.
  for (const ham of hamDegisiklikler) {
    const anahtar = typeof ham?.anahtar === "string" ? ham.anahtar.trim() : "";
    if (!anahtar) {
      return NextResponse.json({ hata: "Alan adı eksik." }, { status: 422 });
    }
    if (gorulenAnahtarlar.has(anahtar)) {
      return NextResponse.json(
        { hata: `Aynı alan bir işlemde iki kez değiştirilemez: ${anahtar}` },
        { status: 422 }
      );
    }
    gorulenAnahtarlar.add(anahtar);

    const sonuc = validateField(anahtar, ham.deger);
    if (!sonuc.ok) {
      return NextResponse.json(
        { hata: sonuc.hata, anahtar },
        { status: 422 }
      );
    }
    normalizeEdilenler.push({
      anahtar: sonuc.alan.anahtar,
      kolon: sonuc.alan.kolon,
      etiket: sonuc.alan.etiket,
      deger: sonuc.deger,
    });
  }

  let admin: SupabaseClient | null;
  try {
    admin = rateLimitAdmin();
  } catch (error) {
    console.error("[owner-draft-batch] rate limit admin unavailable", error);
    return NextResponse.json(
      { hata: "Kaydetme servisi şu anda kullanılamıyor. Lütfen tekrar dene." },
      { status: 503 }
    );
  }

  if (admin) {
    const rateLimit = await rateLimitKontrol(admin, ownerSession.slug);
    if (!rateLimit.ok) return rateLimit.response;
  }

  const changesByColumn: Record<string, string | number | boolean | null> = {};
  for (const item of normalizeEdilenler) {
    changesByColumn[item.kolon] = item.deger;
  }

  const { data, error } = await supabaseAnon().rpc("update_working_draft_fields", {
    p_session_token: ownerSession.sessionToken,
    p_changes: changesByColumn,
  });

  if (error) {
    const metin = HATA_METNI[error.message] ?? "Kaydedilemedi. Lütfen tekrar dene.";
    console.error("[owner-draft-batch] update failed:", error.message);
    const durum = error.message === "INVALID_SESSION_TOKEN" ? 401 : 400;
    return NextResponse.json({ hata: metin }, { status: durum });
  }

  // Tek kullanıcı işlemi → tek yayın sinyali. Payload alan/değer taşımaz.
  broadcastTaslakGuncellendi(slug, clientId);

  return NextResponse.json({
    tamam: true,
    degisiklikler: normalizeEdilenler,
    taslakSurumu: (data as { draft_version?: number } | null)?.draft_version ?? null,
  });
}
