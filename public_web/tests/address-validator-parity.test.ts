import { describe, expect, it } from "vitest";
import { addressHataMesaji, isAddressValid } from "@/lib/addressValidator";

/**
 * GAP-21 — AddressValidator Flutter paritesi.
 * Dart lib/utils/address_validator.dart ile aynı kurallar.
 * Flutter referansı: hatalı adresleri reddet, geçerliyi kabul.
 */
describe("GAP-21 adres doğrulama — Flutter AddressValidator paritesi", () => {
  it("boş adres reddedilir", () => {
    expect(addressHataMesaji("")).toMatch(/Adres gerekli/);
    expect(addressHataMesaji("   ")).toMatch(/Adres gerekli/);
    expect(isAddressValid("")).toBe(false);
  });

  it("çok kısa adres reddedilir (min 10)", () => {
    expect(addressHataMesaji("asd")).toMatch(/çok kısa/);
    expect(addressHataMesaji("a b c")).toMatch(/çok kısa/);
    expect(isAddressValid("Kısa")).toBe(false);
  });

  it("rakam ve yer belirteci olmadan reddedilir", () => {
    // 10+ karakter ama ne rakam ne de cad/sok/mah vb
    expect(addressHataMesaji("Büyük bir ev güzel")).toMatch(/eksik görünüyor/);
    expect(isAddressValid("Büyük bir ev güzel")).toBe(false);
  });

  it("Flutter geçerli örnekleri Next’te de geçer", () => {
    expect(isAddressValid("Atatürk Cad. No:24")).toBe(true);
    expect(isAddressValid("Çatalmeşe Mah. 207. Sokak No: 12")).toBe(true);
    expect(isAddressValid("Caferağa Mah. Moda Cad. No:12")).toBe(true);
    expect(isAddressValid("Kavaklıdere Mah. Atatürk Bulvarı No: 112/A Çankaya/Ankara")).toBe(true);
    // Sadece rakam da geçer (yer belirteci yok ama rakam var)
    expect(isAddressValid("Test Mah. No:1")).toBe(true);
  });

  it("Flutter geçersiz örnekleri Next’te de reddedilir", () => {
    expect(isAddressValid("asd")).toBe(false);
    expect(isAddressValid("test")).toBe(false);
    expect(isAddressValid("adres")).toBe(false);
    // 5 karakter kuralı artık yok — 5 karakter Flutter’da reddedilirdi
    expect(isAddressValid("abcde")).toBe(false);
  });

  it("hata mesajı kullanıcıya görünür ve actionable", () => {
    const msg = addressHataMesaji("asd")!;
    expect(msg.length).toBeGreaterThan(20);
    expect(msg).toMatch(/Örnek|örnek/);
  });

  it("trim edilir — baş/son boşluk temizlenmeli", () => {
    expect(isAddressValid("  Atatürk Cad. No:24  ")).toBe(true);
    expect(isAddressValid("    ")).toBe(false);
  });
});
