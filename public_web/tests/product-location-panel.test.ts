import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import {
  ProductInfoBody,
  ProductLocationPanel,
  bolgeHaritadaAranabilirMi,
} from "../src/components/ProductSurfaceShared";

describe("bolgeHaritadaAranabilirMi", () => {
  it("stok metinlerini haritada aranamaz sayar", () => {
    expect(bolgeHaritadaAranabilirMi("Mağaza stoğu")).toBe(false);
    expect(bolgeHaritadaAranabilirMi("mağaza stoğu")).toBe(false);
    expect(bolgeHaritadaAranabilirMi("MAĞAZA STOĞU")).toBe(false);
    expect(bolgeHaritadaAranabilirMi("Magaza stogu")).toBe(false);
    expect(bolgeHaritadaAranabilirMi("Rafta")).toBe(false);
    expect(bolgeHaritadaAranabilirMi("Rafta hazır")).toBe(false);
    expect(bolgeHaritadaAranabilirMi("İşletmede")).toBe(false);
  });

  it("gerçek bölgeyi aranabilir sayar", () => {
    expect(bolgeHaritadaAranabilirMi("Kadıköy, İstanbul")).toBe(true);
    expect(bolgeHaritadaAranabilirMi("Kadıköy, Üsküdar")).toBe(true);
    expect(bolgeHaritadaAranabilirMi("Taraftar Sk., Beşiktaş")).toBe(true);
  });

  it("boş değeri aranamaz sayar", () => {
    expect(bolgeHaritadaAranabilirMi("")).toBe(false);
    expect(bolgeHaritadaAranabilirMi("   ")).toBe(false);
  });
});

describe("ProductLocationPanel çıktısı", () => {
  const ortak = {
    isService: false,
    storeLocationLabel: "Kadıköy, İstanbul",
    storeAddress: "Moda Cd. 1",
    storeMapUrl: "https://maps.example/x",
  };

  it("stok metninde harita linki ve teslim bölgesi bloğu üretmez", () => {
    const html = renderToStaticMarkup(
      createElement(ProductLocationPanel, { ...ortak, fulfillmentRegion: "Mağaza stoğu" }),
    );
    expect(html).not.toContain("Haritada ara");
    expect(html).not.toContain("teslim bölgesi");
    expect(html).not.toContain("query=Ma");
    expect(html).toContain("İşletme konumu");
    expect(html).toContain("Yol tarifi");
  });

  it("gerçek bölgede harita linkini korur", () => {
    const html = renderToStaticMarkup(
      createElement(ProductLocationPanel, { ...ortak, fulfillmentRegion: "Kadıköy, Üsküdar" }),
    );
    expect(html).toContain("Haritada ara");
    expect(html).toContain("teslim bölgesi");
  });
});

describe("ProductInfoBody sırası", () => {
  it("çocuk içerik özellikler listesinden önce gelir", () => {
    const html = renderToStaticMarkup(
      createElement(
        ProductInfoBody,
        {
          isService: false,
          name: "Test ürün",
          heading: "h1",
          displayedPrice: "10 TL",
          variantGroups: [],
          selectedOptions: {},
          onSelectOption: () => undefined,
          isOptionAvailable: () => true,
          stockStatus: "Stokta",
          facts: [{ key: "renk", label: "ETIKET-RENK", value: "Mavi" }],
          description: "AciklamaMetni",
        },
        createElement("button", null, "COCUK-SATIN-AL"),
      ),
    );
    const cocuk = html.indexOf("COCUK-SATIN-AL");
    expect(cocuk).toBeGreaterThan(html.indexOf("Stokta"));
    expect(cocuk).toBeLessThan(html.indexOf("ETIKET-RENK"));
    expect(cocuk).toBeLessThan(html.indexOf("AciklamaMetni"));
  });
});
