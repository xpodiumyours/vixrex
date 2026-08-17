// PayTR Link API — imza ve parametre üretimi (VIXREX_RULES §3.7: sırlar
// yalnız env'den gelir, koda/README'ye yazılmaz).
//
// ⚠️ DOĞRULANACAK (2026-08-17): dev.paytr.com bu oturumda erişilemedi (500,
// bot koruması). Aşağıdaki alan sırası ve hash formülü PayTR'nin resmî
// dokümantasyonundan birebir teyit edilmeden, araştırma notuna
// (docs/research/vixrex-paytr-abonelik-odeme-2026-08-17.md) dayanarak
// yazıldı. Hesap aktifleşince:
//   1) Mağaza Paneli → Destek & Kurulum → Entegrasyon Bilgileri'ndeki
//      MERCHANT_ID / MERCHANT_KEY / MERCHANT_SALT (+ varsa MERCHANT_PASS)
//      Vercel env'ine eklenir (secret).
//   2) Callback URL'si panele kaydedilir: https://<site>/api/paytr/callback
//   3) debug_on=1 ile ilk canlı test yapılır. Formül tutmazsa yalnız bu
//      dosya düzeltilir — başka hiçbir yere dokunulmaz (tek doğruluk
//      kaynağı burası).
//
// Hash deseni (Link API Create, PayTR dokümantasyonundan):
//   paytr_token = base64( hmac_sha256(
//     merchant_id + payment_amount + merchant_oid + payment_type +
//     link_type + no_installment + max_installment + link_name +
//     buyer_name + buyer_surname + buyer_mail + buyer_gsm + user_ip +
//     user_basket + currency + merchant_pass,
//     merchant_key, true ) )
// Callback doğrulama deseni:
//   paytr_token = base64( hmac_sha256( merchant_oid + merchant_salt,
//     merchant_key, true ) )

import { createHmac } from "node:crypto";

/** Aylık premium bedeli — kuruş (299 TL = 29900). Sunucu tarafı tek
 *  doğruluk kaynağı; kiralama bandındaki metin yalnız gösterimdir. */
export const PAYTR_AYLIK_PREMIUM_KRUS = 29900;
/** Link API Create uç noktası. */
export const PAYTR_LINK_API_URL = "https://www.paytr.com/odeme/api/link-api/create";

/** Create isteği için ödeme sepeti — imzanın parçası, birebir aynı
 *  dize üretilmelidir. PayTR biçimi: [["ad","tutar","adet"], ...]. */
export function paytrUserBasket(): string {
  return JSON.stringify([["VixRex Premium — Aylık", "299.00", 1]]);
}

export interface PaytrCreateLinkInput {
  merchantId: string;
  merchantKey: string;
  merchantPass: string;
  merchantOid: string;
  linkName: string;
  linkDescription: string;
  buyerName: string;
  buyerSurname: string;
  buyerMail: string;
  buyerGsm: string;
  userIp: string;
}

/** Link API Create imzası. Kuruş tutarı PAYTR_AYLIK_PREMIUM_KRUS'tan
 *  alınır — çağıran tutarı parametre olarak veremez, değiştirilemez. */
export function paytrCreateToken(input: PaytrCreateLinkInput): string {
  const raw = [
    input.merchantId,
    String(PAYTR_AYLIK_PREMIUM_KRUS),
    input.merchantOid,
    "LINK_API", // payment_type
    "0", // link_type: tek kullanımlık
    "1", // no_installment: taksit yok
    "0", // max_installment
    input.linkName,
    input.buyerName,
    input.buyerSurname,
    input.buyerMail,
    input.buyerGsm,
    input.userIp,
    paytrUserBasket(),
    "TL", // currency (PayTR para birimi kodu)
    input.merchantPass,
  ].join("");

  return createHmac("sha256", input.merchantKey).update(raw).digest("base64");
}

/** Link API Create isteği gövdesi (form-urlencoded). */
export function paytrCreateLinkPayload(input: PaytrCreateLinkInput): URLSearchParams {
  const params = new URLSearchParams();
  params.set("merchant_id", input.merchantId);
  params.set("payment_amount", String(PAYTR_AYLIK_PREMIUM_KRUS));
  params.set("merchant_oid", input.merchantOid);
  params.set("payment_type", "LINK_API");
  params.set("link_type", "0");
  params.set("no_installment", "1");
  params.set("max_installment", "0");
  params.set("link_name", input.linkName);
  params.set("link_description", input.linkDescription);
  params.set("buyer_name", input.buyerName);
  params.set("buyer_surname", input.buyerSurname);
  params.set("buyer_mail", input.buyerMail);
  params.set("buyer_gsm", input.buyerGsm);
  params.set("user_ip", input.userIp);
  params.set("user_basket", paytrUserBasket());
  params.set("currency", "TL");
  params.set("merchant_pass", input.merchantPass);
  params.set("paytr_token", paytrCreateToken(input));
  return params;
}

/** Callback imza doğrulaması — fail-closed karşılaştırma çağıranda. */
export function paytrCallbackToken(
  merchantOid: string,
  merchantSalt: string,
  merchantKey: string
): string {
  const raw = merchantOid + merchantSalt;
  return createHmac("sha256", merchantKey).update(raw).digest("base64");
}

/** Ortam değişkenlerinden PayTR kimliklerini okur. Eksikse null —
 *  çağıran 503 döner (\"ödeme altyapısı henüz yapılandırılmadı\"). */
export function paytrEnv(): {
  merchantId: string;
  merchantKey: string;
  merchantSalt: string;
  merchantPass: string;
} | null {
  const merchantId = (process.env.PAYTR_MERCHANT_ID || "").trim();
  const merchantKey = (process.env.PAYTR_MERCHANT_KEY || "").trim();
  const merchantSalt = (process.env.PAYTR_MERCHANT_SALT || "").trim();
  const merchantPass = (process.env.PAYTR_MERCHANT_PASS || "").trim();

  if (!merchantId || !merchantKey || !merchantSalt) return null;
  return { merchantId, merchantKey, merchantSalt, merchantPass };
}
