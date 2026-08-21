import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";
import { broadcastTaslakGuncellendi } from "@/lib/workingDraftBroadcast";

export const dynamic = "force-dynamic";

const HATA_METNI: Record<string, string> = {
  INVALID_SESSION_TOKEN: "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç.",
  DEMO_STORE_IMMUTABLE: "Bu örnek vitrin düzenlenemez.",
  FIELD_NOT_EDITABLE: "Bu alan düzenlenemez.",
  UNKNOWN_FIELD: "Bilinmeyen alan.",
  INVALID_FIELD_KEY: "Alan adı eksik.",
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

export async function POST(request: NextRequest) {
  let govde: { slug?: unknown; anahtar?: unknown; clientId?: unknown };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const anahtar = typeof govde.anahtar === "string" ? govde.anahtar.trim() : "";
  const clientId = typeof govde.clientId === "string" ? govde.clientId : null;

  if (!slug || !anahtar) {
    return NextResponse.json({ hata: "Vitrin veya alan belirtilmedi." }, { status: 400 });
  }

  const alan = FIELD_BY_KEY.get(anahtar);
  if (!alan) {
    return NextResponse.json({ hata: "Bilinmeyen alan." }, { status: 422 });
  }

  // Oturum yalnız HttpOnly sahip çerezinden gelir; gövdeden token kabul edilmez.
  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);

  if (!ownerSession) {
    return NextResponse.json(
      { hata: HATA_METNI.INVALID_SESSION_TOKEN },
      { status: 401 }
    );
  }

  const { error, data } = await supabaseAnon().rpc("restore_working_draft_field", {
    p_session_token: ownerSession.sessionToken,
    p_key: alan.kolon,
  });

  if (error) {
    console.error("[owner-draft-restore] restore failed:", error.message);
    const durum = error.message === "INVALID_SESSION_TOKEN" ? 401 : 400;
    return NextResponse.json(
      { hata: HATA_METNI[error.message] ?? "Canlı hâline döndürülemedi." },
      { status: durum }
    );
  }

  const sonuc = data as {
    changed?: boolean;
    value?: unknown;
    draft_version?: number;
  } | null;
  const degisti = sonuc?.changed === true;

  if (degisti) {
    broadcastTaslakGuncellendi(slug, clientId);
  }

  return NextResponse.json({
    tamam: true,
    degisti,
    anahtar: alan.anahtar,
    etiket: alan.etiket,
    deger: sonuc?.value ?? null,
    taslakSurumu: sonuc?.draft_version ?? null,
  });
}
