import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { randomUUID } from "node:crypto";
import {
  OWNER_SESSION_COOKIE,
  verifyOwnerSession,
} from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import {
  paytrCreateLinkPayload,
  paytrEnv,
  PAYTR_AYLIK_PREMIUM_KRUS,
  PAYTR_LINK_API_URL,
} from "@/lib/paytr";

// "Premium ile yayınla" → PayTR ödeme linki üretir (spec PR #4).
//
// Zincir:
//   istek {slug}
//   → HttpOnly sahip çerezi doğrulanır (storeId çerezden gelir, gövdeden
//     token ALINMAZ — owner-publish deseni)
//   → create_premium_order RPC (bekleyen sipariş, service_role)
//   → PayTR Link API Create (imzalı) → { link } döner
//
// merchant_oid benzersiz üretilir (vx_ + uuid) — premium_orders'taki
// unique kısıtı aynı siparişin iki kez açılmasını engeller. Ödeme yalnız
// /api/paytr/callback üzerinden (imza doğrulanmış) işlenir; bu rota yalnız
// linki üretir, premium YAZMAZ.
//
// Loglama yalnız hata mesajı; oturum tokenı ve sipariş içeriği loglanmaz.

export const dynamic = "force-dynamic";

const HATA_METNI: Record<string, string> = {
  INVALID_SESSION_TOKEN:
    "Oturumun geçersiz veya süresi dolmuş. Önizlemeyi tekrar aç.",
  STORE_NOT_FOUND: "Vitrin bulunamadı.",
  RATE_LIMITED: "Çok fazla ödeme isteği yapıldı. Lütfen biraz sonra tekrar dene.",
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

  // Oturum YALNIZ çerezden okunur.
  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);

  if (!ownerSession) {
    return NextResponse.json(
      { hata: HATA_METNI.INVALID_SESSION_TOKEN },
      { status: 401 }
    );
  }

  // PayTR kimlikleri henüz tanımlı değilse dürüstçe söyle — numara Vercel
  // env'ine girilince bu rota hiç değişmeden çalışır.
  const env = paytrEnv();
  if (!env) {
    return NextResponse.json(
      {
        hata: "Ödeme altyapısı henüz yapılandırılmadı. Lütfen daha sonra tekrar dene.",
      },
      { status: 503 }
    );
  }

  const merchantOid = `vx_${randomUUID().replace(/-/g, "")}`;

  const { data: siparis, error: siparisHatasi } = await getSupabaseAdmin().rpc(
    "create_premium_order",
    {
      p_store_id: ownerSession.storeId,
      p_merchant_oid: merchantOid,
      p_amount_kurus: PAYTR_AYLIK_PREMIUM_KRUS,
      p_currency: "TRY",
    }
  );

  if (siparisHatasi) {
    const metin = HATA_METNI[siparisHatasi.message] ?? "Ödeme başlatılamadı.";
    console.error("[paytr/create-link] create_premium_order failed:", siparisHatasi.message);
    return NextResponse.json({ hata: metin }, { status: 400 });
  }

  const payload = paytrCreateLinkPayload({
    merchantId: env.merchantId,
    merchantKey: env.merchantKey,
    merchantPass: env.merchantPass,
    merchantOid,
    linkName: "VixRex Premium — Aylık",
    linkDescription: "Aylık 299 TL · Kiralık vitrininizi yayınlamak için premium üyelik.",
    // Esnaf kirala akışında ad/soyad/e-posta vermiyor (hesap açmıyor);
    // PayTR link sayfası ödemeyi alır. Gerçek alıcı bilgisi istenirse
    // ayrı karar + form gerekir — şimdilik sabit değerler (DOĞRULANACAK).
    buyerName: "VixRex",
    buyerSurname: "Premium",
    buyerMail: "",
    buyerGsm: "",
    userIp: request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "127.0.0.1",
  });

  let paytrYanit: Response;
  try {
    paytrYanit = await fetch(PAYTR_LINK_API_URL, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: payload.toString(),
      cache: "no-store",
    });
  } catch (err) {
    console.error("[paytr/create-link] PayTR isteği başarısız:", err);
    return NextResponse.json(
      { hata: "Ödeme sağlayıcısına ulaşılamadı. Lütfen tekrar dene." },
      { status: 502 }
    );
  }

  const paytrBody = (await paytrYanit.json().catch(() => null)) as {
    status?: string;
    link?: string;
    error_message?: string;
  } | null;

  if (!paytrYanit.ok || !paytrBody || paytrBody.status !== "success" || !paytrBody.link) {
    console.error(
      "[paytr/create-link] PayTR hata:",
      paytrBody?.error_message ?? `http ${paytrYanit.status}`
    );
    return NextResponse.json(
      { hata: "Ödeme linki oluşturulamadı. Lütfen tekrar dene." },
      { status: 502 }
    );
  }

  return NextResponse.json({ tamam: true, link: paytrBody.link, merchantOid });
}
