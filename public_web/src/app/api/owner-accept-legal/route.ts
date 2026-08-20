import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";

// Sahip oturumundan yasal onay verir (Vixrex Asistan içinden, üyelik
// paneline gitmeden). owner-publish/route.ts ile birebir aynı oturum
// deseni: token yalnız HttpOnly çerezden okunur, gövdeden ALINMAZ.
//
// Zincir:
//   istek {slug}
//   → sahip çerezi doğrulanır
//   → accept_store_legal_consent RPC'si çağrılır
//   → RPC aktif legal_documents sürümünü SUNUCUDA okuyup stores'a yazar
//   → başarıda owner-publish artık PRIVACY/TERMS/CONSENT hatası vermez
//
// Bu uç genel taslak alan düzenleme yolundan (owner-draft) AYRIDIR —
// yasal alanlar owner_forbidden_draft_keys()'te kalmaya devam eder
// (docs/vitrin-alan-semasi.md §7). Buradan yalnız TEK, dar bir eylem
// yapılır: aktif sürümü kabul et.

export const dynamic = "force-dynamic";

const HATA_METNI: Record<string, string> = {
  INVALID_SESSION_TOKEN:
    "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç.",
  DEMO_STORE_IMMUTABLE: "Bu örnek vitrin için onay verilemez.",
  LEGAL_DOCUMENT_MISSING:
    "Yasal belgeler şu an yüklenemiyor. Lütfen daha sonra tekrar dene.",
};

const DURUM_MAP: Record<string, number> = {
  INVALID_SESSION_TOKEN: 401,
  DEMO_STORE_IMMUTABLE: 409,
  LEGAL_DOCUMENT_MISSING: 503,
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

  const { error, data } = await supabaseAnon().rpc("accept_store_legal_consent", {
    p_session_token: ownerSession.sessionToken,
  });

  if (error) {
    const metin =
      HATA_METNI[error.message] ?? "Onay verilemedi. Lütfen tekrar dene.";
    // Hata kodu loglanır; oturum tokenı ve taslak içeriği loglanmaz.
    console.error("[owner-accept-legal] accept failed:", error.message);
    const durum = DURUM_MAP[error.message] ?? 500;
    return NextResponse.json({ hata: metin }, { status: durum });
  }

  return NextResponse.json({
    tamam: true,
    slug,
    kabulEdildi: (data as { accepted?: boolean } | null)?.accepted ?? false,
  });
}
