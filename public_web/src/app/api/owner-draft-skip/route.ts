import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";

// Rehberli akışta "boş geç" denen isteğe bağlı alanı kalıcı işaretler
// (Vixrex Asistan rehberli tamamlama, ADR 0002 — 3. alt-faz).
//
// `/api/owner-draft`'a paralel ama ayrı: burası vitrin İÇERİĞİ yazmıyor,
// yalnız akış durumu (hangi isteğe bağlı alan bilerek atlandı) kaydediyor.
// Bu yüzden vitrinFieldValidation'dan geçmiyor — anahtarın gerçek bir
// stores kolonuna karşılık gelmesi gerekmiyor.

export const dynamic = "force-dynamic";

const HATA_METNI: Record<string, string> = {
  INVALID_SESSION_TOKEN: "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç.",
  DEMO_STORE_IMMUTABLE: "Bu örnek vitrin düzenlenemez.",
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
  let govde: { slug?: unknown; anahtar?: unknown };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const anahtar = typeof govde.anahtar === "string" ? govde.anahtar.trim() : "";

  if (!slug || !anahtar) {
    return NextResponse.json({ hata: "Vitrin veya alan belirtilmedi." }, { status: 400 });
  }

  // Oturum YALNIZ çerezden okunur. Gövdeden gelen bir token kabul edilmez.
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

  const { error, data } = await supabaseAnon().rpc(
    "mark_working_draft_field_skipped",
    {
      p_session_token: ownerSession.sessionToken,
      p_key: anahtar,
    }
  );

  if (error) {
    const metin = HATA_METNI[error.message] ?? "Kaydedilemedi. Lütfen tekrar dene.";
    console.error("[owner-draft-skip] mark failed:", error.message);
    const durum = error.message === "INVALID_SESSION_TOKEN" ? 401 : 400;
    return NextResponse.json({ hata: metin }, { status: durum });
  }

  return NextResponse.json({
    tamam: true,
    atlananAlanlar: (data as { atlanan_alanlar?: string[] } | null)?.atlanan_alanlar ?? [],
  });
}
