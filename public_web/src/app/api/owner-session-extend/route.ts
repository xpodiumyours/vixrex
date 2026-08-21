import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { supabase } from "@/lib/supabase";
import {
  OWNER_SESSION_COOKIE,
  OWNER_SESSION_MAX_AGE_SECONDS,
  OWNER_SESSION_TTL_MS,
  signOwnerSession,
  verifyOwnerSession,
} from "@/lib/ownerSession";

// Sahip oturumunu aktif kullanımda kaydırmalı biçimde uzatır ("bankacılık
// usulü" oturum — Casper 2026-08-13 ürün kararı).
//
// OwnerWorkspaceShell panel açıkken (sekme görünürken) bunu birkaç dakikada
// bir sessizce çağırır. Hem veritabanındaki oturum kaydı (owner_sessions)
// hem Next.js çerezi AYNI ANDA uzatılır — biri diğerine göre daha uzun
// yaşarsa tutarsız bir durum oluşur (çerez geçerli görünür ama veritabanı
// reddeder, ya da tam tersi).
//
// Süresi zaten dolmuş bir oturum canlandırılmaz — yalnız hâlâ aktif olan
// uzatılır. Loglama yalnız error.message; oturum tokenı asla loglanmaz.

export const dynamic = "force-dynamic";

const HATA_METNI: Record<string, string> = {
  INVALID_SESSION_TOKEN: "Oturumun süresi dolmuş. Önizlemeyi tekrar aç.",
};

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

  const { error } = await supabase.rpc("extend_owner_session", {
    p_session_token: ownerSession.sessionToken,
  });

  if (error) {
    const metin = HATA_METNI[error.message] ?? "Oturum uzatılamadı.";
    console.error("[owner-session-extend] extend failed:", error.message);
    const durum = error.message === "INVALID_SESSION_TOKEN" ? 401 : 400;
    return NextResponse.json({ hata: metin }, { status: durum });
  }

  // Veritabanı uzatmayı kabul etti — çerezi de aynı pencereyle tekrar imzala.
  let token: string;
  try {
    token = signOwnerSession(
      ownerSession.storeId,
      ownerSession.slug,
      ownerSession.sessionToken
    );
  } catch {
    console.error("[owner-session-extend] signOwnerSession failed");
    return NextResponse.json({ hata: "Oturum uzatılamadı." }, { status: 500 });
  }

  const response = NextResponse.json({
    tamam: true,
    expiresAt: Date.now() + OWNER_SESSION_TTL_MS,
  });
  response.headers.set("cache-control", "no-store");
  response.cookies.set(OWNER_SESSION_COOKIE, token, {
    httpOnly: true,
    secure: true,
    sameSite: "lax",
    path: "/",
    maxAge: OWNER_SESSION_MAX_AGE_SECONDS,
  });

  return response;
}
