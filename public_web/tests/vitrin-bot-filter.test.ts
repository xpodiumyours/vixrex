import { describe, expect, it } from "vitest";
import { isLikelyBotUserAgent } from "@/lib/vitrinBotFilter";

describe("Vitrin Ölçer bot filtresi", () => {
  it("bilinen crawler ve link önizleme botlarını eler", () => {
    expect(isLikelyBotUserAgent("Googlebot/2.1")).toBe(true);
    expect(isLikelyBotUserAgent("facebookexternalhit/1.1")).toBe(true);
    expect(isLikelyBotUserAgent("WhatsApp/2.24")).toBe(true);
    expect(isLikelyBotUserAgent("curl/8.7.1")).toBe(true);
  });

  it("normal mobil ve masaüstü tarayıcıları bot saymaz", () => {
    expect(isLikelyBotUserAgent("Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 Chrome/151 Mobile Safari/537.36")).toBe(false);
    expect(isLikelyBotUserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Version/18 Safari/605.1.15")).toBe(false);
  });

  it("user-agent olmayan otomatik isteği ölçüme sokmaz", () => {
    expect(isLikelyBotUserAgent("")).toBe(true);
  });
});
