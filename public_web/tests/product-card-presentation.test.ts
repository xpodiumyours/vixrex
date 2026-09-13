import { describe, expect, it } from "vitest";
import {
  buildProductQuickFacts,
  productVariantCount,
  productVariantLabel,
} from "../src/lib/productCardPresentation";

describe("ürün kartı veri sunumu", () => {
  it("moda ürününde yalnız quick yüzeyindeki gerçek alanları döndürür", () => {
    const facts = buildProductQuickFacts({
      brand: "Vix Marka",
      metadata: {
        itemKind: "physical",
        templateKey: "fashion",
        attributes: [
          { key: "color", value: "Siyah" },
          { key: "size", value: "M" },
          { key: "material", value: "Pamuk" },
          { key: "pattern", value: "Düz" },
        ],
      },
    });

    expect(facts).toEqual([
      { key: "brand", label: "Marka", value: "Vix Marka" },
      { key: "color", label: "Renk", value: "Siyah" },
      { key: "size", label: "Beden", value: "M" },
      { key: "material", label: "Materyal", value: "Pamuk" },
    ]);
  });

  it("hizmet kaydında ürün alanı uydurmaz; hizmet verisini Türkçe sunar", () => {
    const facts = buildProductQuickFacts({
      brand: "Gösterilmemeli",
      metadata: {
        itemKind: "service",
        templateKey: "service",
        service: {
          serviceType: "Telefon ekran değişimi",
          priceMode: "starting_from",
          durationMinutes: 45,
          serviceLocation: "customer",
        },
      },
    });

    expect(facts).toEqual([
      { key: "serviceType", label: "Hizmet türü", value: "Telefon ekran değişimi" },
      { key: "priceMode", label: "Fiyat biçimi", value: "Başlangıç fiyatı" },
      { key: "durationMinutes", label: "Tahmini süre", value: "45 dk" },
      { key: "serviceLocation", label: "Hizmet yeri", value: "Müşteri adresinde" },
    ]);
  });

  it("şemada quick olmayan veya bilinmeyen alanı hızlı görünüm verisine sokmaz", () => {
    const facts = buildProductQuickFacts({
      metadata: {
        itemKind: "physical",
        templateKey: "electronics",
        attributes: [
          { key: "model", value: "X100" },
          { key: "warranty", value: "2 yıl" },
          { key: "uydurmaAlan", value: "gösterme" },
        ],
      },
    });

    expect(facts).toEqual([{ key: "model", label: "Model", value: "X100" }]);
  });

  it("yalnız geçerli varyantları sayar ve birden fazla seçenek varsa etiket üretir", () => {
    const variants = [
      { id: "", options: { color: "Siyah" } },
      { id: "v1", options: { color: "Siyah" } },
      { id: "v2", options: { color: "Beyaz" } },
      { id: "v3", options: {} },
    ];
    expect(productVariantCount(variants)).toBe(2);
    expect(productVariantLabel(variants)).toBe("2 seçenek");
    expect(productVariantLabel([{ id: "v1", options: { color: "Siyah" } }])).toBeNull();
  });
});
