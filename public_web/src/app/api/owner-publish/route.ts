import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";
import { createClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";

// Sahip çalışma taslağını canlı vitrine yayınlar (implementation_plan.md Faz 11).
//
// Zincir:
//   istek {slug}
//   → HttpOnly sahip çerezi doğrulanır (gövdeden token ALINMAZ)
//   → publish_working_draft RPC'si çağrılır
//   → veritabanı kendi bağımsız yetki ve yasal onay kontrolünü yapar
//   → başarıda /v/:slug önbelleği tazelenir (revalidatePath — dış /api/revalidate
//     çağrısı yapılmaz, o uç secret ister ve başka amaç içindir)
//
// Yasal onay hataları (PRIVACY_NOTICE_*, TERMS_*, PUBLICATION_CONSENT_*)
// artık Vixrex Asistan'dan da giderilebilir — bkz. /api/owner-accept-legal
// (accept_store_legal_consent RPC'si). Bu hatalar normalde PublishBar'daki
// onay kutusu işaretlenmeden Yayınla'ya basılırsa görülür; istemci zaten
// onay durumunu draftData'dan okuyup düğmeyi ona göre gösterir, buradaki
// mesaj yalnız RPC'nin kendi bağımsız kontrolü tetiklenirse (savunma
// katmanı) görünür.
//
// Loglama yalnız error.message; oturum tokenı ve taslak içeriği ASLA loglanmaz.

export const dynamic = "force-dynamic";

const HATA_METNI: Record<string, string> = {
  INVALID_SESSION_TOKEN:
    "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç.",
  DEMO_STORE_IMMUTABLE: "Bu örnek vitrin yayınlanamaz.",
  WORKING_DRAFT_NOT_FOUND: "Yayınlanacak bir değişiklik yok.",
  DRAFT_STALE:
    "Vitrinin başka bir yerden değiştirilmiş. Sayfayı yenileyip değişikliklerini tekrar yap.",
  PRIVACY_NOTICE_REQUIRED:
    "Yayınlamak için önce yasal onay kutusunu işaretlemen gerekiyor.",
  TERMS_ACCEPTANCE_REQUIRED:
    "Yayınlamak için önce yasal onay kutusunu işaretlemen gerekiyor.",
  PUBLICATION_CONSENT_REQUIRED:
    "Yayınlamak için önce yasal onay kutusunu işaretlemen gerekiyor.",
  PRIVACY_NOTICE_VERSION_INVALID:
    "Sözleşme metinleri güncellenmiş. Onay kutusunu tekrar işaretleyip yeniden dene.",
  TERMS_VERSION_INVALID:
    "Sözleşme metinleri güncellenmiş. Onay kutusunu tekrar işaretleyip yeniden dene.",
  PUBLICATION_CONSENT_VERSION_INVALID:
    "Sözleşme metinleri güncellenmiş. Onay kutusunu tekrar işaretleyip yeniden dene.",
  PREMIUM_REQUIRED:
    "Bu hazır vitrin yalnız premium üyelikle yayınlanır. Aylık 299 TL ile devam et.",
};

const DURUM_MAP: Record<string, number> = {
  INVALID_SESSION_TOKEN: 401,
  PREMIUM_REQUIRED: 402,
  DRAFT_STALE: 409,
  PRIVACY_NOTICE_REQUIRED: 422,
  TERMS_ACCEPTANCE_REQUIRED: 422,
  PUBLICATION_CONSENT_REQUIRED: 422,
  PRIVACY_NOTICE_VERSION_INVALID: 422,
  TERMS_VERSION_INVALID: 422,
  PUBLICATION_CONSENT_VERSION_INVALID: 422,
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

  const { error, data } = await supabaseAnon().rpc("publish_working_draft", {
    p_session_token: ownerSession.sessionToken,
  });

  if (error) {
    const metin =
      HATA_METNI[error.message] ?? "Yayınlanamadı. Lütfen tekrar dene.";
    // Hata kodu loglanır; oturum tokenı ve taslak içeriği loglanmaz.
    console.error("[owner-publish] publish failed:", error.message);
    const durum = DURUM_MAP[error.message] ?? 400;
    return NextResponse.json({ hata: metin }, { status: durum });
  }

  // Canlı satır değişti — /v/:slug önbelleği tazelenir.
  revalidatePath(`/v/${slug}`);

  return NextResponse.json({
    tamam: true,
    slug,
    canliSurum: (data as { live_version?: number } | null)?.live_version ?? null,
  });
}
