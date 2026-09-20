import { type NextRequest } from "next/server";
import { timingSafeEqual } from "node:crypto";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { paytrCallbackToken, paytrEnv } from "@/lib/paytr";

// PayTR Link API callback'i — ödeme sonucunu bildirir.
//
// PayTR ödeme sayfasından form-urlencoded POST gelir. Zincir:
//   form: callback_id, merchant_oid, status, total_amount, currency, hash
//   → imza doğrulanır (fail-closed: eşleşmezse 403, İŞLEM YAPILMAZ)
//   → status='success' ise record_premium_payment RPC (service_role)
//   → başarıda "OK" (PayTR başarıyı bu metinle anlar), hata "FAIL"
//
// GÜVENLİK (VIXREX_RULES §9): premium'u YALNIZ bu rota yazabilir.
// İmza doğrulanmadan gelen istek reddedilir; istemci kendi kendine
// premium yazamaz (Flutter'daki purchasePremium iskeleti kapatıldı).
// Tutar callback'ten asla doğrudan güvenilmez — record_premium_payment
// siparişte saklanan tutarla karşılaştırır, uyuşmazsa AMOUNT_MISMATCH.
// Aynı callback_id ikinci kez gelirse RPC idempotenttir (süre uzamaz).
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

  const callbackId = String(form.get("callback_id") || "").trim();
  const merchantOid = String(form.get("merchant_oid") || "").trim();
  const status = String(form.get("status") || "").trim();
  const totalAmountRaw = String(form.get("total_amount") || "").trim();
  const currency = String(form.get("currency") || "TL").trim();
  const hash = String(form.get("hash") || "").trim();

  if (!callbackId || !merchantOid || !hash) {
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
    paytrCallbackToken(
      callbackId,
      merchantOid,
      status,
      totalAmountRaw,
      env.merchantSalt,
      env.merchantKey
    ),
    "utf8"
  );
  const gelen = Buffer.from(hash, "utf8");

  if (
    gelen.length !== beklenen.length ||
    !timingSafeEqual(gelen, beklenen)
  ) {
    console.warn("[paytr/callback] imza uyuşmazlığı reddedildi");
    return new Response("FAIL", { status: 403 });
  }

  // Yalnız başarılı ödeme işlenir; başarısız/iptal durumları sessizce
  // "OK" döner (PayTR bildirimi başarıyla alındı, işlenecek bir şey yok).
  if (status !== "success") {
    return new Response("OK");
  }

  const totalAmount = Number.parseInt(totalAmountRaw, 10);
  if (!Number.isInteger(totalAmount) || totalAmount <= 0) {
    console.warn("[paytr/callback] geçersiz total_amount reddedildi");
    return new Response("FAIL", { status: 400 });
  }

  const { error } = await getSupabaseAdmin().rpc("record_premium_payment", {
    p_callback_id: callbackId,
    p_merchant_oid: merchantOid,
    p_amount_kurus: totalAmount,
    p_currency: currency === "TL" ? "TRY" : currency,
  });

  if (error) {
    // AMOUNT_MISMATCH / UNKNOWN_ORDER — sipariş işlenmez; PayTR'ye FAIL.
    console.error("[paytr/callback] record_premium_payment failed:", error.message);
    return new Response("FAIL", { status: 422 });
  }

  return new Response("OK");
}
