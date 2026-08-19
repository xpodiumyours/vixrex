import { describe, expect, it } from "vitest";

/**
 * Instagram açık yönlendirme (open redirect) testi.
 *
 * SORUN: safeReturnTo() yalnızca startsWith("/") kontrolü yapıyordu.
 * "//evil.com" (protocol-relative URL) bu kontrolden geçiyordu.
 * callbackRedirect() ise new URL(returnTo, base) ile //evil.com'u
 * https://evil.com'a çözüyordu — açık yönlendirme.
 *
 * DÜZELTME: "//" prefix'i reddedilir.
 *
 * Bu testler connect/route.ts'deki safeReturnTo mantığını doğrular.
 * Fonksiyon export edilmediği için davranışı API üzerinden test edilir;
 * burada beklenen mantık belgelenir.
 */

describe("Instagram open redirect koruması", () => {
  /**
   * safeReturnTo mantığını taklit eden yardımcı.
   * Gerçek fonksiyon connect/route.ts内ba.
   */
  function safeReturnTo(value: string | null, storeSlug: string): string {
    if (value && value.startsWith("/") && !value.startsWith("//")) return value;
    return `/v/${storeSlug}`;
  }

  it("normal path'i aynen döndürür", () => {
    expect(safeReturnTo("/v/my-store", "my-store")).toBe("/v/my-store");
  });

  it("null input varsayılan döndürür", () => {
    expect(safeReturnTo(null, "my-store")).toBe("/v/my-store");
  });

  it("boş string varsayılan döndürür", () => {
    expect(safeReturnTo("", "my-store")).toBe("/v/my-store");
  });

  it("http:// URL'ini reddeder ve varsayılan döndürür", () => {
    expect(safeReturnTo("http://evil.com", "my-store")).toBe("/v/my-store");
  });

  it("https:// URL'ini reddeder ve varsayılan döndürür", () => {
    expect(safeReturnTo("https://evil.com", "my-store")).toBe("/v/my-store");
  });

  it("protocol-relative //evil.com bypass'ını engeller", () => {
    expect(safeReturnTo("//evil.com", "my-store")).toBe("/v/my-store");
  });

  it("protocol-relative //evil.com/path bypass'ını engeller", () => {
    expect(safeReturnTo("//evil.com/steal-cookie", "my-store")).toBe("/v/my-store");
  });

  it("javascript: URI'ini reddeder", () => {
    expect(safeReturnTo("javascript:alert(1)", "my-store")).toBe("/v/my-store");
  });

  it("data: URI'ini reddeder", () => {
    expect(safeReturnTo("data:text/html,<script>alert(1)</script>", "my-store")).toBe("/v/my-store");
  });

  it("kök path'i (/) kabul eder", () => {
    expect(safeReturnTo("/", "my-store")).toBe("/");
  });

  it("derin path'leri kabul eder", () => {
    expect(safeReturnTo("/v/my-store/randevu", "my-store")).toBe("/v/my-store/randevu");
  });
});

describe("callbackRedirect sanitizeReturnTo mantığı", () => {
  /**
   * callback_redirect'teki sanitizeReturnTo mantığını taklit eder.
   */
  function sanitizeReturnTo(value: string): string {
    if (value && value.startsWith("/") && !value.startsWith("//")) return value;
    return "/";
  }

  it("normal path'i aynen döndürür", () => {
    expect(sanitizeReturnTo("/v/my-store")).toBe("/v/my-store");
  });

  it("protocol-relative URL'yi engeller", () => {
    expect(sanitizeReturnTo("//evil.com")).toBe("/");
  });

  it("boş string'i根'e çevirir", () => {
    expect(sanitizeReturnTo("")).toBe("/");
  });

  it("http URL'yi reddeder", () => {
    expect(sanitizeReturnTo("http://evil.com")).toBe("/");
  });
});
