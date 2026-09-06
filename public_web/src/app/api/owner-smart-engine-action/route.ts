import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { SMART_ENGINE_DISABLED_MESSAGE } from "@/lib/smartEngineFlags";
import { smartEngineStorefrontServerEnabled } from "@/lib/smartEngineFlagsServer";
import { validateField } from "@/lib/vitrinFieldValidation";
import { broadcastTaslakGuncellendi } from "@/lib/workingDraftBroadcast";

export const dynamic = "force-dynamic";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const LIMIT_PER_MINUTE = 60;
const LIMIT_PER_HOUR = 500;

const DB_HATALARI: Record<string, { status: number; mesaj: string }> = {
  INVALID_ACTION_PRECONDITION: { status: 400, mesaj: "Akıllı motor işlem bilgisi eksik." },
  SMART_ENGINE_DISABLED: { status: 503, mesaj: SMART_ENGINE_DISABLED_MESSAGE },
  INVALID_SESSION_TOKEN: { status: 401, mesaj: "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç." },
  OWNER_AUTHORIZATION_REQUIRED: { status: 401, mesaj: "Sahip oturumu gerekli." },
  DEMO_STORE_IMMUTABLE: { status: 403, mesaj: "Bu örnek vitrin düzenlenemez." },
  FIELD_NOT_EDITABLE: { status: 422, mesaj: "Bu alan akıllı motor tarafından düzenlenemez." },
  INVALID_FIELD_VALUE: { status: 422, mesaj: "Alan değeri sunucu doğrulamasından geçmedi." },
  WORKING_DRAFT_NOT_FOUND: { status: 404, mesaj: "Çalışma taslağı bulunamadı. Önizlemeyi tekrar aç." },
  IDEMPOTENCY_KEY_REUSE: { status: 409, mesaj: "Bu işlem kimliği farklı bir işlem için daha önce kullanılmış." },
  DRAFT_VERSION_CONFLICT: { status: 409, mesaj: "Taslak başka bir yerde değişti. Güncel hâli alıp tekrar dene." },
};

type LimitResult = {
  allowed?: boolean;
  retry_after_seconds?: number;
};

type ActionRpcResult = {
  ok?: boolean;
  replayed?: boolean;
  draft_version?: number;
  action_id?: string;
  command_id?: string;
  field_key?: string;
  column?: string;
};

function dbHataKodu(message: string): string | null {
  return Object.keys(DB_HATALARI).find((kod) => message.includes(kod)) ?? null;
}

async function oranSiniri(
  admin: ReturnType<typeof getSupabaseAdmin>,
  slug: string,
): Promise<NextResponse | null> {
  const pencereler = [
    { suffix: "min", max: LIMIT_PER_MINUTE, seconds: 60 },
    { suffix: "hour", max: LIMIT_PER_HOUR, seconds: 3600 },
  ] as const;

  for (const pencere of pencereler) {
    const { data, error } = await admin.rpc("consume_assistant_request", {
      p_client_key: `owner_smart_engine:${slug}:${pencere.suffix}`,
      p_max_requests: pencere.max,
      p_window_seconds: pencere.seconds,
    });

    if (error) {
      console.error("[owner-smart-engine-action] rate limit failed:", error.message);
      return NextResponse.json(
        { hata: "Kaydetme servisi şu anda kullanılamıyor.", kod: "RATE_LIMIT_SERVICE_ERROR" },
        { status: 503 },
      );
    }

    const sonuc = (Array.isArray(data) ? data[0] : data) as LimitResult | null;
    if (sonuc && sonuc.allowed === false) {
      return NextResponse.json(
        {
          hata: `Çok sık güncelleme. ${sonuc.retry_after_seconds ?? 1} saniye sonra tekrar dene.`,
          kod: "RATE_LIMITED",
        },
        { status: 429 },
      );
    }
  }

  return null;
}

export async function POST(request: NextRequest) {
  let govde: {
    slug?: unknown;
    anahtar?: unknown;
    deger?: unknown;
    expectedDraftVersion?: unknown;
    actionId?: unknown;
    commandId?: unknown;
    clientId?: unknown;
  };

  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const anahtar = typeof govde.anahtar === "string" ? govde.anahtar.trim() : "";
  const actionId = typeof govde.actionId === "string" ? govde.actionId.trim() : "";
  const commandId = typeof govde.commandId === "string" ? govde.commandId.trim() : "";
  const expectedDraftVersion = govde.expectedDraftVersion;
  const clientId = typeof govde.clientId === "string" ? govde.clientId : null;

  if (
    !slug ||
    !anahtar ||
    !UUID_RE.test(actionId) ||
    !UUID_RE.test(commandId) ||
    typeof expectedDraftVersion !== "number" ||
    !Number.isSafeInteger(expectedDraftVersion) ||
    expectedDraftVersion < 1
  ) {
    return NextResponse.json(
      { hata: "Akıllı motor işlem bilgisi geçersiz.", kod: "INVALID_ACTION_PRECONDITION" },
      { status: 400 },
    );
  }

  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);
  if (!ownerSession) {
    return NextResponse.json(
      { hata: DB_HATALARI.INVALID_SESSION_TOKEN.mesaj, kod: "INVALID_SESSION_TOKEN" },
      { status: 401 },
    );
  }

  if (!(await smartEngineStorefrontServerEnabled())) {
    return NextResponse.json(
      { hata: SMART_ENGINE_DISABLED_MESSAGE, kod: "SMART_ENGINE_DISABLED" },
      { status: 503 },
    );
  }

  const validation = validateField(anahtar, govde.deger);
  if (!validation.ok) {
    return NextResponse.json(
      { hata: validation.hata, kod: "INVALID_FIELD_VALUE" },
      { status: 422 },
    );
  }

  let admin: ReturnType<typeof getSupabaseAdmin>;
  try {
    admin = getSupabaseAdmin();
  } catch (error) {
    console.error("[owner-smart-engine-action] admin unavailable", error);
    return NextResponse.json(
      { hata: "Kaydetme servisi şu anda kullanılamıyor.", kod: "SERVICE_UNAVAILABLE" },
      { status: 503 },
    );
  }

  const limitResponse = await oranSiniri(admin, slug);
  if (limitResponse) return limitResponse;

  const { data, error } = await admin.rpc("vixrex_apply_storefront_action", {
    p_session_token: ownerSession.sessionToken,
    p_field_key: validation.alan.anahtar,
    p_value: validation.deger,
    p_expected_draft_version: expectedDraftVersion,
    p_action_id: actionId,
    p_command_id: commandId,
  });

  if (error) {
    const kod = dbHataKodu(error.message);
    const hata = kod ? DB_HATALARI[kod] : null;
    console.error("[owner-smart-engine-action] authoritative mutation failed:", kod ?? "UNKNOWN");
    return NextResponse.json(
      {
        hata: hata?.mesaj ?? "Kaydedilemedi. Güncel taslağı alıp tekrar dene.",
        kod: kod ?? "UNKNOWN_MUTATION_ERROR",
      },
      { status: hata?.status ?? 500 },
    );
  }

  const sonuc = data as ActionRpcResult | null;
  if (!sonuc?.ok || !Number.isSafeInteger(sonuc.draft_version)) {
    return NextResponse.json(
      { hata: "Kaydetme sonucu doğrulanamadı.", kod: "UNKNOWN_MUTATION_OUTCOME" },
      { status: 500 },
    );
  }

  broadcastTaslakGuncellendi(slug, clientId);

  return NextResponse.json({
    tamam: true,
    replayed: sonuc.replayed === true,
    anahtar: validation.alan.anahtar,
    etiket: validation.alan.etiket,
    deger: validation.deger,
    taslakSurumu: sonuc.draft_version,
    actionId,
    commandId,
  });
}
