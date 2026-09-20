import { describe, expect, it } from "vitest";
import {
  paytrCallbackToken,
  paytrCreateLinkPayload,
  paytrCreateToken,
  paytrEnv,
  PAYTR_AYLIK_PREMIUM_KRUS,
} from "@/lib/paytr";

const sabitGirdi = {
  merchantId: "123456",
  merchantKey: "test-key",
  merchantSalt: "test-salt",
  name: "VixRex Premium — Aylık",
  callbackId: "vx_abc123",
  callbackLink: "https://vixrex.com/api/paytr/callback",
};

describe("paytrCreateToken — Link API Create imzası", () => {
  it("deterministik: aynı girdi her zaman aynı imzayı üretir", () => {
    expect(paytrCreateToken(sabitGirdi)).toBe(paytrCreateToken(sabitGirdi));
  });

  it("callback_id imzaya girmez (hash yalnız name/price/currency/max_installment/link_type/lang/min_count/salt'tan gelir)", () => {
    const diger = paytrCreateToken({ ...sabitGirdi, callbackId: "vx_diger" });
    expect(diger).toBe(paytrCreateToken(sabitGirdi));
  });

  it("merchant_key değişince imza değişir (sır imzaya bağlı)", () => {
    const diger = paytrCreateToken({ ...sabitGirdi, merchantKey: "baska-key" });
    expect(diger).not.toBe(paytrCreateToken(sabitGirdi));
  });

  it("merchant_salt değişince imza değişir", () => {
    const diger = paytrCreateToken({ ...sabitGirdi, merchantSalt: "baska-salt" });
    expect(diger).not.toBe(paytrCreateToken(sabitGirdi));
  });

  it("geçerli base64 üretir", () => {
    const token = paytrCreateToken(sabitGirdi);
    expect(token).toMatch(/^[A-Za-z0-9+/=]+$/);
    expect(token.length).toBeGreaterThan(20);
  });
});

describe("paytrCreateLinkPayload — istek gövdesi", () => {
  it("resmî parametre adlarını taşır ve tutar kuruş cinsindendir", () => {
    const payload = paytrCreateLinkPayload(sabitGirdi);
    expect(payload.get("merchant_id")).toBe("123456");
    expect(payload.get("price")).toBe(String(PAYTR_AYLIK_PREMIUM_KRUS));
    expect(payload.get("callback_id")).toBe("vx_abc123");
    expect(payload.get("callback_link")).toBe("https://vixrex.com/api/paytr/callback");
    expect(payload.get("currency")).toBe("TL");
    expect(payload.get("paytr_token")).toBe(paytrCreateToken(sabitGirdi));
  });
});

describe("paytrCallbackToken — callback doğrulama imzası", () => {
  it("create imzasından farklıdır (iki imza karıştırılamaz)", () => {
    const callbackToken = paytrCallbackToken(
      "vx_abc123",
      "PAYTR_999",
      "success",
      "29900",
      "test-salt",
      "test-key",
    );
    expect(callbackToken).not.toBe(paytrCreateToken(sabitGirdi));
  });

  it("deterministik ve her alana bağlıdır", () => {
    expect(
      paytrCallbackToken("vx_abc123", "PAYTR_999", "success", "29900", "s", "k"),
    ).toBe(paytrCallbackToken("vx_abc123", "PAYTR_999", "success", "29900", "s", "k"));

    expect(
      paytrCallbackToken("vx_baska", "PAYTR_999", "success", "29900", "s", "k"),
    ).not.toBe(paytrCallbackToken("vx_abc123", "PAYTR_999", "success", "29900", "s", "k"));

    expect(
      paytrCallbackToken("vx_abc123", "PAYTR_999", "failed", "29900", "s", "k"),
    ).not.toBe(paytrCallbackToken("vx_abc123", "PAYTR_999", "success", "29900", "s", "k"));
  });
});

describe("paytrEnv — ortam değişkenleri", () => {
  it("kimlikler tanımlı değilse null döner (route 503 verir)", () => {
    const onceki = {
      id: process.env.PAYTR_MERCHANT_ID,
      key: process.env.PAYTR_MERCHANT_KEY,
      salt: process.env.PAYTR_MERCHANT_SALT,
    };
    try {
      delete process.env.PAYTR_MERCHANT_ID;
      delete process.env.PAYTR_MERCHANT_KEY;
      delete process.env.PAYTR_MERCHANT_SALT;
      expect(paytrEnv()).toBeNull();
    } finally {
      if (onceki.id) process.env.PAYTR_MERCHANT_ID = onceki.id;
      if (onceki.key) process.env.PAYTR_MERCHANT_KEY = onceki.key;
      if (onceki.salt) process.env.PAYTR_MERCHANT_SALT = onceki.salt;
    }
  });
});
