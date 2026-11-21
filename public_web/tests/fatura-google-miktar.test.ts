import { describe, expect, it } from "vitest";
import { googleKartlariBelgeAdedi } from "@/lib/faturaArkaPlanIslemi";

describe("googleKartlariBelgeAdedi", () => {
  it("satır sayısını değil miktarların toplamını verir", () => {
    const kartlar = [{ quantity: 3 }, { quantity: 2 }];
    expect(googleKartlariBelgeAdedi(kartlar)).toBe(5);
  });

  it("çok satırlı faturada belgede yazan toplam miktarı korur", () => {
    const kartlar = Array.from({ length: 10 }, (_, sira) => ({ quantity: sira === 0 ? 11 : 3 }));
    expect(googleKartlariBelgeAdedi(kartlar)).toBe(38);
  });

  it("miktarı okunamayan satır varsa toplam uydurmaz", () => {
    expect(googleKartlariBelgeAdedi([{ quantity: 3 }, { quantity: null }])).toBeNull();
  });

  it("kart yoksa toplam da yoktur", () => {
    expect(googleKartlariBelgeAdedi([])).toBeNull();
  });
});
