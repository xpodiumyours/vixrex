import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";
import { createClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";

// Sahip taslağını CANLI vitrinden tazeler (tur bulgusu 10).
//
// SORUN
// Taslak bir kez oluşturuluyordu — o anki vitrinin kopyası olarak. Esnaf
// manuel panelden yayınladığı her şey `stores`a yazılıyor ama taslak eski
// hâlde kalıyordu. Turuncu kutu farkı bildiriyor, ama "Yeniden Yükle"
// aynı eski taslağı tekrar getiriyordu — uyarının çaresi yoktu.
//
// Casper 2026-08-07: "canlı vitrin değişmiş taslak sürümü eski diye bir
// turuncu kutucuk içinde yeniden yükle uyarısı veriyor ama yeniden
// yükleme ile ... next.js ekrana gelmiyor."
//
// Tek çıkış "Değişiklikleri bırak"tı; esnaf için o "işimi kaybedeceğim"
// demek, kimse basmaz.
//
// Zincir: istek {slug} → HttpOnly sahip çerezi doğrulanır (gövdeden
// token ALINMAZ) → refresh_working_draft RPC → /v/:slug tazelenir.
//
// Loglama yalnız error.message; oturum tokenı asla loglanmaz.

export const dynamic = "force-dynamic";

const HATA_METNI: Record<string, string> = {
  INVALID_SESSION_TOKEN:
    "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç.",
  STORE_NOT_FOUND: "Vitrin bulunamadı.",
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

  const { error, data } = await supabaseAnon().rpc("refresh_working_draft", {
    p_session_token: ownerSession.sessionToken,
  });

  if (error) {
    const metin =
      HATA_METNI[error.message] ??
      "Taslak tazelenemedi. Lütfen tekrar dene.";
    console.error("[owner-refresh] refresh failed:", error.message);
    const durum = error.message === "INVALID_SESSION_TOKEN" ? 401 : 400;
    return NextResponse.json({ hata: metin }, { status: durum });
  }

  revalidatePath(`/v/${slug}`);

  return NextResponse.json({
    tamam: true,
    degisenAlan:
      (data as { degisen_alan?: number } | null)?.degisen_alan ?? 0,
  });
}
