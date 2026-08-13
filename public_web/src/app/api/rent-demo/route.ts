import { NextResponse } from "next/server";
import crypto from "node:crypto";
import { supabase } from "@/lib/supabase";

// "Bu vitrini kirala" — Keşfet ekranındaki demo vitrin kartından açılır.
//
// Zincir:
//   Flutter (VitrinStoreCard) → bu rota (?slug=<demo-slug>)
//   → clone_demo_store_as_draft RPC (demoyu taslak olarak kopyalar,
//     zengin içerik dahil — bkz. migration'daki gerekçe)
//   → create_owner_session RPC (yeni kopya için tek kullanımlık kod)
//   → /api/owner-session'a yönlendirir (mevcut rota, hiç değişmedi)
//   → orası çerezi kurar, Vixrex Asistan'ı açar.
//
// Demo satırının KENDİSİ hiçbir zaman sahip oturumu alamaz — veritabanı
// bunu zaten reddediyor (DEMO_STORE_IMMUTABLE, _create_owner_session_core).
// Bu rota o yüzden önce KOPYALAR, sonra kopyanın oturumunu açar.

export const dynamic = "force-dynamic";

const ERROR_COPY: Record<string, string> = {
  INVALID_SLUG: "Vitrin bulunamadı.",
  SOURCE_NOT_FOUND: "Bu vitrin artık kiralık örnek olarak mevcut değil.",
};

function rentErrorPage(title: string, message: string): Response {
  const html = `<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta name="robots" content="noindex" />
<title>Vitrin Açılamadı</title>
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

function rastgeleEk(): string {
  return crypto.randomBytes(4).toString("hex");
}

export async function GET(request: Request) {
  const url = new URL(request.url);
  const demoSlug = url.searchParams.get("slug")?.trim() ?? "";

  if (!demoSlug) {
    return rentErrorPage(
      "Vitrin bulunamadı",
      "Kiralama bağlantısında vitrin bilgisi eksik."
    );
  }

  const editToken = crypto.randomUUID();

  // Slug çakışması (astronomik derecede düşük ama olabilir) — bir kez
  // farklı rastgele ekle tekrar dene, ikinci sefer de olursa vazgeç.
  let newSlug = "";
  let cloned = false;
  let lastError: { message?: string; code?: string } | null = null;

  for (let attempt = 0; attempt < 2 && !cloned; attempt++) {
    newSlug = `${demoSlug}-${rastgeleEk()}`;
    const { error } = await supabase.rpc("clone_demo_store_as_draft", {
      p_source_slug: demoSlug,
      p_new_slug: newSlug,
      p_edit_token: editToken,
    });

    if (!error) {
      cloned = true;
      break;
    }

    lastError = error;
    // 23505 = unique_violation (slug çakıştı) → tekrar dene.
    // Başka bir hata ise (ör. SOURCE_NOT_FOUND) tekrar denemenin anlamı yok.
    if (error.code !== "23505") {
      break;
    }
  }

  if (!cloned) {
    const message =
      ERROR_COPY[lastError?.message ?? ""] ??
      "Vitrin şu anda kiralanamıyor. Lütfen tekrar dene.";
    console.error("[rent-demo] clone_demo_store_as_draft failed", lastError);
    return rentErrorPage("Vitrin açılamadı", message);
  }

  const { data, error: sessionError } = await supabase.rpc(
    "create_owner_session",
    { p_slug: newSlug, p_edit_token: editToken }
  );

  if (sessionError || !data?.code) {
    console.error("[rent-demo] create_owner_session failed", sessionError);
    return rentErrorPage(
      "Vitrin açılamadı",
      "Kopya oluşturuldu ama düzenleme oturumu açılamadı. Lütfen tekrar dene."
    );
  }

  const destination = new URL("/api/owner-session", url);
  destination.searchParams.set("slug", newSlug);
  destination.searchParams.set("ocode", data.code as string);

  const response = NextResponse.redirect(destination, 303);
  response.headers.set("cache-control", "no-store");
  return response;
}
