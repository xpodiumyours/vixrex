import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";
import {
  assertOwnerSessionConfigured,
  OWNER_SESSION_COOKIE,
  OWNER_SESSION_MAX_AGE_SECONDS,
  signOwnerSession,
} from "@/lib/ownerSession";

// Sahip giriş rotası (implementation_plan.md §5.2, Commit 4 & 7).
//
// Zincir: Flutter tek kullanımlık kod → consume_owner_session
//   → 256-bit session_token (tek kez döner) → SHA-256 hash DB'ye
//   → Next.js session_token'ı HMAC imzalı HttpOnly çerez payload'ına koyar
//   → page.tsx çerezi doğrular, payload içindeki session_token alır
//   → Supabase RPC tokenı hashleyerek owner_sessions kaydıyla eşleştirir
//   → çalışma taslağını döndürür
//   → herhangi bir halka başarısızsa owner modu fail-closed kapanır.

export const dynamic = "force-dynamic";

const ERROR_COPY: Record<string, string> = {
  INVALID_SLUG: "Vitrin bulunamadı.",
  INVALID_OWNER_CODE: "Önizleme bağlantısında kod eksik.",
  INVALID_OR_EXPIRED_OWNER_CODE:
    "Bu önizleme bağlantısı geçersiz, kullanılmış veya süresi dolmuş.",
};

interface ConsumeOwnerSessionResult {
  store_id: string;
  slug: string;
  session_token: string;
}

function ownerErrorPage(title: string, message: string): Response {
  const html = `<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta name="robots" content="noindex" />
<title>Önizleme Bağlantısı Geçersiz</title>
<style>
  body { margin: 0; background: #0B1120; color: #fff; font-family: system-ui, -apple-system, sans-serif; display: grid; place-items: center; min-height: 100vh; }
  main { max-width: 420px; padding: 24px; text-align: center; }
  h1 { font-size: 20px; }
  p { color: rgba(255,255,255,0.7); line-height: 1.6; }
</style>
</head>
<body>
<main>
  <h1>${title}</h1>
  <p>${message}</p>
  <p>Lütfen uygulamadan <strong>Önizle</strong> düğmesine tekrar dokunun.</p>
</main>
</body>
</html>`;

  return new Response(html, {
    status: 400,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

export async function GET(request: Request) {
  const url = new URL(request.url);
  const slug = url.searchParams.get("slug")?.trim() ?? "";
  const code = url.searchParams.get("ocode")?.trim() ?? "";

  if (!slug) {
    return ownerErrorPage(
      "Vitrin bulunamadı",
      "Önizleme bağlantısında vitrin bilgisi eksik."
    );
  }
  if (!code) {
    return ownerErrorPage(
      "Kod eksik",
      "Önizleme bağlantısında sahip kodu eksik."
    );
  }

  try {
    assertOwnerSessionConfigured();
  } catch (err) {
    console.error("[owner-session] configuration invalid", err);
    return ownerErrorPage(
      "Önizleme açılamadı",
      "Sunucu sahip oturumunu oluşturamadı. Lütfen tekrar dene."
    );
  }

  const { data, error } = await supabase.rpc("consume_owner_session", {
    p_slug: slug,
    p_code: code,
  });

  if (error) {
    const message =
      ERROR_COPY[error.message] ??
      "Önizleme açılamadı. Lütfen tekrar dene.";
    return ownerErrorPage("Önizleme bağlantısı geçersiz", message);
  }

  const session = data as ConsumeOwnerSessionResult | null;
  if (!session?.store_id || !session.session_token) {
    return ownerErrorPage(
      "Önizleme bağlantısı geçersiz",
      ERROR_COPY.INVALID_OR_EXPIRED_OWNER_CODE
    );
  }

  // Veritabanının döndürdüğü slug ile istek slug'ını doğrula
  if (session.slug !== slug) {
    return ownerErrorPage(
      "Önizleme bağlantısı geçersiz",
      "Slug uyuşmazlığı."
    );
  }

  let token: string;
  try {
    // HMAC payload: storeId, slug, sessionToken, exp
    token = signOwnerSession(session.store_id, session.slug, session.session_token);
  } catch (err) {
    console.error("[owner-session] signOwnerSession failed");
    return ownerErrorPage(
      "Önizleme açılamadı",
      "Sunucu sahip oturumunu oluşturamadı. Lütfen tekrar dene."
    );
  }

  const destination = new URL(`/v/${slug}`, url);
  const response = NextResponse.redirect(destination, 303);
  response.headers.set("cache-control", "no-store");
  response.cookies.set(OWNER_SESSION_COOKIE, token, {
    httpOnly: true,
    secure: true,
    sameSite: "lax",
    path: "/",
    maxAge: OWNER_SESSION_MAX_AGE_SECONDS,
  });

  // session_token loga/hata mesajına GİRMESİN
  return response;
}