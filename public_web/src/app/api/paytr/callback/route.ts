import { NextResponse, type NextRequest } from "next/server";
import { timingSafeEqual } from "node:crypto";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { paytrCallbackToken, paytrEnv } from "@/lib/paytr";

// PayTR Link API callback'i — ödeme sonucunu bildirir.
//
// PayTR ödeme sayfasından form-urlencoded POST gelir. Zincir:
//   form: merchant_oid, paytr_status, payment_amount, paytr_token, ...
//   → imza doğrulanır (fail-closed: eşleşmezse 403, İŞLEM YAPILMAZ)
//   → paytr_status='success' ise record_premium_payment RPC (service_role)
//   → başarıda "OK" (PayTR başarıyı bu metinle anlar), hata "FAIL"
//
// GÜVENLİK (VIXREX_RULES §9): premium'u YALNIZ bu rota yazabilir.
// İmza doğrulanmadan gelen istek reddedilir; istemci kendi kendine
// premium yazamaz (Flutter'daki purchasePremium iskeleti kapatıldı).
// Tutar callback'ten asla doğrudan güvenilmez — record_premium_payment
// siparişte saklanan tutarla karşılaştırır, uyuşmazsa AMOUNT_MISMATCH.
// Aynı merchant_oid ikinci kez gelirse RPC idempotenttir (süre uzamaz).
//
// Oran sınırı bilinçli YOK: imza doğrulaması asıl kapıdır (HMAC ucuz),
// PayTR başarısız bildirimleri yeniden gönderir — sınır koymak meşru
// tekrarları düşürür. Replay koruması RPC'nin idempotency'sidir.
//
// Loglama yalnız hata/red; sipariş içeriği ve imza loglanmaz.

export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return new Response("FAIL", { status: 400 });
  }

  const merchantOid = String(form.get("merchant_oid") || "").trim();
  const paytrStatus = String(form.get("paytr_status") || "").trim();
  const paymentAmountRaw = String(form.get("payment_amount") || "").trim();
  const paytrToken = String(form.get("paytr_token") || "").trim();

  if (!merchantOid || !paytrToken) {
    console.warn("[paytr/callback] eksik alan reddedildi");
    return new Response("FAIL", { status: 400 });
  }

  const env = paytrEnv();
  if (!env) {
    console.error("[paytr/callback] PAYTR env tanımlı değil");
    return new Response("FAIL", { status: 503 });
  }

  // İmza doğrulama — fail-closed, sabit zamanlı karşılaştırma.
  const beklenen = Buffer.from(
    paytrCallbackToken(merchantOid, env.merchantSalt, env.merchantKey),
    "utf8"
  );
  const gelen = Buffer.from(paytrToken, "utf8");

  if (
    gelen.length !== beklenen.length ||
    !timingSafeEqual(gelen, beklenen)
  ) {
    console.warn("[paytr/callback] imza uyuşmazlığı reddedildi");
    return new Response("FAIL", { status: 403 });
  }

  // Yalnız başarılı ödeme işlenir; başarısız/iptal durumları sessizce
  // "OK" döner (PayTR bildirimi başarıyla alındı, işlenecek bir şey yok).
  if (paytrStatus !== "success") {
    return new Response("OK");
  }

  const paymentAmount = Number.parseInt(paymentAmountRaw, 10);
  if (!Number.isInteger(paymentAmount) || paymentAmount <= 0) {
    console.warn("[paytr/callback] geçersiz payment_amount reddedildi");
    return new Response("FAIL", { status: 400 });
  }

  const { error } = await getSupabaseAdmin().rpc("record_premium_payment", {
    p_merchant_oid: merchantOid,
    p_amount_kurus: paymentAmount,
    p_currency: "TRY",
  });

  if (error) {
    // AMOUNT_MISMATCH / UNKNOWN_ORDER — sipariş işlenmez; PayTR'ye FAIL.
    console.error("[paytr/callback] record_premium_payment failed:", error.message);
    return new Response("FAIL", { status: 422 });
  }

  return new Response("OK");
}
