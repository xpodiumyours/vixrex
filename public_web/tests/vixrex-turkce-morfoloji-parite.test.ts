import { describe, expect, it } from "vitest";
import { resolveVixrexIntent, resolveVixrexIntentsAll } from "../src/lib/vixrexIntentResolver";
import { extractVixrexValue } from "../src/lib/vixrexValueExtractor";

const cases = [
  ["Dükkanın adı Aymira Giyim", "isletmeAdi", "Aymira Giyim"],
  ["Dükkanımın adı Aymira Giyim", "isletmeAdi", "Aymira Giyim"],
  ["Ürünlerin başlığı Ürünlerimiz", "urunBolumBaslik", "Ürünlerimiz"],
  ["Galerinin başlığı Yaptığımız İşler", "galeriBaslik", "Yaptığımız İşler"],
] as const;

describe("Türkçe iyelik/genitif — Next.js", () => {
  for (const [input, anahtar, deger] of cases) {
    it(`${input} -> ${anahtar}`, () => {
      const alan = resolveVixrexIntent(input);
      expect(alan?.anahtar).toBe(anahtar);
      expect(alan ? extractVixrexValue(input, alan) : null).toBe(deger);
    });
  }

  it("kısa 'il' aliası normal kelime içinden veya ek genişlemesinden doğmaz", () => {
    for (const input of [
      "Ailece müşterilerimize hizmet veriyoruz",
      "İlgili bilgiyi sonra ekleriz",
      "Kaliteli hizmet veriyoruz",
    ]) {
      expect(resolveVixrexIntentsAll(input).map((a) => a.anahtar)).not.toContain("il");
    }
  });
});
