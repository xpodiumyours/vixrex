import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { DogrulanmisSatir } from "@/lib/faturaUrunBaglantisi";
import type { HazirUrunGirdisi } from "@/lib/productIntake";
import {
  aciklamayaFaturaRengiEkle,
  faturaRenginiCoz,
  groundingIstemiOlustur,
  kayitliFaturaKatalogunuUygula,
  mesruEticaretCdnMi,
  resmiAlanAdiUygunMu,
  resmiUrunSayfasiGroundingIleBul,
} from "@/lib/faturaUrunHazirlama";
import { googleFaturaUrunKartlariUret } from "@/lib/faturaPriz";
import { kartYanitiniCoz, tekKartSozlesmesi } from "@/lib/faturaKartSozlesmesi";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";
import { kartPresetYanitiniOku } from "@/lib/faturaKartPreset";
import type { GoruSonucu } from "@/lib/faturaGoru";

describe("VixRex Türkiye Üretici Gerçekliği & Boş Kart Yok Sözleşmesi", () => {
  const originalGeminiKey = process.env.GEMINI_API_KEY;

  beforeEach(() => {
    process.env.GEMINI_API_KEY = "test-gemini-key";
  });

  afterEach(() => {
    process.env.GEMINI_API_KEY = originalGeminiKey;
    vi.unstubAllEnvs();
  });

  it("kurumsal e-ticaret CDN görsellerini kabul eder, pazaryeri ve sahte sayfa CDN'ini reddeder", () => {
    expect(mesruEticaretCdnMi("https://img-mavi.akinoncdn.com/products/jean.jpg")).toBe(true);
    expect(resmiAlanAdiUygunMu("https://img-mavi.akinoncdn.com/products/jean.jpg", "mavi.com")).toBe(true);
    expect(resmiAlanAdiUygunMu("https://cdn.mncdn.com/koton/gomlek.webp", "koton.com", { gorsel: true })).toBe(true);
    expect(resmiAlanAdiUygunMu("https://static.ticimax.cloud/550/uploads/elbise.jpg", "seher.com.tr", { gorsel: true })).toBe(true);
    expect(resmiAlanAdiUygunMu("https://cdn.ideacdn.net/idea/ab/pantolon.jpg", "marka.com.tr", { gorsel: true })).toBe(true);
    expect(resmiAlanAdiUygunMu("https://cdn.shopify.com/s/files/1/tisort.jpg", "marka.com", { gorsel: true })).toBe(true);

    expect(resmiAlanAdiUygunMu("https://cdn.dsmcdn.com/mnresize/urun.jpg", "mavi.com", { gorsel: true })).toBe(false);
    expect(resmiAlanAdiUygunMu("https://media-amazon.com/images/I/urun.jpg", "mavi.com", { gorsel: true })).toBe(false);
    expect(resmiAlanAdiUygunMu("https://img-mavi.akinoncdn.com/products/jean.jpg", "mavi.com", { gorsel: false })).toBe(false);
    expect(resmiAlanAdiUygunMu("https://www.beko.com.tr/urun", "vestel.com.tr", { gorsel: false })).toBe(false);
    expect(resmiAlanAdiUygunMu("javascript:alert(1)", "mavi.com", { gorsel: true })).toBe(false);
    expect(resmiAlanAdiUygunMu("https://user:pass@akinoncdn.com/a.jpg", "mavi.com", { gorsel: true })).toBe(false);
    expect(resmiAlanAdiUygunMu("https://127.0.0.1/a.jpg", "mavi.com", { gorsel: true })).toBe(false);
  });

  it("sayfaGorselAlanAdlari ile bilinmeyen kurumsal CDN alan adini kurtarir, pazaryerini kurtarmaz", async () => {
    const fetcher = vi.fn(async (url: string) => {
      if (url.includes("generativelanguage.googleapis.com")) {
        return {
          ok: true,
          json: async () => ({
            candidates: [
              {
                content: {
                  parts: [
                    {
                      text: JSON.stringify({
                        official_domain: "mavi.com",
                        official_product_url: "https://www.mavi.com/jake-slim-fit-jean",
                        official_name: "Jake Slim Fit Jean Pantolon",
                        brand: "Mavi",
                        description: "Esnek denim pantolon",
                        category: "Pantolon",
                        selected_image_url: "https://media.ozel-marka-cdn.net/mavi/jake-main.jpg",
                        image_urls: [
                          "https://media.ozel-marka-cdn.net/mavi/jake-main.jpg",
                          "https://media.ozel-marka-cdn.net/mavi/jake-side.jpg",
                          "https://cdn.dsmcdn.com/korsan.jpg",
                        ],
                      }),
                    },
                  ],
                },
              },
            ],
          }),
        };
      }
      return new Response(
        '<html><head><meta property="og:image" content="https://media.ozel-marka-cdn.net/mavi/jake-main.jpg"/><meta name="twitter:image" content="https://cdn.dsmcdn.com/korsan-og.jpg"/></head></html>',
        { status: 200, headers: { "content-type": "text/html" } },
      );
    }) as unknown as typeof fetch;

    const sonuc = await resmiUrunSayfasiGroundingIleBul(
      { urunAdi: "MAVI SLM DNM PNT SYH M", marka: "Mavi", model: "004222", varyant: "SYH" },
      fetcher,
    );

    expect(sonuc).not.toBeNull();
    expect(sonuc?.resmiSayfa).toBe("https://www.mavi.com/jake-slim-fit-jean");
    expect(sonuc?.selectedImageUrl).toBe("https://media.ozel-marka-cdn.net/mavi/jake-main.jpg");
    expect(sonuc?.gorseller).toEqual([
      "https://media.ozel-marka-cdn.net/mavi/jake-main.jpg",
      "https://media.ozel-marka-cdn.net/mavi/jake-side.jpg",
    ]);
    expect(sonuc?.aciklama).toContain("Siyah");
  });

  it("Türkiye fatura kısaltmalarını ve renklerini doğru çözer, beden ve ölçüleri renk sanmaz", () => {
    const istem = groundingIstemiOlustur(
      { urunAdi: "MAVI SLM GMLK LCV", marka: "Mavi", model: "02100", varyant: "LCV", beden: "L" },
      "mavi.com",
    );
    expect(istem).toContain("SLM=Slim Fit");
    expect(istem).toContain("REG=Regular Fit");
    expect(istem).toContain("SYH=Siyah");
    expect(istem).toContain("LCV=Lacivert");
    expect(istem).toContain("PNT=Pantolon");
    expect(istem).toContain("GMLK=Gömlek");
    expect(istem).toContain("DNM=Denim");
    expect(istem).toContain("selected_image_url");

    expect(faturaRenginiCoz("SYH")).toBe("Siyah");
    expect(faturaRenginiCoz("750 LCV")).toBe("Lacivert");
    expect(faturaRenginiCoz("Y.Haki")).toBe("Haki");
    expect(faturaRenginiCoz("", "MAVİ SLM PNT BYZ 32/32")).toBe("Beyaz");

    expect(faturaRenginiCoz("XL")).toBe("");
    expect(faturaRenginiCoz("42")).toBe("");
    expect(faturaRenginiCoz("55 inç")).toBe("");
    expect(faturaRenginiCoz("175 g")).toBe("");

    expect(aciklamayaFaturaRengiEkle("Slim fit denim pantolon", "Lacivert")).toBe(
      "Slim fit denim pantolon · Renk: Lacivert",
    );
    expect(aciklamayaFaturaRengiEkle("Lacivert slim fit denim pantolon", "Lacivert")).toBe(
      "Lacivert slim fit denim pantolon",
    );
  });

  it("Saf platform prizi: doğrulanmış ürün sayfasında grounding görseli ek HTML kazıma yapmadan karta taşınır", async () => {
    const fetcher = vi.fn(async (url: string, init?: RequestInit) => {
      expect(url).toContain("generativelanguage.googleapis.com");
      const body = String(init?.body ?? "");
      expect(body).toContain("SLM=Slim Fit");
      expect(body).not.toContain("1234567890");
      return {
        ok: true,
        json: async () => ({
          candidates: [
            {
              content: {
                parts: [
                  {
                    text: JSON.stringify({
                      items: [
                        {
                          row_id: "1",
                          title: "Mavi Jake Slim Fit Siyah Jean Pantolon",
                          brand: "Mavi",
                          model: "0042228479",
                          barcode: "8684245011223",
                          variant: "SYH",
                          size: "32/32",
                          quantity: 4,
                          unit: "adet",
                          unit_price: 450,
                          category: "Pantolon",
                          short_description: "Dar kesim siyah denim pantolon",
                          official_domain: "mavi.com",
                          official_product_url: "https://www.mavi.com/jake-siyah-jean-p-004222",
                          selected_image_url: null,
                          image_urls: [],
                        },
                      ],
                    }),
                  },
                ],
              },
              groundingMetadata: {
                groundingChunks: [
                  { image: { imageUri: "https://img-mavi.akinoncdn.com/products/2025/02/jake-siyah-manken.jpg" } },
                ],
              },
            },
          ],
        }),
      };
    }) as unknown as typeof fetch;

    const kartlar = await googleFaturaUrunKartlariUret("data:image/png;base64,iVBORw0KGgo=", fetcher);
    expect(fetcher).toHaveBeenCalledTimes(1);
    expect(kartlar).toHaveLength(1);
    expect(kartlar[0].official_product_url).toBe("https://www.mavi.com/jake-siyah-jean-p-004222");
    expect(kartlar[0].selected_image_url).toBe("https://img-mavi.akinoncdn.com/products/2025/02/jake-siyah-manken.jpg");
    expect(kartlar[0].image_urls).toEqual(["https://img-mavi.akinoncdn.com/products/2025/02/jake-siyah-manken.jpg"]);
    expect(kartlar[0].short_description?.toLocaleLowerCase("tr-TR")).toContain("siyah");
  });

  it("Boş Kart Yok negatif uç durum: yalnızca pazaryeri og:image varsa karta sızmaz", async () => {
    const fetcher = vi.fn(async (url: string) => {
      if (url.includes("generativelanguage.googleapis.com")) {
        return {
          ok: true,
          json: async () => ({
            candidates: [
              {
                content: {
                  parts: [
                    {
                      text: JSON.stringify({
                        items: [
                          {
                            row_id: "1",
                            title: "Mavi Gömlek",
                            brand: "Mavi",
                            model: "02100",
                            barcode: null,
                            variant: "LCV",
                            size: "M",
                            quantity: 1,
                            unit: "adet",
                            category: "Gömlek",
                            short_description: "Klasik yaka",
                            official_domain: "mavi.com",
                            official_product_url: "https://www.mavi.com/gomlek",
                            selected_image_url: null,
                            image_urls: [],
                          },
                        ],
                      }),
                    },
                  ],
                },
              },
            ],
          }),
        };
      }
      return new Response(
        '<html><head><meta property="og:image" content="https://cdn.dsmcdn.com/sahte.jpg"/></head></html>',
        { status: 200, headers: { "content-type": "text/html" } },
      );
    }) as unknown as typeof fetch;

    const kartlar = await googleFaturaUrunKartlariUret("data:image/png;base64,iVBORw0KGgo=", fetcher);
    expect(kartlar).toHaveLength(1);
    expect(kartlar[0].selected_image_url).toBeNull();
    expect(kartlar[0].image_urls).toEqual([]);
  });

  it("faturaKartSozlesmesi, faturaKartPreset ve faturaPresetAktarimi selected_image_url, gorselAdaylari ve katalog.faturaRengi tasir", async () => {
    vi.stubEnv("PRESET_AKIS", "yeni");

    const sozlesme = tekKartSozlesmesi({
      row_id: "1",
      title: "Mavi Slim Fit Gömlek",
      brand: "Mavi",
      validation: {
        status: "verified",
        official_domain: "mavi.com",
        official_product_url: "https://www.mavi.com/slim-gomlek",
      },
      media: {
        selected_image_url: "https://img-mavi.akinoncdn.com/products/manken-ana.jpg",
        image_url: "https://img-mavi.akinoncdn.com/products/detay.jpg",
        image_urls: [
          "https://img-mavi.akinoncdn.com/products/detay.jpg",
          "https://img-mavi.akinoncdn.com/products/arka-aci.jpg",
        ],
        source_url: "https://www.mavi.com/slim-gomlek",
      },
      sources: [{ url: "https://www.mavi.com/slim-gomlek" }],
    });

    expect(sozlesme.seciliGorsel).toBe("https://img-mavi.akinoncdn.com/products/manken-ana.jpg");
    expect(sozlesme.gorselAdresi).toBe("https://img-mavi.akinoncdn.com/products/manken-ana.jpg");
    expect(sozlesme.gorselAdaylari).toEqual([
      "https://img-mavi.akinoncdn.com/products/manken-ana.jpg",
      "https://img-mavi.akinoncdn.com/products/detay.jpg",
      "https://img-mavi.akinoncdn.com/products/arka-aci.jpg",
    ]);

    const guvensiz = tekKartSozlesmesi({
      row_id: "2",
      title: "Hatalı Görsel Testi",
      media: {
        selected_image_url: "javascript:alert(1)",
        image_urls: ["https://img-mavi.akinoncdn.com/products/temiz.jpg"],
      },
    });
    expect(guvensiz.seciliGorsel).toBe("https://img-mavi.akinoncdn.com/products/temiz.jpg");
    expect(guvensiz.gorselAdaylari).toEqual(["https://img-mavi.akinoncdn.com/products/temiz.jpg"]);

    const okuma = {
      tedarikci: "Mavi Giyim",
      satirlar: [
        {
          hamSatir: "MAVI SLM GMLK LCV L",
          model: "02100",
          ad: "MAVI SLM GMLK LCV",
          barkod: "",
          varyant: "LCV",
          beden: "L",
          marka: "Mavi",
          adet: 2,
          birim: "adet",
          birimFiyat: 500,
          tutar: 1000,
          okumaGuveni: 0.95,
        },
      ],
    } as unknown as GoruSonucu;

    const response = new Response(
      JSON.stringify({
        choices: [
          {
            finish_reason: "stop",
            message: {
              content: JSON.stringify({
                items: [
                  {
                    row_id: "1",
                    vixrex_product_json: {
                      title: "Mavi Slim Fit Erkek Gömlek",
                      brand: "Mavi",
                      category_suggestion: "Gömlek",
                      variant: "LCV",
                      short_description: "Pamuklu slim fit gömlek",
                    },
                    validation: {
                      status: "verified",
                      official_domain: "mavi.com",
                      official_product_url: "https://www.mavi.com/slim-gomlek",
                      matched_attributes: ["model"],
                      unmatched_attributes: [],
                    },
                    media: {
                      selected_image_url: "https://img-mavi.akinoncdn.com/products/manken-ana.jpg",
                      image_url: "https://img-mavi.akinoncdn.com/products/manken-ana.jpg",
                      image_urls: [
                        "https://img-mavi.akinoncdn.com/products/manken-ana.jpg",
                        "https://img-mavi.akinoncdn.com/products/arka-aci.jpg",
                      ],
                      source_url: "https://www.mavi.com/slim-gomlek",
                      verification_status: "verified",
                    },
                    sources: [
                      {
                        url: "https://www.mavi.com/slim-gomlek",
                        fetched_at: "2026-11-18T12:00:00Z",
                        snippet: "Mavi Slim Fit Gömlek",
                      },
                    ],
                  },
                ],
              }),
            },
          },
        ],
      }),
      { status: 200, headers: { "content-type": "application/json" } },
    );

    const okunan = await kartPresetYanitiniOku(response, okuma, "yeni");
    const aktarilan = faturaSatiriniAktar(okunan.sonuc.satirlar[0], "Mavi Giyim");

    expect(aktarilan.siteGorsel).toBe("https://img-mavi.akinoncdn.com/products/manken-ana.jpg");
    expect(aktarilan.siteGorseller).toEqual([
      "https://img-mavi.akinoncdn.com/products/manken-ana.jpg",
      "https://img-mavi.akinoncdn.com/products/arka-aci.jpg",
    ]);
    expect(aktarilan.katalog?.faturaRengi).toBe("Lacivert");
    expect(aktarilan.katalog?.aciklama).toContain("Renk: Lacivert");
    expect(aktarilan.katalog?.gorselAdaylari).toEqual([
      "https://img-mavi.akinoncdn.com/products/manken-ana.jpg",
      "https://img-mavi.akinoncdn.com/products/arka-aci.jpg",
    ]);

    const cozulen = await kartYanitiniCoz(
      JSON.stringify({
        items: [
          {
            row_id: "1",
            vixrex_product_json: { title: "Mavi Slim Fit Gömlek" },
            media: {
              selected_image_url: "https://img-mavi.akinoncdn.com/products/manken-ana.jpg",
              image_urls: ["https://img-mavi.akinoncdn.com/products/manken-ana.jpg"],
            },
          },
        ],
      }),
    );
    expect(cozulen.kartlar[0].seciliGorsel).toBe("https://img-mavi.akinoncdn.com/products/manken-ana.jpg");
  });

  it("kayitliFaturaKatalogunuUygula gorselHakDurumlari denied olan gorseli izinli listeye eklemez, izinli CDN gorsellerini tasir", async () => {
    const ana = "https://img-mavi.akinoncdn.com/products/ana.jpg";
    const reddedilen = "https://img-mavi.akinoncdn.com/products/yasak.jpg";

    const girdi: HazirUrunGirdisi = {
      name: "MAVI SLM GMLK SYH",
      description: "",
      priceText: "",
      priceAmount: null,
      categoryId: "",
      stockStatus: "Stokta",
      stockQuantity: 1,
      brand: "Mavi",
      barcode: null,
      variants: [],
      imageUrls: [],
      metadata: { attributes: [] },
    };

    const satir: DogrulanmisSatir = {
      satirId: "satir-cdn-1",
      sonuc: "kanitli",
      urunId: null,
      izinliGorseller: new Set<string>(),
      gorselHakDurumlari: new Map([[reddedilen, "denied"]]),
      katalog: {
        resmiAd: "Mavi Slim Fit Gömlek",
        marka: "Mavi",
        aciklama: "Klasik kesim",
        kaynak: "https://www.mavi.com/slim-gomlek",
        selected_image_url: ana,
        gorseller: [ana, reddedilen],
        gorselAdaylari: [ana, reddedilen],
      },
      alisBirimFiyati: null,
      varyant: "SYH",
      beden: "M",
      urunAdi: "MAVI SLM GMLK SYH",
      marka: "Mavi",
      resmiAlanAdi: "mavi.com",
    };

    const hata = await kayitliFaturaKatalogunuUygula({
      admin: {} as SupabaseClient,
      storeId: "store-1",
      editToken: "token-1",
      girdi,
      satir,
      kategoriOnbellegi: new Map(),
    });

    expect(hata).toBeNull();
    expect(girdi.description).toBe("Klasik kesim · Renk: Siyah");
    expect(satir.katalog?.faturaRengi).toBe("Siyah");
    expect(satir.izinliGorseller.has(ana)).toBe(true);
    expect(satir.izinliGorseller.has(reddedilen)).toBe(false);
    expect(girdi.imageUrls[0]).toBe(ana);
  });

  it("resmi Gemini API GroundingChunk.image.imageUri ve urlContextMetadata.urlMetadata alanlarını doğru çözer", async () => {
    const fetcher = vi.fn(async () => ({
      ok: true,
      json: async () => ({
        candidates: [
          {
            content: {
              parts: [
                {
                  text: JSON.stringify({
                    official_domain: "mavi.com",
                    official_product_url: null,
                    official_name: "Mavi Denim Ceket",
                    brand: "Mavi",
                    image_urls: [],
                  }),
                },
              ],
            },
            groundingMetadata: {
              groundingChunks: [
                {
                  image: {
                    imageUri: "https://img-mavi.akinoncdn.com/products/ceket-ana.jpg",
                    sourceUri: "https://www.mavi.com/denim-ceket",
                  },
                },
              ],
            },
            urlContextMetadata: {
              urlMetadata: [
                {
                  retrievedUrl: "https://www.mavi.com/basarisiz-sayfa",
                  urlRetrievalStatus: "URL_RETRIEVAL_STATUS_ERROR",
                },
                {
                  retrievedUrl: "https://www.mavi.com/denim-ceket",
                  urlRetrievalStatus: "URL_RETRIEVAL_STATUS_SUCCESS",
                },
              ],
            },
          },
        ],
      }),
    })) as unknown as typeof fetch;

    const sonuc = await resmiUrunSayfasiGroundingIleBul(
      { urunAdi: "MAVI DNM CKT", marka: "Mavi" },
      fetcher,
    );

    expect(sonuc).not.toBeNull();
    expect(sonuc?.resmiSayfa).toBe("https://www.mavi.com/denim-ceket");
    expect(sonuc?.selectedImageUrl).toBe("https://img-mavi.akinoncdn.com/products/ceket-ana.jpg");
    expect(sonuc?.gorseller).toEqual(["https://img-mavi.akinoncdn.com/products/ceket-ana.jpg"]);
    expect(sonuc?.groundingKaynaklari).toEqual(["https://www.mavi.com/denim-ceket"]);
  });

  it("groundingIstemiOlustur genel kisaltma acma kuralini, ters yonlu kod kirmayi, marka/link-gorsel ayrimini ve GEMINI_FATURA_EK_TALIMAT destegini tasir", () => {
    vi.stubEnv("GEMINI_FATURA_EK_TALIMAT", "  Sadece üreticinin güncel sezon görsellerini tercih et.  ");
    const istem = groundingIstemiOlustur(
      { urunAdi: "167-1-3XL BYN RB G.ASK ATL K.GRİ", model: "167-1-3XL", varyant: "K.GRİ", beden: "3XL" },
      null,
    );

    expect(istem).toContain("Hangi sektör olursa olsun faturadaki kısaltmaları, renk/beden/ölçü kodlarını ve sektörel terimleri faturanın bağlamından otomatik çözümleyip tam tüketici diline aç.");
    expect(istem).not.toContain("RB/RİB");
    expect(istem).not.toContain("BYN/BYL");
    expect(istem).not.toContain("G.ASK=");
    expect(istem).toContain("167-1-3XL, 049-19-3XL, 328-1-4");
    expect(istem).toContain("baştaki kök model numarası ve açılmış ürün adıyla da arama yap");
    expect(istem).toContain("official_domain, official_product_url, selected_image_url ve image_urls alanları için pazaryeri/aracı siteleri");
    expect(istem).toContain("ürünün hangi markaya ait olduğunu (brand) tespit ederken");
    expect(istem).toContain("Sadece üreticinin güncel sezon görsellerini tercih et.");

    vi.stubEnv("GEMINI_FATURA_EK_TALIMAT", "   ");
    const eksizIstem = groundingIstemiOlustur(
      { urunAdi: "167-1-3XL BYN RB G.ASK ATL", model: "167-1-3XL" },
      null,
    );
    expect(eksizIstem).not.toContain("Sadece üreticinin güncel sezon görsellerini tercih et.");
  });
});
