import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { SMART_ENGINE_DISABLED_MESSAGE } from "@/lib/smartEngineFlags";
import { smartEngineStorefrontServerEnabled } from "@/lib/smartEngineFlagsServer";
import { broadcastTaslakGuncellendi } from "@/lib/workingDraftBroadcast";

export const dynamic = "force-dynamic";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const DB_HATALARI: Record<string, { status: number; mesaj: string }> = {
  INVALID_UNDO_PRECONDITION: { status: 400, mesaj: "Geri alma işlem bilgisi geçersiz." },
  SMART_ENGINE_DISABLED: { status: 503, mesaj: SMART_ENGINE_DISABLED_MESSAGE },
  INVALID_SESSION_TOKEN: { status: 401, mesaj: "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç." },
  OWNER_AUTHORIZATION_REQUIRED: { status: 401, mesaj: "Sahip oturumu gerekli." },
  DEMO_STORE_IMMUTABLE: { status: 403, mesaj: "Bu örnek vitrin düzenlenemez." },
  WORKING_DRAFT_NOT_FOUND: { status: 404, mesaj: "Çalışma taslağı bulunamadı. Önizlemeyi tekrar aç." },
  UNDO_COMMAND_NOT_FOUND: { status: 404, mesaj: "Geri alınacak akıllı motor işlemi bulunamadı." },
  UNDO_CONFLICT: { status: 409, mesaj: "Bu alanlardan biri daha sonra değiştirildiği için işlem güvenle geri alınamadı." },
};

type UndoRpcResult = {
  ok?: boolean;
  replayed?: boolean;
  draft_version?: number;
  rolled_back_action_count?: number;
};

function dbHataKodu(message: string): string | null {
  return Object.keys(DB_HATALARI).find((kod) => message.includes(kod)) ?? null;
}

export async function POST(request: NextRequest) {
  let govde: { slug?: unknown; commandId?: unknown; clientId?: unknown };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const commandId = typeof govde.commandId === "string" ? govde.commandId.trim() : "";
  const clientId = typeof govde.clientId === "string" ? govde.clientId : null;

  if (!slug || !UUID_RE.test(commandId)) {
    return NextResponse.json(
      { hata: DB_HATALARI.INVALID_UNDO_PRECONDITION.mesaj, kod: "INVALID_UNDO_PRECONDITION" },
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

  let admin: ReturnType<typeof getSupabaseAdmin>;
  try {
    admin = getSupabaseAdmin();
  } catch (error) {
    console.error("[owner-smart-engine-undo] admin unavailable", error);
    return NextResponse.json(
      { hata: "Geri alma servisi şu anda kullanılamıyor.", kod: "SERVICE_UNAVAILABLE" },
      { status: 503 },
    );
  }

  const { data, error } = await admin.rpc("vixrex_undo_storefront_command", {
    p_session_token: ownerSession.sessionToken,
    p_command_id: commandId,
  });

  if (error) {
    const kod = dbHataKodu(error.message);
    const hata = kod ? DB_HATALARI[kod] : null;
    console.error("[owner-smart-engine-undo] authoritative undo failed:", kod ?? "UNKNOWN");
    return NextResponse.json(
      {
        hata: hata?.mesaj ?? "İşlem geri alınamadı. Güncel taslağı alıp tekrar dene.",
        kod: kod ?? "UNKNOWN_UNDO_ERROR",
      },
      { status: hata?.status ?? 500 },
    );
  }

  const sonuc = data as UndoRpcResult | null;
  if (!sonuc?.ok || !Number.isSafeInteger(sonuc.draft_version)) {
    return NextResponse.json(
      { hata: "Geri alma sonucu doğrulanamadı.", kod: "UNKNOWN_UNDO_OUTCOME" },
      { status: 500 },
    );
  }

  broadcastTaslakGuncellendi(slug, clientId);

  return NextResponse.json({
    tamam: true,
    replayed: sonuc.replayed === true,
    commandId,
    taslakSurumu: sonuc.draft_version,
    geriAlinanIslemSayisi: sonuc.rolled_back_action_count ?? 0,
  });
}
