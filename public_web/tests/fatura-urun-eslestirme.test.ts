import { describe, expect, it } from "vitest";
import { ayniUrunMu } from "../src/lib/faturaUrunBaglantisi";

function urun(ek: Record<string, unknown> = {}) {
  return {
    name: "Pınar Süzme Peynir",
    brand: "PINAR",
    variants: [],
    ...ek,
  };
}

describe("fatura satırı var olan ürüne bağlanırken", () => {
  it("marka yazımı farklı olsa da aynı ürünü bulur (SÜTAŞ = SUTAŞ)", () => {
    expect(
      ayniUrunMu(
        urun({ name: "Sütaş Ayran 300 ml", brand: "SÜTAŞ" }),
        urun({ name: "Sutaş Ayran 300 ml", brand: "SUTAŞ" }),
      ),
    ).toBe(true);
  });

  it("parantezli ek adı farklı yazsa da aynı ürünü bulur", () => {
    expect(
      ayniUrunMu(
        urun({ name: "Pınar Yağlı Süt 1 L", brand: "PINAR" }),
        urun({ name: "Pınar Yağlı Süt (Tam Yağlı) 1 L", brand: "PINAR" }),
      ),
    ).toBe(true);
  });

  it("aynı ad ve markada miktar farklıysa ayrı kart açar", () => {
    expect(
      ayniUrunMu(
        urun({ name: "Coca-Cola Orijinal Tat 330 ml", brand: "COCA-COLA" }),
        urun({ name: "Coca-Cola Orijinal Tat 250 ml", brand: "COCA-COLA" }),
      ),
    ).toBe(false);
  });

  it("ölçü birimini aynı tabana çevirerek karşılaştırır (1 kg = 1000 g)", () => {
    expect(
      ayniUrunMu(
        urun({ name: "Torku Toz Şeker 1 kg", brand: "TORKU" }),
        urun({ name: "Torku Toz Şeker 1000 g", brand: "TORKU" }),
      ),
    ).toBe(true);
  });

  it("marka farklıysa aynı ada rağmen birleştirmez", () => {
    expect(
      ayniUrunMu(
        urun({ name: "Süzme Peynir 500 g", brand: "PINAR" }),
        urun({ name: "Süzme Peynir 500 g", brand: "SÜTAŞ" }),
      ),
    ).toBe(false);
  });

  it("ad çekirdeği farklıysa birleştirmez", () => {
    expect(
      ayniUrunMu(
        urun({ name: "Popkek 60 g", brand: "ETİ" }),
        urun({ name: "Popkek Kakaolu 60 g", brand: "ETİ" }),
      ),
    ).toBe(false);
  });

  it("varyantlar çakışmıyorsa birleştirmez", () => {
    expect(
      ayniUrunMu(
        urun({
          name: "Pınar Süzme Peynir 500 g",
          variants: [{ id: "v1", options: { variant: "Süzme Beyaz" } }],
        }),
        urun({
          name: "Pınar Süzme Peynir 500 g",
          variants: [{ id: "v2", options: { variant: "Beyaz" } }],
        }),
      ),
    ).toBe(false);
  });

  it("aynı ürünü ikinci kez kart açmadan mevcut karta bağlar", () => {
    expect(
      ayniUrunMu(
        urun({ name: "Popkek Kakaolu 60 g", brand: "ETİ" }),
        urun({ name: "ETİ Popkek Kakaolu 60 g", brand: "ETİ" }),
      ),
    ).toBe(true);
  });
});
