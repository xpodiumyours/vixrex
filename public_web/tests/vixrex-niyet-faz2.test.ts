import { describe, it, expect } from "vitest";
import { VIXREX_NIYET_SOZLUGU } from "../src/lib/vixrexNiyetSozlugu";
import { resolveVixrexIntent } from "../src/lib/vixrexIntentResolver";
import { extractVixrexValue } from "../src/lib/vixrexValueExtractor";
import { validateField } from "../src/lib/vitrinFieldValidation";

describe("Faz 2 – 8 kalite alan", () => {
  const kalite = ["heroRozet", "logo", "kapakGorseli", "mahalle", "calismaSaatleri", "haritaLinki", "hakkindaBaslik", "hakkindaMetin"] as const;

  it("8 kalite sözlükte var", () => {
    for (const k of kalite) expect(VIXREX_NIYET_SOZLUGU.some((a) => a.anahtar === k)).toBe(true);
  });

  it("kalite niyet tanınır", () => {
    expect(resolveVixrexIntent("Rozeti Kadıköyün En İyisi yap")?.anahtar).toBe("heroRozet");
    expect(resolveVixrexIntent("Logoyu https://a.com/logo.png yap")?.anahtar).toBe("logo");
    expect(resolveVixrexIntent("Kapak görselini https://a.com/c.jpg yap")?.anahtar).toBe("kapakGorseli");
    expect(resolveVixrexIntent("Mahalleyi Caddebostan yap")?.anahtar).toBe("mahalle");
    expect(resolveVixrexIntent("Çalışma saatlerini 09:00-18:00 yap")?.anahtar).toBe("calismaSaatleri");
    expect(resolveVixrexIntent("Harita linkini https://maps.google.com yap")?.anahtar).toBe("haritaLinki");
  });

  it("değer ayıklama kalite", () => {
    const hero = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === "heroRozet")!;
    const mah = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === "mahalle")!;
    const harita = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === "haritaLinki")!;
    expect(extractVixrexValue("Rozeti 'Kadıköyün En İyisi' yap", hero)).toBe("Kadıköyün En İyisi");
    expect(extractVixrexValue("Mahalleyi Caddebostan yap", mah)).toBe("Caddebostan");
    expect(extractVixrexValue("Harita linkini https://maps.google.com yap", harita)).toBe("https://maps.google.com");
  });

  it("validator kalite – url/gorsel ve uzunluk", () => {
    expect(validateField("haritaLinki", "https://maps.google.com").ok).toBe(true);
    expect(validateField("haritaLinki", "not-url").ok).toBe(false);
    expect(validateField("logo", "https://a.com/l.png").ok).toBe(true);
    expect(validateField("heroRozet", "a".repeat(61)).ok).toBe(false);
    expect(validateField("mahalle", "Caddebostan").ok).toBe(true);
  });
});

describe("Faz 2 Web↔Mobil parity – kalite", () => {
  it("aynı cümle aynı anahtar/değer", () => {
    const cases = [
      { input: "Mahalleyi Caddebostan yap", anahtar: "mahalle", deger: "Caddebostan" },
      { input: "Logoyu https://a.com/logo.png yap", anahtar: "logo", deger: "https://a.com/logo.png" },
    ] as const;
    for (const { input, anahtar, deger } of cases) {
      const a = resolveVixrexIntent(input);
      expect(a?.anahtar).toBe(anahtar);
      if (a) expect(extractVixrexValue(input, a)).toBe(deger);
    }
  });
});
