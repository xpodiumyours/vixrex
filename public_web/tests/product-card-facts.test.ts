import { describe, expect, it } from "vitest";
import {
  buildProductCardFacts,
  eskiFiyatYazisi,
  indirimOrani,
  kartRozeti,
} from "../src/lib/productCardPresentation";

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

describe("kart fiyat ve indirim gösterimi", () => {
  it("indirim oranını iki fiyattan kendisi hesaplar", () => {
    expect(indirimOrani({ priceAmount: 899, oldPriceAmount: 1299 })).toBe(31);
    expect(indirimOrani({ priceAmount: 500, oldPriceAmount: 1000 })).toBe(50);
  });

  it("indirim yoksa oran üretmez", () => {
    expect(indirimOrani({ priceAmount: 1000, oldPriceAmount: 1000 })).toBeNull();
    expect(indirimOrani({ priceAmount: 1200, oldPriceAmount: 1000 })).toBeNull();
    expect(indirimOrani({ priceAmount: 100, oldPriceAmount: null })).toBeNull();
  });

  it("esnaf kendi rozetini yazdıysa ona dokunmaz", () => {
    expect(
      kartRozeti({ badgeTag: "Yeni Sezon", priceAmount: 899, oldPriceAmount: 1299 }),
    ).toBe("Yeni Sezon");
  });

  it("rozet boşsa indirimi kendisi yazar", () => {
    expect(kartRozeti({ badgeTag: "", priceAmount: 899, oldPriceAmount: 1299 })).toBe("%31 indirim");
    expect(kartRozeti({ badgeTag: null, priceAmount: 899, oldPriceAmount: null })).toBeNull();
  });

  it("eski fiyatı güncel fiyatla aynı yazımda gösterir", () => {
    expect(eskiFiyatYazisi(1800)).toBe("1.800 TL");
    expect(eskiFiyatYazisi(499)).toBe("499 TL");
    expect(eskiFiyatYazisi(0)).toBeNull();
    expect(eskiFiyatYazisi(null)).toBeNull();
  });
});
