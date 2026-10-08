import { describe, expect, it } from "vitest";
import { resmiSiteSayilmaz } from "@/lib/firmaArama";

describe("resmi site sayilmaz", () => {
  it("pazar yeri ve sosyal ag resmi site degildir", () => {
    expect(resmiSiteSayilmaz("trendyol.com")).toBe(true);
    expect(resmiSiteSayilmaz("www.instagram.com")).toBe(true);
    expect(resmiSiteSayilmaz("https://www.hepsiburada.com/magaza")).toBe(true);
  });

  it("bos veya gecersiz adres resmi site degildir", () => {
    expect(resmiSiteSayilmaz("")).toBe(true);
    expect(resmiSiteSayilmaz("   ")).toBe(true);
  });

  it("firma alanini eler", () => {
    expect(resmiSiteSayilmaz("etigida.com.tr")).toBe(false);
    expect(resmiSiteSayilmaz("https://www.sehermensucat.com")).toBe(false);
  });
});
