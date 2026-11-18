import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import {
  resmiUrunSayfasiGroundingIleBul,
  type GroundingAramaGirdisi,
} from "@/lib/faturaUrunHazirlama";
import { CatalogProductImage } from "@/app/v/[slug]/ProductCatalog";

describe("Google Grounding ve Telif Kalkanı Sözleşmesi", () => {
  const originalApiKey = process.env.GEMINI_API_KEY;

  beforeEach(() => {
    process.env.GEMINI_API_KEY = "test-gemini-grounding-api-key";
  });

  afterEach(() => {
    process.env.GEMINI_API_KEY = originalApiKey;
  });

  // a) Pazaryeri reddi (Trendyol/Amazon vb. null döner ve pazaryeri görselleri filtrelenir)
  it("pazaryeri reddi: Trendyol/Amazon domain ve görselleri kesinlikle reddedilir", async () => {
    const fakeTrendyolResponse = {
      candidates: [
        {
          content: {
            parts: [
              {
                text: JSON.stringify({
                  official_domain: "trendyol.com",
                  official_product_url: "https://www.trendyol.com/marka/urun-p-123456",
                  official_name: "Marka Elbise",
                  brand: "Marka",
                  image_urls: [
                    "https://cdn.dsmcdn.com/mnresize/1200/1800/product.jpg",
                    "https://images.trendyol.com/p.jpg",
                  ],
                }),
              },
            ],
          },
          groundingMetadata: {
            groundingChunks: [
              { web: { uri: "https://www.trendyol.com/marka/urun-p-123456" } },
            ],
          },
        },
      ],
    };

    const trendyolFetcher = vi.fn(async () => ({
      ok: true,
      json: async () => fakeTrendyolResponse,
    })) as unknown as typeof fetch;

    const trendyolSonuc = await resmiUrunSayfasiGroundingIleBul(
      { urunAdi: "Marka Elbise", marka: "Marka" },
      trendyolFetcher,
    );
    expect(trendyolSonuc).toBeNull();

    const fakeAmazonResponse = {
      candidates: [
        {
          content: {
            parts: [
              {
                text: JSON.stringify({
                  official_domain: "amazon.com.tr",
                  official_product_url: "https://www.amazon.com.tr/dp/B00EXAMPLE",
                  official_name: "Amazon Ürün",
                  brand: "Marka",
                  image_urls: ["https://media-amazon.com/images/I/product.jpg"],
                }),
              },
            ],
          },
          groundingMetadata: {
            groundingChunks: [
              { web: { uri: "https://www.amazon.com.tr/dp/B00EXAMPLE" } },
            ],
          },
        },
      ],
    };

    const amazonSonuc = await resmiUrunSayfasiGroundingIleBul(
      { urunAdi: "Amazon Ürün" },
      vi.fn(async () => ({ ok: true, json: async () => fakeAmazonResponse })) as unknown as typeof fetch,
    );
    expect(amazonSonuc).toBeNull();

    // Resmi üretici sitesi kabul edilirken araya karışan pazaryeri görselleri temizlenir
    const fakeMixedImageResponse = {
      candidates: [
        {
          content: {
            parts: [
              {
                text: JSON.stringify({
                  official_domain: "vestel.com.tr",
                  official_product_url: "https://www.vestel.com.tr/vestel-smart-tv",
                  official_name: "Vestel Smart TV",
                  brand: "Vestel",
                  image_urls: [
                    "https://cdn.dsmcdn.com/mnresize/tv.jpg",
                    "https://images.trendyol.com/tv2.jpg",
                    "https://media-amazon.com/tv3.jpg",
                    "https://www.vestel.com.tr/media/tv.jpg",
                  ],
                }),
              },
            ],
          },
          groundingMetadata: {
            groundingChunks: [
              { web: { uri: "https://www.vestel.com.tr/vestel-smart-tv" } },
            ],
          },
        },
      ],
    };

    const mixedSonuc = await resmiUrunSayfasiGroundingIleBul(
      { urunAdi: "Vestel Smart TV", kilitliAlanAdi: "vestel.com.tr" },
      vi.fn(async () => ({ ok: true, json: async () => fakeMixedImageResponse })) as unknown as typeof fetch,
    );
    expect(mixedSonuc).not.toBeNull();
    expect(mixedSonuc?.resmiSayfa).toBe("https://www.vestel.com.tr/vestel-smart-tv");
    expect(mixedSonuc?.gorseller).toEqual(["https://www.vestel.com.tr/media/tv.jpg"]);
  });

  // b) Kilitli domain ihlali (üretici dışı site null döner)
  it("kilitli domain ihlali: üretici dışındaki domainler kesinlikle reddedilir", async () => {
    const fakeOtherDomainResponse = {
      candidates: [
        {
          content: {
            parts: [
              {
                text: JSON.stringify({
                  official_domain: "beko.com.tr",
                  official_product_url: "https://www.beko.com.tr/tv",
                  official_name: "Beko TV",
                  brand: "Beko",
                  image_urls: ["https://www.beko.com.tr/tv.jpg"],
                }),
              },
            ],
          },
          groundingMetadata: {
            groundingChunks: [
              { web: { uri: "https://www.beko.com.tr/tv" } },
            ],
          },
        },
      ],
    };

    const kilitliSonuc = await resmiUrunSayfasiGroundingIleBul(
      {
        urunAdi: "Vestel TV",
        marka: "Vestel",
        kilitliAlanAdi: "vestel.com.tr",
      },
      vi.fn(async () => ({ ok: true, json: async () => fakeOtherDomainResponse })) as unknown as typeof fetch,
    );

    expect(kilitliSonuc).toBeNull();
  });

  // c) Kural 32 sızıntı testi (toptan alış fiyatı/VKN asla Gemini prompt'a sızmaz)
  it("kural 32 sızıntı testi: toptan alış fiyatı ve VKN asla arama promptuna sızmaz", async () => {
    let yakalananIstekGovdesi = "";

    const captureFetcher = vi.fn(async (_url, init) => {
      yakalananIstekGovdesi = String(init?.body ?? "");
      return {
        ok: true,
        json: async () => ({
          candidates: [
            {
              content: {
                parts: [
                  {
                    text: JSON.stringify({
                      official_domain: "vestel.com.tr",
                      official_product_url: "https://www.vestel.com.tr/tv",
                      official_name: "Vestel TV",
                    }),
                  },
                ],
              },
            },
          ],
        }),
      };
    }) as unknown as typeof fetch;

    const riskliGirdi: GroundingAramaGirdisi & Record<string, unknown> = {
      urunAdi: "Akıllı Televizyon VKN 5555555555 Alış Fiyatı 1200 TL",
      marka: "Vestel",
      model: "55UA9600",
      tedarikci: "Tedarikçi A.Ş. VKN: 9876543210 toptan 850 TL",
      kilitliAlanAdi: "vestel.com.tr",
      alisFiyati: 1200,
      toptanFiyat: 850,
      vkn: "1234567890",
      vergi_no: "9998887776",
      unit_price: 1200,
      purchase_price: 1200,
      iskonto: 20,
    };

    await resmiUrunSayfasiGroundingIleBul(riskliGirdi, captureFetcher);

    // 1. Hassas alan anahtarları asla yer almaz
    expect(yakalananIstekGovdesi).not.toContain("alisFiyati");
    expect(yakalananIstekGovdesi).not.toContain("toptanFiyat");
    expect(yakalananIstekGovdesi).not.toContain("unit_price");
    expect(yakalananIstekGovdesi).not.toContain("purchase_price");
    expect(yakalananIstekGovdesi).not.toContain("vergi_no");
    expect(yakalananIstekGovdesi).not.toContain("iskonto");

    // 2. VKN/TCKN ve alış fiyatları metinlerden de maskelenmiştir
    expect(yakalananIstekGovdesi).not.toContain("1234567890");
    expect(yakalananIstekGovdesi).not.toContain("9876543210");
    expect(yakalananIstekGovdesi).not.toContain("5555555555");
    expect(yakalananIstekGovdesi).not.toContain("9998887776");
    expect(yakalananIstekGovdesi).not.toContain("1200 TL");
    expect(yakalananIstekGovdesi).not.toContain("850 TL");

    // 3. Resmi Google Grounding ve urlContext araçları resmi tools formatında iletilmiştir
    expect(yakalananIstekGovdesi).toContain(
      '"tools":[{"googleSearch":{"searchTypes":{"webSearch":{},"imageSearch":{}}}},{"urlContext":{}}]',
    );
  });

  // d) Telif kalkanı vitrin testi (tüketicide kalkan, esnafta tam görsel)
  it("telif kalkanı vitrin testi: genel vitrinde telif kalkanı, esnafta tam görsel açılır", () => {
    // 1. Tüketici vitrini (isOwner: false): Telif kalkanı ve 'Fotoğraf üreticide' rozeti görünür, <img> basılmaz
    const consumerMarkup = renderToStaticMarkup(
      createElement(CatalogProductImage, {
        src: "https://cdn.uretici.com/telifli-resim.jpg",
        alt: "Telifli Ürün",
        gorselIzinBekliyor: true,
        isOwner: false,
      }),
    );

    expect(consumerMarkup).toContain("Fotoğraf üreticide");
    expect(consumerMarkup).toContain("Telif onayı bekleniyor");
    expect(consumerMarkup).not.toContain("telifli-resim.jpg");
    expect(consumerMarkup).not.toContain("<img");

    // 2. Esnaf önizlemesi (isOwner: true): Telif kalkanı kalkar, görsel tam basılır
    const ownerMarkup = renderToStaticMarkup(
      createElement(CatalogProductImage, {
        src: "https://cdn.uretici.com/telifli-resim.jpg",
        alt: "Telifli Ürün",
        gorselIzinBekliyor: true,
        isOwner: true,
      }),
    );

    expect(ownerMarkup).not.toContain("Fotoğraf üreticide");
    expect(ownerMarkup).toContain("telifli-resim.jpg");

    // 3. Normal izinli ürün (gorselIzinBekliyor: false, isOwner: false): Tüketiciye doğrudan görsel açılır
    const regularMarkup = renderToStaticMarkup(
      createElement(CatalogProductImage, {
        src: "https://cdn.uretici.com/izinli-resim.jpg",
        alt: "İzinli Ürün",
        gorselIzinBekliyor: false,
        isOwner: false,
      }),
    );

    expect(regularMarkup).not.toContain("Fotoğraf üreticide");
    expect(regularMarkup).toContain("izinli-resim.jpg");
  });

  // e) Ağ/timeout hatasında çökmeden null dönme
  it("hata dayanıklılığı: ağ ve timeout hatalarında çökmeden null döner", async () => {
    const networkFailFetcher = vi.fn(async () => {
      throw new TypeError("Failed to fetch: network unreachable");
    }) as unknown as typeof fetch;

    const netResult = await resmiUrunSayfasiGroundingIleBul(
      { urunAdi: "Vestel Smart TV" },
      networkFailFetcher,
    );
    expect(netResult).toBeNull();

    const timeoutFetcher = vi.fn(async () => {
      const err = new Error("The operation was aborted due to timeout");
      err.name = "TimeoutError";
      throw err;
    }) as unknown as typeof fetch;

    const timeoutResult = await resmiUrunSayfasiGroundingIleBul(
      { urunAdi: "Vestel Smart TV" },
      timeoutFetcher,
    );
    expect(timeoutResult).toBeNull();

    const http500Fetcher = vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({ error: { message: "Internal Google API Error" } }),
    })) as unknown as typeof fetch;

    const http500Result = await resmiUrunSayfasiGroundingIleBul(
      { urunAdi: "Vestel Smart TV" },
      http500Fetcher,
    );
    expect(http500Result).toBeNull();
  });
});
