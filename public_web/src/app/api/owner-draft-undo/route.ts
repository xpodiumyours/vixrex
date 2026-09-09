import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { VITRIN_FIELDS } from "@/lib/vitrinFieldSchema";
import { broadcastTaslakGuncellendi } from "@/lib/workingDraftBroadcast";

// Vixrex Assistant command-bazlı "Geri al" kapısı.
//
// İstemci eski değer veya alan listesi göndermez. Yalnız batch yazımında
// sunucunun döndürdüğü commandId gelir. DB o command'ın kendi undo kaydını
// bulur ve draft_version hâlâ uygunsa geri alır. Böylece aynı alan art arda
// iki Assistant command'ında değiştirilse bile eski kart yeni command'ı geri
// alamaz.

export const dynamic = "force-dynamic";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const FIELD_BY_COLUMN = new Map(VITRIN_FIELDS.map((alan) => [alan.kolon, alan]));

const HATA_METNI: Record<string, string> = {
  INVALID_SESSION_TOKEN: "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç.",
  DEMO_STORE_IMMUTABLE: "Bu örnek vitrin düzenlenemez.",
  INVALID_UNDO_PRECONDITION: "Geri alma işlem kimliği geçersiz.",
  UNDO_COMMAND_NOT_FOUND: "Bu işleme ait geri alma kaydı bulunamadı.",
  UNDO_ALREADY_CONSUMED: "Bu işlem zaten geri alınmış.",
  UNDO_NOT_AVAILABLE: "Geri alma süresi doldu.",
  UNDO_STALE:
    "Bu işlemden sonra başka bir değişiklik yapıldı. Yeni veriyi ezmemek için geri alma uygulanmadı.",
  INVALID_UNDO_RECORD: "Geri alma kaydı doğrulanamadı.",
  FIELD_NOT_EDITABLE: "Bu alan geri alınamaz.",
  WORKING_DRAFT_NOT_FOUND: "Çalışma taslağı bulunamadı. Önizlemeyi tekrar açın.",
};

function supabaseAnon() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || "",
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
      process.env.SUPABASE_PUBLISHABLE_KEY ||
      ""
  );
}

interface UndoBody {
  slug?: unknown;
  commandId?: unknown;
  clientId?: unknown;
}

export async function POST(request: NextRequest) {
  let govde: UndoBody;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const commandId =
    typeof govde.commandId === "string" ? govde.commandId.trim() : "";
  const clientId = typeof govde.clientId === "string" ? govde.clientId : null;

  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }
  if (!UUID_RE.test(commandId)) {
    return NextResponse.json(
      { hata: HATA_METNI.INVALID_UNDO_PRECONDITION },
      { status: 422 }
    );
  }

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

  const { data, error } = await supabaseAnon().rpc(
    "undo_working_draft_command",
    {
      p_session_token: ownerSession.sessionToken,
      p_command_id: commandId,
    }
  );

  if (error) {
    const metin = HATA_METNI[error.message] ?? "Geri alınamadı. Lütfen tekrar dene.";
    console.error("[owner-draft-undo] command undo failed:", error.message);
    const durum = error.message === "INVALID_SESSION_TOKEN" ? 401 : 409;
    return NextResponse.json({ hata: metin }, { status: durum });
  }

  const sonuc = (data ?? {}) as {
    command_id?: string;
    changed_keys?: unknown;
    restored_values?: Record<string, unknown>;
    draft_version?: number;
    replayed?: boolean;
  };
  const restoredValues =
    sonuc.restored_values && typeof sonuc.restored_values === "object"
      ? sonuc.restored_values
      : {};
  const changedColumns = Array.isArray(sonuc.changed_keys)
    ? sonuc.changed_keys.filter((v): v is string => typeof v === "string")
    : Object.keys(restoredValues);

  const degisiklikler = [];
  for (const kolon of changedColumns) {
    const alan = FIELD_BY_COLUMN.get(kolon);
    if (!alan) {
      console.error("[owner-draft-undo] canonical field missing for column:", kolon);
      return NextResponse.json(
        { hata: "Geri alma sonucu alan şemasıyla doğrulanamadı." },
        { status: 500 }
      );
    }
    degisiklikler.push({
      anahtar: alan.anahtar,
      kolon: alan.kolon,
      etiket: alan.etiket,
      deger: Object.prototype.hasOwnProperty.call(restoredValues, kolon)
        ? restoredValues[kolon]
        : null,
    });
  }

  broadcastTaslakGuncellendi(slug, clientId);

  return NextResponse.json({
    tamam: true,
    commandId: sonuc.command_id ?? commandId,
    replayed: sonuc.replayed === true,
    degisiklikler,
    taslakSurumu: sonuc.draft_version ?? null,
  });
}
