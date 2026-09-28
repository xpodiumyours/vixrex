import { createHmac } from "node:crypto";
import { describe, expect, it } from "vitest";

import {
  paytrCallbackToken,
  paytrCreateLinkPayload,
  paytrCreateToken,
  PAYTR_AYLIK_PREMIUM_KRUS,
  PAYTR_LINK_API_URL,
  PAYTR_LINK_TYPE,
  PAYTR_LANG,
  PAYTR_MAX_INSTALLMENT,
  PAYTR_MIN_COUNT,
  PAYTR_CURRENCY,
} from "@/lib/paytr";

/**
 * PayTR resmî dokümanlarından 2026-09-20'de birebir teyit edilen formüller:
 *   https://dev.paytr.com/en/link-api/link-api-create
 *   https://dev.paytr.com/en/link-api/linkle-api-callback
 *
 * Bu test dokümandaki formülü elle yeniden hesaplayıp kütüphanenin
 * ürettiğiyle karşılaştırır — kaynak kodun kendi mantığını tekrar etmez.
 */

const MERCHANT_ID = "123456";
const MERCHANT_KEY = "test-merchant-key";
const MERCHANT_SALT = "test-merchant-salt";

describe("PayTR Link API Create imzası", () => {
  it("resmî uç noktayı kullanır", () => {
    expect(PAYTR_LINK_API_URL).toBe("https://www.paytr.com/odeme/api/link/create");
  });

  it("dokümandaki alan sırasıyla birebir aynı hash'i üretir", () => {
    const input = {
      merchantId: MERCHANT_ID,
      merchantKey: MERCHANT_KEY,
      merchantSalt: MERCHANT_SALT,
      name: "VixRex Premium — Aylık",
      callbackId: "vx_test123",
      callbackLink: "https://vixrex.com/api/paytr/callback",
    };

    const elleHesaplanan = createHmac("sha256", MERCHANT_KEY)
      .update(
        input.name +
          String(PAYTR_AYLIK_PREMIUM_KRUS) +
          PAYTR_CURRENCY +
          PAYTR_MAX_INSTALLMENT +
          PAYTR_LINK_TYPE +
          PAYTR_LANG +
          PAYTR_MIN_COUNT +
          MERCHANT_SALT,
      )
      .digest("base64");

    expect(paytrCreateToken(input)).toBe(elleHesaplanan);
  });

  it("isteğe merchant_oid, buyer_* veya user_basket eklemez (Link Create'in almadığı alanlar)", () => {
    const params = paytrCreateLinkPayload({
      merchantId: MERCHANT_ID,
      merchantKey: MERCHANT_KEY,
      merchantSalt: MERCHANT_SALT,
      name: "VixRex Premium — Aylık",
      callbackId: "vx_test123",
      callbackLink: "https://vixrex.com/api/paytr/callback",
    });

    expect(params.has("merchant_oid")).toBe(false);
    expect(params.has("buyer_name")).toBe(false);
    expect(params.has("buyer_gsm")).toBe(false);
    expect(params.has("user_basket")).toBe(false);
    expect(params.has("merchant_pass")).toBe(false);
    expect(params.get("callback_id")).toBe("vx_test123");
    expect(params.get("link_type")).toBe("product");
  });
});

describe("PayTR Link API Callback doğrulaması", () => {
  it("dokümandaki alan sırasıyla birebir aynı hash'i üretir", () => {
    const callbackId = "vx_test123";
    const merchantOid = "PAYTR_URETTI_999";
    const status = "success";
    const totalAmount = "29900";

    const elleHesaplanan = createHmac("sha256", MERCHANT_KEY)
      .update(callbackId + merchantOid + MERCHANT_SALT + status + totalAmount)
      .digest("base64");

    expect(
      paytrCallbackToken(callbackId, merchantOid, status, totalAmount, MERCHANT_SALT, MERCHANT_KEY),
    ).toBe(elleHesaplanan);
  });
});
