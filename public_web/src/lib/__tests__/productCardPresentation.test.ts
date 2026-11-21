import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import {
  buildConsumerDetailFacts,
  buildProductCardFacts,
  buildProductQuickFacts,
} from "../productCardPresentation";

vi.mock("next/navigation", () => ({
  useSearchParams: () => new URLSearchParams(),
  usePathname: () => "/v/ornek-magaza",
  useRouter: () => ({ push: vi.fn(), replace: vi.fn() }),
}));

vi.mock("next/image", () => ({
  default: (props: Record<string, unknown>) =>
    createElement("img", {
      src: String(props.src ?? ""),
      alt: String(props.alt ?? ""),
      className: String(props.className ?? ""),
    }),
}));

import ProductCatalog from "../../app/v/[slug]/ProductCatalog";

describe("buildProductCardFacts resmi kaynak, GTIN ve konum sözleşmesi", () => {
  it("doğrulanmış resmi kaynak ve geçerli GS1 GTIN için tam rozet üretir", () => {
    const kart = buildProductCardFacts({
      brand: "Tutku",
      barcode: "8690000000005",
      stockQuantity: 12,
      stockStatus: "Mevcut",
      metadata: {
        schemaVersion: 2,
        itemKind: "physical",
        templateKey: "fashion",
        manufacturerSource: {
          url: "https://www.sehermensucat.com/urun/fanila",
          verificationStatus: "Doğrulandı",
        },
        attributes: [{ key: "color", label: "Renk", value: "Beyaz" }],
      },
      storeLocation: {
        district_name: "Kadıköy",
        province_name: "İstanbul",
        mapsUrl: "https://www.google.com/maps/search/?api=1&query=Kadikoy",
      },
    });

    expect(kart.gtin).toBe("8690000000005");
    expect(kart.resmiKaynak).toEqual({
      url: "https://www.sehermensucat.com/urun/fanila",
      alanAdi: "sehermensucat.com",
    });
    expect(kart.resmiKatalogRozeti).toBe("Resmi Üretici Kataloğu / GS1");
    expect(kart.location).toEqual({
      ilceIlMetni: "Kadıköy, İstanbul",
      mapsUrl: "https://www.google.com/maps/search/?api=1&query=Kadikoy",
      raftaHazirMi: true,
      rozetMetni: "Kadıköy, İstanbul · Rafta Hazır",
    });
  });

  it("yalnız resmi kaynak doğrulandıysa GS1 iddiası üretmez", () => {
    const kart = buildProductCardFacts({
      brand: "Tutku",
      barcode: "MAGAZA-123",
      metadata: {
        itemKind: "physical",
        templateKey: "generic",
        manufacturerSource: {
          url: "https://sehermensucat.com/urun",
          verificationStatus: "verified",
        },
      },
    });

    expect(kart.gtin).toBeNull();
    expect(kart.resmiKatalogRozeti).toBe("Resmi Üretici Kataloğu");
  });

  it("yalnız geçerli GS1 barkodu varsa GS1 GTIN rozeti üretir", () => {
    const kart = buildProductCardFacts({
      barcode: "8690000000005",
      metadata: {
        itemKind: "physical",
        templateKey: "generic",
        manufacturerSource: {
          url: "https://sehermensucat.com/urun",
          verificationStatus: "? Belirsiz",
        },
      },
    });

    expect(kart.resmiKaynak).toBeNull();
    expect(kart.gtin).toBe("8690000000005");
    expect(kart.resmiKatalogRozeti).toBe("GS1 GTIN");
  });

  it("adres üzerinden ilçe ve il çıkarımı yapar, mapsUrl verilmediyse arama linki türetir", () => {
    const kart = buildProductCardFacts({
      stockStatus: "Mevcut",
      storeLocation: {
        address: "Bağdat Cad. No:120, Kadıköy, İstanbul",
      },
    });

    expect(kart.location).toEqual({
      ilceIlMetni: "Kadıköy, İstanbul",
      mapsUrl:
        "https://www.google.com/maps/search/?api=1&query=Ba%C4%9Fdat%20Cad.%20No%3A120%2C%20Kad%C4%B1k%C3%B6y%2C%20%C4%B0stanbul",
      raftaHazirMi: true,
      rozetMetni: "Kadıköy, İstanbul · Rafta Hazır",
    });
  });

  it("ilçe ve il adı aynıysa metni tekrarlamaz", () => {
    const kart = buildProductCardFacts({
      storeLocation: {
        district_name: "İstanbul",
        province_name: "İstanbul",
        mapsUrl: null,
      },
    });

    expect(kart.location).toEqual({
      ilceIlMetni: "İstanbul",
      mapsUrl: null,
      raftaHazirMi: true,
      rozetMetni: "İstanbul · Rafta Hazır",
    });
  });

  it("stok tükendiğinde veya siparişle temin edildiğinde raftaHazirMi false döner", () => {
    const sifirStok = buildProductCardFacts({
      stockQuantity: 0,
      storeLocation: { district_name: "Beşiktaş", province_name: "İstanbul" },
    });
    expect(sifirStok.location?.raftaHazirMi).toBe(false);
    expect(sifirStok.location?.rozetMetni).toBeNull();
    expect(sifirStok.location?.ilceIlMetni).toBe("Beşiktaş, İstanbul");

    const tukendiMetni = buildProductCardFacts({
      stockStatus: "Tükendi",
      storeLocation: { district_name: "Beşiktaş", province_name: "İstanbul" },
    });
    expect(tukendiMetni.location?.raftaHazirMi).toBe(false);
    expect(tukendiMetni.location?.rozetMetni).toBeNull();

    const siparisle = buildProductCardFacts({
      stockStatus: "Siparişle hazırlanır",
      storeLocation: { district_name: "Beşiktaş", province_name: "İstanbul" },
    });
    expect(siparisle.location?.raftaHazirMi).toBe(false);
    expect(siparisle.location?.rozetMetni).toBeNull();
  });

  it("hizmet kayıtlarında GTIN, resmi kaynak ve Rafta Hazır rozeti üretmez", () => {
    const kart = buildProductCardFacts({
      barcode: "8690000000005",
      metadata: {
        itemKind: "service",
        templateKey: "service",
        manufacturerSource: {
          url: "https://uretici.example/hizmet",
          verificationStatus: "Doğrulandı",
        },
        service: { durationMinutes: 30, priceMode: "fixed", serviceLocation: "business" },
      },
      storeLocation: {
        district_name: "Çankaya",
        province_name: "Ankara",
      },
    });

    expect(kart.gtin).toBeNull();
    expect(kart.resmiKaynak).toBeNull();
    expect(kart.resmiKatalogRozeti).toBeNull();
    expect(kart.location?.raftaHazirMi).toBe(false);
    expect(kart.location?.rozetMetni).toBeNull();
    expect(kart.location?.ilceIlMetni).toBe("Çankaya, Ankara");
  });

  it("mahalle, ilçe ve ili tekrarsız tek konum metninde birleştirir", () => {
    const kart = buildProductCardFacts({
      storeLocation: {
        neighborhood_name: "Caddebostan",
        district_name: "Kadıköy",
        province_name: "İstanbul",
      },
    });

    expect(kart.location?.ilceIlMetni).toBe("Caddebostan, Kadıköy, İstanbul");
  });

  it("geçersiz veya tehlikeli URL şemalarını reddeder", () => {
    const kart = buildProductCardFacts({
      barcode: "02000000000007",
      metadata: {
        itemKind: "physical",
        templateKey: "generic",
        manufacturerSource: {
          url: "javascript:alert(1)",
          verificationStatus: "Doğrulandı",
        },
      },
      storeLocation: {
        district_name: "Konak",
        province_name: "İzmir",
        mapsUrl: "javascript:alert(1)",
      },
    });

    expect(kart.gtin).toBeNull();
    expect(kart.resmiKaynak).toBeNull();
    expect(kart.resmiKatalogRozeti).toBeNull();
    expect(kart.location?.mapsUrl).toBeNull();
  });

  it("Kural 32: fatura toptan alış fiyatı ve VKN bilgilerini hiçbir yüzeyde sızdırmaz", () => {
    const zehirliMetadata = {
      lunaInvoice: true,
      itemKind: "physical",
      templateKey: "generic",
      attributes: [
        { key: "vkn", label: "VKN", value: "1234567890" },
        { key: "vergiNo", label: "Vergi No", value: "9876543210" },
        { key: "alisFiyati", label: "Alış fiyatı", value: "42,50 TL" },
        { key: "purchasePrice", label: "Fatura alış fiyatı", value: 42.5 },
        { key: "toptanFiyat", label: "Toptan fiyat", value: "40 TL" },
        { key: "unitPrice", label: "Birim alış", value: "42,50 TL" },
        { key: "color", label: "Renk", value: "Lacivert" },
      ],
    };

    const kart = buildProductCardFacts({
      metadata: zehirliMetadata,
      storeLocation: {
        district_name: "VKN 1234567890",
        province_name: "Alış fiyatı 42 TL",
        address: "Toptan fiyat gizli",
        mapsUrl: "https://www.google.com/maps/search/?api=1&query=VKN%201234567890",
      },
    });

    expect(kart.ozellikler.map((o) => o.value)).toEqual(["Lacivert"]);
    expect(kart.location).toBeNull();
    expect(buildProductQuickFacts({ metadata: zehirliMetadata }).map((o) => o.value)).toEqual(["Lacivert"]);
    expect(buildConsumerDetailFacts({ metadata: zehirliMetadata }).map((o) => o.value)).toEqual(["Lacivert"]);
  });
});

describe("ProductCatalog kart konumu ve Material görünüm render doğrulaması", () => {
  it("rafta hazır üründe aspect-square, resmi katalog rozeti ve tıklanabilir Google Maps rozeti basar; Kural 32 verisi sızdırmaz", () => {
    const html = renderToStaticMarkup(
      createElement(ProductCatalog, {
        storeSlug: "ornek-magaza",
        storeName: "Örnek Mağaza",
        storeLocationText: "Bağdat Cad. No:120, Kadıköy, İstanbul",
        storeDistrictName: "Kadıköy",
        storeProvinceName: "İstanbul",
        storeMapsUrl: "https://www.google.com/maps/search/?api=1&query=Kadikoy",
        trackingEnabled: false,
        categoryMap: [{ id: "cat-1", name: "İç Giyim" }],
        products: [
          {
            id: "prod-1",
            slug: "tutku-fanila",
            name: "Tutku Pamuklu Fanila",
            description: "Pamuklu fanila",
            price: "249 TL",
            priceAmount: 249,
            stockStatus: "Mevcut",
            stockQuantity: 10,
            category: "İç Giyim",
            categoryId: "cat-1",
            brand: "Tutku",
            barcode: "8690000000005",
            imageUrls: ["https://cdn.example/fanila.webp"],
            metadata: {
              lunaInvoice: true,
              itemKind: "physical",
              templateKey: "fashion",
              manufacturerSource: {
                url: "https://sehermensucat.com/urun/fanila",
                verificationStatus: "Doğrulandı",
              },
              attributes: [
                { key: "color", label: "Renk", value: "Beyaz" },
                { key: "vkn", label: "VKN", value: "5554443322" },
                { key: "alisFiyati", label: "Alış fiyatı", value: "99 TL" },
              ],
            },
          },
        ],
      }),
    );

    expect(html).toContain("aspect-square");
    expect(html).toContain("Resmi Üretici Kataloğu / GS1");
    expect(html).toContain("Kadıköy, İstanbul · Rafta Hazır");
    expect(html).toContain("alt=\"Tutku Pamuklu Fanila - Örnek Mağaza - Kadıköy\"");
    expect(html).toContain('href="https://www.google.com/maps/search/?api=1&amp;query=Kadikoy"');
    expect(html).toContain('target="_blank"');
    expect(html).toContain('rel="noopener noreferrer"');
    expect(html).not.toContain("5554443322");
    expect(html).not.toContain("99 TL");
  });

  it("tükendi durumunda Google Maps Rafta Hazır rozeti basmaz", () => {
    const html = renderToStaticMarkup(
      createElement(ProductCatalog, {
        storeSlug: "ornek-magaza",
        storeName: "Örnek Mağaza",
        storeDistrictName: "Kadıköy",
        storeProvinceName: "İstanbul",
        storeMapsUrl: "https://www.google.com/maps/search/?api=1&query=Kadikoy",
        trackingEnabled: false,
        categoryMap: [],
        products: [
          {
            id: "prod-2",
            slug: "tukenen-urun",
            name: "Tükenen Ürün",
            price: "199 TL",
            priceAmount: 199,
            stockStatus: "Tükendi",
            stockQuantity: 0,
            imageUrls: ["https://cdn.example/urun.webp"],
          },
        ],
      }),
    );

    expect(html).not.toContain("Rafta Hazır");
    expect(html).toContain("Kadıköy, İstanbul");
  });
});
