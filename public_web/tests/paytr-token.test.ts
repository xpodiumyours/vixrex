import { describe, expect, it } from "vitest";
import {
  paytrCallbackToken,
  paytrCreateLinkPayload,
  paytrCreateToken,
  paytrEnv,
  paytrUserBasket,
  PAYTR_AYLIK_PREMIUM_KRUS,
} from "@/lib/paytr";

// paytr.ts birim testleri. DİKKAT: bu testler PayTR'nin resmî test
// vektörüyle karşılaştırma yapmaz — dev.paytr.com erişilemediği için
// formül henüz birincil kaynaktan doğrulanmadı (dosyadaki DOĞRULANACAK
// notu). Bu testler yalnız uygulamanın kendi içinde tutarlı olduğunu
// garanti eder: imza deterministiktir, girdi değişince değişir, payload
// formülle aynı alanları taşır. Hesap açılınca formül canlı testle teyit
// edilir; o noktada değişecek tek dosya src/lib/paytr.ts'tir.

const sabitGirdi = {
  merchantId: "123456",
  merchantKey: "test-key",
  merchantPass: "test-pass",
  merchantOid: "vx_abc123",
  linkName: "VixRex Premium — Aylık",
  linkDescription: "Aylık 299 TL",
  buyerName: "VixRex",
  buyerSurname: "Premium",
  buyerMail: "",
  buyerGsm: "",
  userIp: "127.0.0.1",
};

describe("paytrCreateToken — Link API Create imzası", () => {
  it("deterministik: aynı girdi her zaman aynı imzayı üretir", () => {
    expect(paytrCreateToken(sabitGirdi)).toBe(paytrCreateToken(sabitGirdi));
  });

  it("merchant_oid değişince imza değişir (imza siparişe bağlı)", () => {
    const diger = paytrCreateToken({ ...sabitGirdi, merchantOid: "vx_diger" });
    expect(diger).not.toBe(paytrCreateToken(sabitGirdi));
  });

  it("merchant_key değişince imza değişir (sır imzaya bağlı)", () => {
    const diger = paytrCreateToken({ ...sabitGirdi, merchantKey: "baska-key" });
    expect(diger).not.toBe(paytrCreateToken(sabitGirdi));
  });

  it("geçerli base64 üretir", () => {
    const token = paytrCreateToken(sabitGirdi);
    expect(token).toMatch(/^[A-Za-z0-9+/=]+$/);
    expect(token.length).toBeGreaterThan(20);
  });
});

describe("paytrCreateLinkPayload — istek gövdesi", () => {
  it("formülle aynı alanları taşır ve tutar kuruş cinsindendir", () => {
    const payload = paytrCreateLinkPayload(sabitGirdi);
    expect(payload.get("merchant_id")).toBe("123456");
    expect(payload.get("payment_amount")).toBe(String(PAYTR_AYLIK_PREMIUM_KRUS));
    expect(payload.get("merchant_oid")).toBe("vx_abc123");
    expect(payload.get("payment_type")).toBe("LINK_API");
    expect(payload.get("currency")).toBe("TL");
    expect(payload.get("paytr_token")).toBe(paytrCreateToken(sabitGirdi));
  });

  it("sepet PayTR biçimindedir ([ad, tutar, adet])", () => {
    expect(paytrUserBasket()).toBe('[["VixRex Premium — Aylık","299.00",1]]');
  });
});

describe("paytrCallbackToken — callback doğrulama imzası", () => {
  it("create imzasından farklıdır (iki imza karıştırılamaz)", () => {
    const callbackToken = paytrCallbackToken("vx_abc123", "test-salt", "test-key");
    expect(callbackToken).not.toBe(paytrCreateToken(sabitGirdi));
  });

  it("deterministik ve merchant_oid'e bağlıdır", () => {
    expect(paytrCallbackToken("vx_abc123", "s", "k")).toBe(
      paytrCallbackToken("vx_abc123", "s", "k")
    );
    expect(paytrCallbackToken("vx_baska", "s", "k")).not.toBe(
      paytrCallbackToken("vx_abc123", "s", "k")
    );
  });
});

describe("paytrEnv — ortam değişkenleri", () => {
  it("kimlikler tanımlı değilse null döner (route 503 verir)", () => {
    // Bu testte env boş olduğu varsayılır; doldurulmuşsa atlar.
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
