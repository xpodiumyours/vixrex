import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { FIELD_BY_KEY, type VitrinField } from "@/lib/vitrinFieldSchema";
import { broadcastTaslakGuncellendi } from "@/lib/workingDraftBroadcast";

// Vixrex Assistant "Geri al" kapısı.
//
// Eski owner-draft-restore canlı stores değerine döner ve Assistant'tan ÖNCE
// taslakta bulunan değeri kaybedebilir. Bu route eski değer KABUL ETMEZ.
// Yalnız alan anahtarlarını alır; gerçek önceki değerler DB'deki son undo
// kaydından gelir. RPC ayrıca draft_version eşleşmesini zorunlu tutar, yani
// arada başka cihaz/sekme yazdıysa yeni veriyi ezmek yerine fail-closed olur.

export const dynamic = "force-dynamic";

const MAX_UNDO_FIELDS = 20;

const HATA_METNI: Record<string, string> = {
  INVALID_SESSION_TOKEN: "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç.",
  DEMO_STORE_IMMUTABLE: "Bu örnek vitrin düzenlenemez.",
  INVALID_UNDO_KEYS: "Geri alınacak alan listesi geçersiz.",
  UNDO_NOT_AVAILABLE: "Geri alınacak son işlem bulunamadı veya geri alma süresi doldu.",
  UNDO_NOT_LATEST:
    "Bu işlemden sonra başka bir değişiklik yapıldı. Yeni veriyi ezmemek için geri alma uygulanmadı.",
  UNDO_STALE:
    "Bu işlemden sonra başka bir değişiklik yapıldı. Yeni veriyi ezmemek için geri alma uygulanmadı.",
  INVALID_UNDO_RECORD: "Geri alma kaydı doğrulanamadı.",
  FIELD_NOT_EDITABLE: "Bu alan geri alınamaz.",
  UNKNOWN_FIELD: "Bilinmeyen alan.",
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
  anahtarlar?: unknown;
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
  const clientId = typeof govde.clientId === "string" ? govde.clientId : null;
  const hamAnahtarlar = Array.isArray(govde.anahtarlar)
    ? govde.anahtarlar.filter((v): v is string => typeof v === "string")
    : [];

  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }
  if (hamAnahtarlar.length < 1 || hamAnahtarlar.length > MAX_UNDO_FIELDS) {
    return NextResponse.json({ hata: HATA_METNI.INVALID_UNDO_KEYS }, { status: 422 });
  }

  const gorulen = new Set<string>();
  const alanlar: VitrinField[] = [];
  for (const ham of hamAnahtarlar) {
    const anahtar = ham.trim();
    if (!anahtar || gorulen.has(anahtar)) {
      return NextResponse.json({ hata: HATA_METNI.INVALID_UNDO_KEYS }, { status: 422 });
    }
    gorulen.add(anahtar);
    const alan = FIELD_BY_KEY.get(anahtar);
    if (!alan) {
      return NextResponse.json({ hata: "Bilinmeyen alan." }, { status: 422 });
    }
    alanlar.push(alan);
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

  // İstemci alan anahtarı yollar; DB yalnız gerçek kolon adlarını görür.
  const kolonlar = alanlar.map((alan) => alan.kolon);
  const { data, error } = await supabaseAnon().rpc(
    "undo_latest_working_draft_change",
    {
      p_session_token: ownerSession.sessionToken,
      p_keys: kolonlar,
    }
  );

  if (error) {
    const metin = HATA_METNI[error.message] ?? "Geri alınamadı. Lütfen tekrar dene.";
    console.error("[owner-draft-undo] undo failed:", error.message);
    const durum = error.message === "INVALID_SESSION_TOKEN" ? 401 : 409;
    return NextResponse.json({ hata: metin }, { status: durum });
  }

  const sonuc = (data ?? {}) as {
    restored_values?: Record<string, unknown>;
    draft_version?: number;
  };
  const restoredValues =
    sonuc.restored_values && typeof sonuc.restored_values === "object"
      ? sonuc.restored_values
      : {};

  broadcastTaslakGuncellendi(slug, clientId);

  return NextResponse.json({
    tamam: true,
    degisiklikler: alanlar.map((alan) => ({
      anahtar: alan.anahtar,
      kolon: alan.kolon,
      etiket: alan.etiket,
      deger: Object.prototype.hasOwnProperty.call(restoredValues, alan.kolon)
        ? restoredValues[alan.kolon]
        : null,
    })),
    taslakSurumu: sonuc.draft_version ?? null,
  });
}
