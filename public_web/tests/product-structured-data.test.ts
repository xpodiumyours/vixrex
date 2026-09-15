import { describe, expect, it } from "vitest";
import {
  buildPhysicalProductStructuredData,
  normalizeGoogleGtin,
  parseProductPriceAmount,
} from "../src/lib/productStructuredData";
import type { RichProductItem } from "../src/lib/richProductItem";

const baseProduct: RichProductItem = {
  id: "product-123",
  slug: "keten-gomlek",
  name: "Keten Gömlek",
  description: "Keten karışımlı gömlek",
  price: "1.299 TL",
  priceAmount: 1299,
  currency: "TRY",
  stockStatus: "Mevcut",
  stockQuantity: 8,
  brand: "Örnek Marka",
  barcode: "8690000000005",
  metadata: {
    schemaVersion: 2,
    itemKind: "physical",
    templateKey: "fashion",
    identifiers: { sku: "KG-001" },
    attributes: [
      { key: "vatRate", label: "KDV oranı (%)", value: "20" },
      { key: "material", label: "Materyal", value: "Keten" },
    ],
  },
  imageUrls: ["https://example.com/product.jpg"],
};

describe("product structured data", () => {
  it("Türkçe fiyat yazımını schema.org fiyatına doğru çevirir", () => {
    expect(parseProductPriceAmount("1.299 TL")).toBe("1299");
    expect(parseProductPriceAmount("1.299,90 TL")).toBe("1299.9");
    expect(parseProductPriceAmount("1299,90 TL")).toBe("1299.9");
    expect(parseProductPriceAmount("Fiyat sorun")).toBeUndefined();
  });

  it("yalnız geçerli GS1 biçimli GTIN değerini Google verisine taşır", () => {
    expect(normalizeGoogleGtin("8690000000005")).toBe("8690000000005");
    expect(normalizeGoogleGtin("8690000000001")).toBeUndefined();
    expect(normalizeGoogleGtin("MAGAZA-123")).toBeUndefined();
    expect(normalizeGoogleGtin("02000000000007")).toBeUndefined();
  });

  it("varyantsız fiziksel ürünü Product olarak üretir", () => {
    const result = buildPhysicalProductStructuredData({
      product: baseProduct,
      productUrl: "https://vixrex.com/v/magaza/urun/keten-gomlek",
      storeName: "Örnek Mağaza",
      description: "Keten karışımlı gömlek",
      images: ["https://example.com/product.jpg"],
    });

    expect(result).toMatchObject({
      "@type": "Product",
      name: "Keten Gömlek",
      gtin13: "8690000000005",
      sku: "KG-001",
      offers: {
        priceCurrency: "TRY",
        price: "1299",
        availability: "https://schema.org/InStock",
      },
    });
  });

  it("geçersiz barkodu ürün verisinde tutsa da GTIN structured data olarak yayınlamaz", () => {
    const result = buildPhysicalProductStructuredData({
      product: { ...baseProduct, barcode: "MAGAZA-123" },
      productUrl: "https://vixrex.com/v/magaza/urun/keten-gomlek",
      storeName: "Örnek Mağaza",
      description: "Keten karışımlı gömlek",
      images: ["https://example.com/product.jpg"],
    }) as Record<string, unknown>;

    expect(result.gtin).toBeUndefined();
    expect(result.gtin8).toBeUndefined();
    expect(result.gtin12).toBeUndefined();
    expect(result.gtin13).toBeUndefined();
    expect(result.gtin14).toBeUndefined();
  });

  it("varyantlı ürünü ProductGroup ve doğrudan seçilebilir varyant URL'leriyle üretir", () => {
    const result = buildPhysicalProductStructuredData({
      product: {
        ...baseProduct,
        variants: [
          {
            id: "red-s",
            options: { color: "Kırmızı", size: "S" },
            sku: "KG-RED-S",
            barcode: "4006381333931",
            priceAmount: 1299,
            stockQuantity: 3,
            imageUrls: ["https://example.com/red-s.jpg"],
          },
          {
            id: "blue-m",
            options: { color: "Mavi", size: "M" },
            sku: "KG-BLUE-M",
            priceAmount: 1399,
            stockQuantity: 0,
            imageUrls: ["https://example.com/blue-m.jpg"],
          },
        ],
      },
      productUrl: "https://vixrex.com/v/magaza/urun/keten-gomlek",
      storeName: "Örnek Mağaza",
      description: "Keten karışımlı gömlek",
      images: ["https://example.com/product.jpg"],
    });

    expect(result).toMatchObject({
      "@type": "ProductGroup",
      productGroupID: "product-123",
      variesBy: ["https://schema.org/color", "https://schema.org/size"],
      hasVariant: [
        {
          "@type": "Product",
          color: "Kırmızı",
          size: "S",
          sku: "KG-RED-S",
          gtin13: "4006381333931",
          url: "https://vixrex.com/v/magaza/urun/keten-gomlek?variant=red-s",
          offers: {
            url: "https://vixrex.com/v/magaza/urun/keten-gomlek?variant=red-s",
            availability: "https://schema.org/InStock",
          },
        },
        {
          "@type": "Product",
          color: "Mavi",
          size: "M",
          sku: "KG-BLUE-M",
          url: "https://vixrex.com/v/magaza/urun/keten-gomlek?variant=blue-m",
          offers: {
            availability: "https://schema.org/OutOfStock",
          },
        },
      ],
    });
  });

  it("stok metnindeki tükendi bilgisini OutOfStock üretir", () => {
    const result = buildPhysicalProductStructuredData({
      product: {
        ...baseProduct,
        priceAmount: null,
        price: "1.299 TL",
        stockQuantity: null,
        stockStatus: "Stokta yok",
      },
      productUrl: "https://vixrex.com/v/magaza/urun/keten-gomlek",
      storeName: "Örnek Mağaza",
      description: "Keten karışımlı gömlek",
      images: ["https://example.com/product.jpg"],
    });

    expect(result).toMatchObject({
      offers: {
        price: "1299",
        availability: "https://schema.org/OutOfStock",
      },
    });
  });
});
