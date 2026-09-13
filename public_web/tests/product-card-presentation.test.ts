import { describe, expect, it } from "vitest";
import {
  buildProductDetailFacts,
  buildProductQuickFacts,
  buildVariantOptionGroups,
  findMatchingVariant,
  productVariantCount,
  productVariantLabel,
  variantOptionIsAvailable,
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

  it("hizmet detayında eski ürün marka barkod SKU ve MPN alanlarını göstermez", () => {
    const facts = buildProductDetailFacts({
      brand: "Eski Marka",
      barcode: "8690000000000",
      metadata: {
        itemKind: "service",
        templateKey: "service",
        identifiers: { sku: "OLD-SKU", mpn: "OLD-MPN" },
        service: {
          serviceType: "Kurulum",
          priceMode: "fixed",
          serviceLocation: "business",
        },
      },
    });

    expect(facts).toEqual([
      { key: "serviceType", label: "Hizmet türü", value: "Kurulum" },
      { key: "priceMode", label: "Fiyat biçimi", value: "Sabit fiyat" },
      { key: "serviceLocation", label: "Hizmet yeri", value: "İşletmede" },
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

  it("varyant seçeneklerini kategori etiketleriyle gruplar ve tam kombinasyonu bulur", () => {
    const variants = [
      {
        id: "black-m",
        options: { color: "Siyah", size: "M" },
        priceAmount: 749,
        stockQuantity: 4,
      },
      {
        id: "black-l",
        options: { color: "Siyah", size: "L" },
        priceAmount: 779,
        stockQuantity: 2,
      },
      {
        id: "white-m",
        options: { color: "Beyaz", size: "M" },
        priceAmount: 759,
        stockQuantity: 0,
      },
    ];

    expect(buildVariantOptionGroups(variants, "fashion")).toEqual([
      { key: "color", label: "Renk", values: ["Siyah", "Beyaz"] },
      { key: "size", label: "Beden", values: ["M", "L"] },
    ]);
    expect(findMatchingVariant(variants, { color: "Siyah", size: "L" }, "fashion")?.id).toBe(
      "black-l",
    );
    expect(findMatchingVariant(variants, { color: "Beyaz", size: "L" }, "fashion")).toBeNull();
  });

  it("mevcut seçimle var olmayan varyant seçeneğini kullanılabilir saymaz", () => {
    const variants = [
      { id: "black-m", options: { color: "Siyah", size: "M" } },
      { id: "black-l", options: { color: "Siyah", size: "L" } },
      { id: "white-m", options: { color: "Beyaz", size: "M" } },
    ];

    expect(
      variantOptionIsAvailable(
        variants,
        { color: "Beyaz", size: "M" },
        "size",
        "L",
        "fashion",
      ),
    ).toBe(false);
    expect(
      variantOptionIsAvailable(
        variants,
        { color: "Siyah", size: "M" },
        "size",
        "L",
        "fashion",
      ),
    ).toBe(true);
  });

  it("kategori değişince eski kategoriye ait varyantları müşteriye taşımaz", () => {
    const variants = [
      { id: "mixed", options: { size: "M", ram: "8 GB" } },
      { id: "fashion-only", options: { size: "L" } },
      { id: "electronics", options: { ram: "16 GB", storageCapacity: "256 GB" } },
    ];

    expect(buildVariantOptionGroups(variants, "electronics")).toEqual([
      { key: "ram", label: "RAM", values: ["8 GB", "16 GB"] },
      { key: "storageCapacity", label: "Depolama kapasitesi", values: ["256 GB"] },
    ]);
    expect(productVariantCount(variants, "electronics")).toBe(2);
    expect(productVariantLabel(variants, "electronics")).toBe("2 seçenek");
    expect(findMatchingVariant(variants, { size: "L" }, "electronics")).toBeNull();
  });
});