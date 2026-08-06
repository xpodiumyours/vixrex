import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@supabase/supabase-js";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { validateField } from "@/lib/vitrinFieldValidation";

// Sahip çalışma taslağında tek alan günceller (implementation_plan.md Commit 8).
//
// Zincir:
//   istek {slug, anahtar, deger}
//   → HttpOnly sahip çerezi doğrulanır (gövdeden token ALINMAZ)
//   → değer şemaya göre doğrulanır (vitrinFieldValidation)
//   → update_working_draft_field RPC'si çağrılır
//   → veritabanı kendi bağımsız yetki kontrolünü yapar
//
// Alan başına dallanma YOKTUR. Yeni alan eklemek için bu dosya değişmez;
// yalnız vitrinFieldSchema.ts'e satır eklenir.

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
  let govde: { slug?: unknown; anahtar?: unknown; deger?: unknown };
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
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);

  if (!ownerSession) {
    return NextResponse.json(
      { hata: HATA_METNI.INVALID_SESSION_TOKEN },
      { status: 401 }
    );
  }

  // Şema doğrulaması — tek fonksiyon, alan başına dallanma yok.
  const sonuc = validateField(anahtar, govde.deger);
  if (!sonuc.ok) {
    return NextResponse.json({ hata: sonuc.hata }, { status: 422 });
  }

  const { error, data } = await supabaseAnon().rpc("update_working_draft_field", {
    p_session_token: ownerSession.sessionToken,
    p_key: sonuc.alan.kolon,
    p_value: sonuc.deger,
  });

  if (error) {
    const metin = HATA_METNI[error.message] ?? "Kaydedilemedi. Lütfen tekrar dene.";
    // Hata mesajı loglanır; oturum tokenı ve alan değeri loglanmaz.
    console.error("[owner-draft] update failed:", error.message);
    const durum = error.message === "INVALID_SESSION_TOKEN" ? 401 : 400;
    return NextResponse.json({ hata: metin }, { status: durum });
  }

  return NextResponse.json({
    tamam: true,
    anahtar: sonuc.alan.anahtar,
    etiket: sonuc.alan.etiket,
    deger: sonuc.deger,
    taslakSurumu: (data as { draft_version?: number } | null)?.draft_version ?? null,
  });
}
