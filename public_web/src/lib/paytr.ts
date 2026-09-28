// PayTR Link API — imza ve parametre üretimi (VIXREX_RULES §3.7: sırlar
// yalnız env'den gelir, koda/README'ye yazılmaz).
//
// 2026-09-20 doğrulaması: dev.paytr.com resmî dokümanlarından birebir
// teyit edildi (https://dev.paytr.com/en/link-api/link-api-create ve
// https://dev.paytr.com/en/link-api/linkle-api-callback). 2026-08-17'deki
// önceki sürüm dev.paytr.com'a erişilemediği için araştırma notuna
// dayanıyordu ve yanlıştı: yanlış uç nokta, PayTR'nin Link API'de hiç
// almadığı alanlar (buyer_name, buyer_gsm, user_basket, merchant_pass) ve
// yanlış hash formülü içeriyordu. En ciddisi: merchant_oid'i PayTR kendisi
// üretir, biz değil — eski kod kendi ürettiği merchant_oid'i isteğe
// eklemeye çalışıyordu (PayTR bu alanı hiç okumuyor) ve callback'te PayTR
// kendi merchant_oid'ini gönderdiğinde sipariş eşleşmeyip UNKNOWN_ORDER
// ile reddedilecekti — yani gerçek bir ödeme bile premium açmayacaktı.
//
// Create isteği (Link API Create, resmî parametre listesi):
//   merchant_id, name, price, currency, max_installment, link_type, lang,
//   min_count (link_type=product), callback_id, callback_link, paytr_token
//   paytr_token = base64( hmac_sha256(
//     name + price + currency + max_installment + link_type + lang +
//     min_count + merchant_salt,
//     merchant_key, true ) )
//
// Callback (PayTR'nin bize gönderdiği bildirim):
//   callback_id, merchant_oid, status, total_amount, currency, ...
//   hash = base64( hmac_sha256(
//     callback_id + merchant_oid + merchant_salt + status + total_amount,
//     merchant_key, true ) )
//
// merchant_oid PayTR tarafından ödeme anında üretilir; biz yalnız
// callback_id'i (kendi ürettiğimiz, benzersiz) gönderip PayTR'nin aynen
// geri yollamasına güveniriz — sipariş eşleştirmesi callback_id ile
// yapılır, merchant_oid yalnız kayıt amaçlıdır.
//
// Hesap aktifleşince:
//   1) Mağaza Paneli → Destek & Kurulum → Entegrasyon Bilgileri'ndeki
//      MERCHANT_ID / MERCHANT_KEY / MERCHANT_SALT Vercel env'ine eklenir.
//   2) callback_link panele değil, her istekte açıkça gönderilir:
//      https://<site>/api/paytr/callback
//   3) debug_on=1 ile ilk canlı test yapılır.

import { createHmac } from "node:crypto";

import { AYLIK_PREMIUM_KURUS } from "./fiyatlandirma";

export const PAYTR_AYLIK_PREMIUM_KRUS = AYLIK_PREMIUM_KURUS;
export const PAYTR_LINK_API_URL = "https://www.paytr.com/odeme/api/link/create";
export const PAYTR_LINK_TYPE = "product";
export const PAYTR_LANG = "tr";
export const PAYTR_MAX_INSTALLMENT = "1";
export const PAYTR_MIN_COUNT = "1";
export const PAYTR_CURRENCY = "TL";

export interface PaytrCreateLinkInput {
  merchantId: string;
  merchantKey: string;
  merchantSalt: string;
  name: string;
  callbackId: string;
  callbackLink: string;
}

export function paytrCreateToken(input: PaytrCreateLinkInput): string {
  const raw = [
    input.name,
    String(PAYTR_AYLIK_PREMIUM_KRUS),
    PAYTR_CURRENCY,
    PAYTR_MAX_INSTALLMENT,
    PAYTR_LINK_TYPE,
    PAYTR_LANG,
    PAYTR_MIN_COUNT,
    input.merchantSalt,
  ].join("");

  return createHmac("sha256", input.merchantKey).update(raw).digest("base64");
}

export function paytrCreateLinkPayload(input: PaytrCreateLinkInput): URLSearchParams {
  const params = new URLSearchParams();
  params.set("merchant_id", input.merchantId);
  params.set("name", input.name);
  params.set("price", String(PAYTR_AYLIK_PREMIUM_KRUS));
  params.set("currency", PAYTR_CURRENCY);
  params.set("max_installment", PAYTR_MAX_INSTALLMENT);
  params.set("link_type", PAYTR_LINK_TYPE);
  params.set("lang", PAYTR_LANG);
  params.set("min_count", PAYTR_MIN_COUNT);
  params.set("callback_id", input.callbackId);
  params.set("callback_link", input.callbackLink);
  params.set("paytr_token", paytrCreateToken(input));
  return params;
}

export function paytrCallbackToken(
  callbackId: string,
  merchantOid: string,
  status: string,
  totalAmount: string,
  merchantSalt: string,
  merchantKey: string
): string {
  const raw = callbackId + merchantOid + merchantSalt + status + totalAmount;
  return createHmac("sha256", merchantKey).update(raw).digest("base64");
}

export function paytrEnv(): {
  merchantId: string;
  merchantKey: string;
  merchantSalt: string;
} | null {
  const merchantId = (process.env.PAYTR_MERCHANT_ID || "").trim();
  const merchantKey = (process.env.PAYTR_MERCHANT_KEY || "").trim();
  const merchantSalt = (process.env.PAYTR_MERCHANT_SALT || "").trim();

  if (!merchantId || !merchantKey || !merchantSalt) return null;
  return { merchantId, merchantKey, merchantSalt };
}
