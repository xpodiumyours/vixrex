import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { SMART_ENGINE_DISABLED_MESSAGE } from "@/lib/smartEngineFlags";
import { smartEngineStorefrontServerEnabled } from "@/lib/smartEngineFlagsServer";
import { validateField } from "@/lib/vitrinFieldValidation";
import { turkeyDistricts, turkeyProvinces } from "@/lib/turkeyCities";
import { broadcastTaslakGuncellendi } from "@/lib/workingDraftBroadcast";

export const dynamic = "force-dynamic";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const LIMIT_PER_MINUTE = 30;
const LIMIT_PER_HOUR = 120;

const DB_HATALARI: Record<string, { status: number; mesaj: string }> = {
  INVALID_LOCATION_PRECONDITION: { status: 400, mesaj: "Konum işlem bilgisi eksik." },
  SMART_ENGINE_DISABLED: { status: 503, mesaj: SMART_ENGINE_DISABLED_MESSAGE },
  INVALID_LOCATION_COORDINATES: { status: 422, mesaj: "GPS koordinatı geçersiz." },
  INVALID_LOCATION_ADDRESS: { status: 422, mesaj: "Adres doğrulanamadı." },
  INVALID_LOCATION_RELATION: { status: 422, mesaj: "İl ve ilçe birbiriyle eşleşmiyor." },
  INVALID_LOCATION_VALUE: { status: 422, mesaj: "Konum bilgisi sunucu doğrulamasından geçmedi." },
  LOCATION_CONTRACT_MISSING: { status: 503, mesaj: "Konum doğrulama sözleşmesi kullanılamıyor." },
  INVALID_SESSION_TOKEN: { status: 401, mesaj: "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç." },
  OWNER_AUTHORIZATION_REQUIRED: { status: 401, mesaj: "Sahip oturumu gerekli." },
  DEMO_STORE_IMMUTABLE: { status: 403, mesaj: "Bu örnek vitrin düzenlenemez." },
  WORKING_DRAFT_NOT_FOUND: { status: 404, mesaj: "Çalışma taslağı bulunamadı. Önizlemeyi tekrar aç." },
  IDEMPOTENCY_KEY_REUSE: { status: 409, mesaj: "Bu konum işlem kimliği farklı bir veri için daha önce kullanılmış." },
  DRAFT_VERSION_CONFLICT: { status: 409, mesaj: "Taslak başka bir yerde değişti. Güncel hâli alıp tekrar dene." },
};

type LimitResult = { allowed?: boolean; retry_after_seconds?: number };
type LocationRpcResult = {
  ok?: boolean;
  replayed?: boolean;
  draft_version?: number;
  command_id?: string;
  location?: Record<string, unknown>;
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
      p_client_key: `owner_location_bundle:${slug}:${pencere.suffix}`,
      p_max_requests: pencere.max,
      p_window_seconds: pencere.seconds,
    });
    if (error) {
      console.error("[owner-location-bundle] rate limit failed:", error.message);
      return NextResponse.json(
        { hata: "Konum kaydetme servisi şu anda kullanılamıyor.", kod: "RATE_LIMIT_SERVICE_ERROR" },
        { status: 503 },
      );
    }
    const sonuc = (Array.isArray(data) ? data[0] : data) as LimitResult | null;
    if (sonuc?.allowed === false) {
      return NextResponse.json(
        {
          hata: `Çok sık konum güncelleme. ${sonuc.retry_after_seconds ?? 1} saniye sonra tekrar dene.`,
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
    latitude?: unknown;
    longitude?: unknown;
    address?: unknown;
    provinceName?: unknown;
    districtName?: unknown;
    expectedDraftVersion?: unknown;
    commandId?: unknown;
    clientId?: unknown;
  };

  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const address = typeof govde.address === "string" ? govde.address.trim() : "";
  const provinceName = typeof govde.provinceName === "string" ? govde.provinceName.trim() : "";
  const districtName = typeof govde.districtName === "string" ? govde.districtName.trim() : "";
  const commandId = typeof govde.commandId === "string" ? govde.commandId.trim() : "";
  const clientId = typeof govde.clientId === "string" ? govde.clientId : null;
  const expectedDraftVersion = govde.expectedDraftVersion;
  const latitude = govde.latitude;
  const longitude = govde.longitude;

  if (
    !slug ||
    !UUID_RE.test(commandId) ||
    typeof expectedDraftVersion !== "number" ||
    !Number.isSafeInteger(expectedDraftVersion) ||
    expectedDraftVersion < 1 ||
    typeof latitude !== "number" ||
    !Number.isFinite(latitude) ||
    typeof longitude !== "number" ||
    !Number.isFinite(longitude)
  ) {
    return NextResponse.json(
      { hata: "Konum işlem bilgisi geçersiz.", kod: "INVALID_LOCATION_PRECONDITION" },
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

  const province = turkeyProvinces.find((item) => item.name === provinceName);
  if (!province || !(turkeyDistricts[province.code] ?? []).includes(districtName)) {
    return NextResponse.json(
      { hata: DB_HATALARI.INVALID_LOCATION_RELATION.mesaj, kod: "INVALID_LOCATION_RELATION" },
      { status: 422 },
    );
  }

  const validations = [
    validateField("enlem", latitude),
    validateField("boylam", longitude),
    validateField("adres", address),
    validateField("il", provinceName),
    validateField("ilce", districtName),
  ];
  const invalid = validations.find((validation) => !validation.ok);
  if (invalid && !invalid.ok) {
    return NextResponse.json(
      { hata: invalid.hata, kod: "INVALID_LOCATION_VALUE" },
      { status: 422 },
    );
  }

  let admin: ReturnType<typeof getSupabaseAdmin>;
  try {
    admin = getSupabaseAdmin();
  } catch (error) {
    console.error("[owner-location-bundle] admin unavailable", error);
    return NextResponse.json(
      { hata: "Konum kaydetme servisi şu anda kullanılamıyor.", kod: "SERVICE_UNAVAILABLE" },
      { status: 503 },
    );
  }

  const limitResponse = await oranSiniri(admin, slug);
  if (limitResponse) return limitResponse;

  const { data, error } = await admin.rpc("vixrex_apply_location_bundle", {
    p_session_token: ownerSession.sessionToken,
    p_latitude: latitude,
    p_longitude: longitude,
    p_address: address,
    p_province_code: province.code,
    p_province_name: province.name,
    p_district_name: districtName,
    p_expected_draft_version: expectedDraftVersion,
    p_command_id: commandId,
  });

  if (error) {
    const kod = dbHataKodu(error.message);
    const hata = kod ? DB_HATALARI[kod] : null;
    console.error("[owner-location-bundle] authoritative mutation failed:", kod ?? "UNKNOWN");
    return NextResponse.json(
      {
        hata: hata?.mesaj ?? "Konum kaydedilemedi. Güncel taslağı alıp tekrar dene.",
        kod: kod ?? "UNKNOWN_MUTATION_ERROR",
      },
      { status: hata?.status ?? 500 },
    );
  }

  const sonuc = data as LocationRpcResult | null;
  if (!sonuc?.ok || !Number.isSafeInteger(sonuc.draft_version)) {
    return NextResponse.json(
      { hata: "Konum kaydetme sonucu doğrulanamadı.", kod: "UNKNOWN_MUTATION_OUTCOME" },
      { status: 500 },
    );
  }

  broadcastTaslakGuncellendi(slug, clientId);

  return NextResponse.json({
    tamam: true,
    replayed: sonuc.replayed === true,
    taslakSurumu: sonuc.draft_version,
    commandId,
    location: sonuc.location ?? {
      enlem: latitude,
      boylam: longitude,
      adres: address,
      il: province.name,
      ilce: districtName,
      province_code: province.code,
    },
  });
}
