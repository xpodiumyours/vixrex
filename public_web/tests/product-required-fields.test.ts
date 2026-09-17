import { describe, expect, it } from "vitest";
import {
  eksikZorunluAlanlar,
  eksikZorunluAlanMesaji,
} from "../src/lib/productRequiredFields";
import { requiredProductAttributes } from "../src/lib/productAttributeSchema";

describe("zorunlu ürün detayları", () => {
  it("giyimde marka, KDV, renk, beden ve materyal zorunludur", () => {
    expect(requiredProductAttributes("fashion").map((alan) => alan.key)).toEqual([
      "brand",
      "vatRate",
      "color",
      "size",
      "material",
    ]);
  });

  it("boş giyim ürününde beş eksik alanı da sayar", () => {
    const eksikler = eksikZorunluAlanlar({ templateKey: "fashion", brand: "", metadata: {} });
    expect(eksikler.map((eksik) => eksik.key)).toEqual([
      "brand",
      "vatRate",
      "color",
      "size",
      "material",
    ]);
  });

  it("alanlar dolunca eksik kalmaz", () => {
    const eksikler = eksikZorunluAlanlar({
      templateKey: "fashion",
      brand: "Vixrex",
      metadata: {
        templateKey: "fashion",
        attributes: [
          { key: "vatRate", label: "KDV oranı (%)", value: "10" },
          { key: "color", label: "Renk", value: "Siyah" },
          { key: "size", label: "Beden", value: "M" },
          { key: "material", label: "Materyal", value: "Pamuk" },
        ],
      },
    });
    expect(eksikler).toEqual([]);
  });

  it("boşluktan ibaret değeri dolu saymaz", () => {
    const eksikler = eksikZorunluAlanlar({
      templateKey: "food",
      brand: "   ",
      metadata: { templateKey: "food", attributes: [{ key: "netQuantity", label: "Net miktar", value: "  " }] },
    });
    expect(eksikler.map((eksik) => eksik.key)).toContain("brand");
    expect(eksikler.map((eksik) => eksik.key)).toContain("netQuantity");
  });

  it("hizmette marka değil, hizmet alanları zorunludur", () => {
    const eksikler = eksikZorunluAlanlar({ templateKey: "service", brand: null, metadata: {} });
    expect(eksikler.map((eksik) => eksik.key)).toEqual([
      "serviceType",
      "priceMode",
      "serviceLocation",
    ]);
  });

  it("hizmet alanları metadata.service içinden okunur", () => {
    const eksikler = eksikZorunluAlanlar({
      templateKey: "service",
      brand: null,
      metadata: {
        templateKey: "service",
        service: { serviceType: "Saç kesimi", priceMode: "fixed", serviceLocation: "business" },
      },
    });
    expect(eksikler).toEqual([]);
  });

  it("genel şablonda yalnız marka ve KDV zorunludur", () => {
    const eksikler = eksikZorunluAlanlar({ templateKey: "generic", brand: null, metadata: {} });
    expect(eksikler.map((eksik) => eksik.key)).toEqual(["brand", "vatRate"]);
  });

  it("renk ve beden varyanttan girilmişse tekrar sormaz", () => {
    const eksikler = eksikZorunluAlanlar({
      templateKey: "fashion",
      brand: "Aymira",
      metadata: {
        templateKey: "fashion",
        attributes: [
          { key: "vatRate", label: "KDV oranı (%)", value: "10" },
          { key: "material", label: "Materyal", value: "Pamuk" },
        ],
      },
      variants: [
        { id: "v1", options: { color: "Siyah", size: "M" } },
        { id: "v2", options: { color: "Beyaz", size: "L" } },
      ],
    });
    expect(eksikler).toEqual([]);
  });

  it("varyant sadece varyant olabilen alani karsilar, markayi karsilamaz", () => {
    const eksikler = eksikZorunluAlanlar({
      templateKey: "fashion",
      brand: "",
      metadata: { templateKey: "fashion" },
      variants: [{ id: "v1", options: { color: "Siyah", size: "M" } }],
    });
    expect(eksikler.map((eksik) => eksik.key)).toEqual(["brand", "vatRate", "material"]);
  });

  it("esnafa okunur tek cümle üretir", () => {
    expect(eksikZorunluAlanMesaji([])).toBeNull();
    expect(eksikZorunluAlanMesaji([{ key: "color", label: "Renk" }])).toBe("Renk alanı zorunludur.");
    expect(
      eksikZorunluAlanMesaji([
        { key: "color", label: "Renk" },
        { key: "size", label: "Beden" },
      ]),
    ).toBe("Şu alanlar zorunludur: Renk, Beden.");
  });
});
