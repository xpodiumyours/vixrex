import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";
import { createClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";

// Sahip çalışma taslağını siler; canlı vitrine dokunmaz (implementation_plan.md Faz 11).
//
// Zincir:
//   istek {slug}
//   → HttpOnly sahip çerezi doğrulanır (gövdeden token ALINMAZ)
//   → discard_working_draft RPC'si çağrılır — YALNIZ taslak satırını siler,
//     public.stores'a tek bir yazma yapmaz (migration yorumu).
//   → başarıda /v/:slug önbelleği tazelenir
//
// Loglama yalnız error.message; oturum tokenı asla loglanmaz.

export const dynamic = "force-dynamic";

const HATA_METNI: Record<string, string> = {
  INVALID_SESSION_TOKEN:
    "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç.",
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
  let govde: { slug?: unknown };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";

  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
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

  const { error, data } = await supabaseAnon().rpc("discard_working_draft", {
    p_session_token: ownerSession.sessionToken,
  });

  if (error) {
    const metin =
      HATA_METNI[error.message] ?? "Değişiklikler geri alınamadı. Lütfen tekrar dene.";
    // Hata kodu loglanır; oturum tokenı loglanmaz.
    console.error("[owner-discard] discard failed:", error.message);
    const durum = error.message === "INVALID_SESSION_TOKEN" ? 401 : 400;
    return NextResponse.json({ hata: metin }, { status: durum });
  }

  revalidatePath(`/v/${slug}`);

  return NextResponse.json({
    tamam: true,
    silindi: (data as { discarded?: boolean } | null)?.discarded ?? false,
  });
}
