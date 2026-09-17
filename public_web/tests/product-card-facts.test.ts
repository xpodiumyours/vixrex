import { describe, expect, it } from "vitest";
import { buildProductCardFacts } from "../src/lib/productCardPresentation";

describe("ürün kartında gösterilen bilgiler", () => {
  it("giyim kartında marka, renk ve beden gösterir", () => {
    const kart = buildProductCardFacts({
      brand: "Aymira",
      metadata: {
        itemKind: "physical",
        templateKey: "fashion",
        attributes: [
          { key: "color", label: "Renk", value: "Siyah" },
          { key: "size", label: "Beden", value: "M" },
          { key: "material", label: "Materyal", value: "Pamuk" },
        ],
      },
    });
    expect(kart.marka).toBe("Aymira");
    expect(kart.ozellikler.map((alan) => alan.value)).toEqual(["Siyah", "M"]);
  });

  it("materyal gibi karta açılmamış alanı kartta göstermez", () => {
    const kart = buildProductCardFacts({
      brand: null,
      metadata: {
        itemKind: "physical",
        templateKey: "fashion",
        attributes: [{ key: "material", label: "Materyal", value: "Keten" }],
      },
    });
    expect(kart.ozellikler).toEqual([]);
  });

  it("gıda kartında net miktarı gösterir", () => {
    const kart = buildProductCardFacts({
      brand: "Doğal Market",
      metadata: {
        itemKind: "physical",
        templateKey: "food",
        attributes: [
          { key: "netQuantity", label: "Net miktar", value: "500 g" },
          { key: "origin", label: "Menşei", value: "Türkiye" },
        ],
      },
    });
    expect(kart.marka).toBe("Doğal Market");
    expect(kart.ozellikler.map((alan) => alan.value)).toEqual(["500 g"]);
  });

  it("hizmet kartında süre, fiyat biçimi ve yer gösterir; marka göstermez", () => {
    const kart = buildProductCardFacts({
      brand: "Yok Sayılmalı",
      metadata: {
        itemKind: "service",
        templateKey: "service",
        service: {
          serviceType: "Saç kesimi",
          durationMinutes: 45,
          priceMode: "fixed",
          serviceLocation: "business",
        },
      },
    });
    expect(kart.marka).toBeNull();
    expect(kart.ozellikler.map((alan) => alan.value)).toEqual([
      "45 dk",
      "Sabit fiyat",
      "İşletmede",
    ]);
  });

  it("boş üründe kartta fazladan satır açmaz", () => {
    const kart = buildProductCardFacts({ brand: null, metadata: {} });
    expect(kart.marka).toBeNull();
    expect(kart.ozellikler).toEqual([]);
  });

  it("kartı en fazla üç bilgiyle sınırlar", () => {
    const kart = buildProductCardFacts({
      brand: null,
      metadata: {
        itemKind: "service",
        templateKey: "service",
        service: { durationMinutes: 30, priceMode: "ask", serviceLocation: "remote" },
      },
      limit: 2,
    });
    expect(kart.ozellikler).toHaveLength(2);
  });
});
