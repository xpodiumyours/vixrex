import { afterEach, describe, expect, it, vi } from "vitest";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import type { SupabaseClient } from "@supabase/supabase-js";

const mockIslemKaydet = vi.hoisted(() => vi.fn());

vi.mock("@/lib/faturaIslemKaydi", async (original) => ({
  ...(await original<typeof import("@/lib/faturaIslemKaydi")>()),
  islemKaydet: mockIslemKaydet,
}));

import { faturayiArkaPlanaGonder } from "@/lib/faturaArkaPlanIslemi";
import {
  VARSAYILAN_PRIZ_ADRESI,
  GOOGLE_FATURA_URUN_KARTI_SEMASI,
  faturaPrizAdresi,
  faturaPrizAnahtari,
  faturaOkumaPresetReferansi,
  faturaPrizZamanSiniri,
  faturaPrizBasliklari,
  geminiGovdesineCevir,
  geminiPrizAktifMi,
  googleFaturaUrunKartlariUret,
} from "@/lib/faturaPriz";

afterEach(() => {
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
  mockIslemKaydet.mockReset();
});

describe("fatura priz - tak-cikar", () => {
  it("varsayilan OpenRouter fişi calisir", () => {
    vi.stubEnv("OPENROUTER_API_KEY", "sk-or-vixrex-123");
    expect(VARSAYILAN_PRIZ_ADRESI).toBe("https://openrouter.ai/api/v1/chat/completions");
    expect(faturaPrizAdresi()).toBe("https://openrouter.ai/api/v1/chat/completions");
    expect(faturaPrizAnahtari()).toBe("sk-or-vixrex-123");
    expect(faturaOkumaPresetReferansi()).toBe("@preset/vixrex-qwen-fatura-okuma-suzme");
    expect(faturaPrizZamanSiniri()).toBe(240_000);
    expect(faturaPrizBasliklari("sk-or-vixrex-123")).toEqual({
      "Content-Type": "application/json",
      Authorization: "Bearer sk-or-vixrex-123",
      "HTTP-Referer": "https://vixrex.com",
      "X-Title": "Vixrex Fatura",
    });
  });

  it("FATURA_PRIZ_URL ve FATURA_PRIZ_API_KEY ile tak-cikar calisir", () => {
    vi.stubEnv("FATURA_PRIZ_URL", "https://ornek-saglayici.com/v1/chat/completions");
    vi.stubEnv("FATURA_PRIZ_API_KEY", "fk-abc-456");
    expect(faturaPrizAdresi()).toBe("https://ornek-saglayici.com/v1/chat/completions");
    expect(faturaPrizAnahtari()).toBe("fk-abc-456");
  });

  it("FATURA_PRIZ_API_KEY yoksa OPENROUTER_API_KEY fallback calisir", () => {
    vi.stubEnv("FATURA_PRIZ_URL", "https://baska.com/api");
    vi.stubEnv("OPENROUTER_API_KEY", "sk-fallback-789");
    expect(faturaPrizAdresi()).toBe("https://baska.com/api");
    expect(faturaPrizAnahtari()).toBe("sk-fallback-789");
  });

  it("OPENROUTER_BASE_URL verilirse priz adresi buradan uretilir", () => {
    vi.stubEnv("OPENROUTER_BASE_URL", "https://ozel-openrouter.example/api/v1/");
    expect(faturaPrizAdresi()).toBe("https://ozel-openrouter.example/api/v1/chat/completions");
    vi.stubEnv("OPENROUTER_BASE_URL", "https://ozel-openrouter.example/api/v1/chat/completions");
    expect(faturaPrizAdresi()).toBe("https://ozel-openrouter.example/api/v1/chat/completions");
  });

  it("zaman siniri 240 saniye varsayilanidir ve sinirlar dahilinde korunur", () => {
    vi.stubEnv("OPENROUTER_FATURA_TIMEOUT_MS", "600000");
    expect(faturaPrizZamanSiniri()).toBe(600_000);
    vi.stubEnv("OPENROUTER_FATURA_TIMEOUT_MS", "1000");
    expect(faturaPrizZamanSiniri()).toBe(240_000);
    vi.stubEnv("OPENROUTER_FATURA_TIMEOUT_MS", "999999999");
    expect(faturaPrizZamanSiniri()).toBe(240_000);
  });

  it("preset referansi on ek teklami degistirmez", () => {
    vi.stubEnv("OPENROUTER_PRESET", "@preset/ozel");
    expect(faturaOkumaPresetReferansi()).toBe("@preset/ozel");
    vi.stubEnv("OPENROUTER_PRESET", "");
    vi.stubEnv("OPENROUTER_FATURA_PRESET", "eski");
    expect(faturaOkumaPresetReferansi()).toBe("@preset/eski");
  });

  it("faturaGoru.ts kaynak kodunda sabit openrouter.ai URL'i kalmaz", () => {
    const source = readFileSync(
      fileURLToPath(new URL("../src/lib/faturaGoru.ts", import.meta.url)),
      "utf8",
    );
    expect(source).not.toContain("openrouter.ai/api/v1/chat/completions");
  });

  it("hem OPENROUTER_API_KEY hem GEMINI_API_KEY varken Google prizi birincildir ve anahtari baslikta tasir", () => {
    vi.stubEnv("OPENROUTER_API_KEY", "sk-or-real-openrouter-key");
    vi.stubEnv("GEMINI_API_KEY", "AIzaSyFakeGeminiKey123");

    expect(geminiPrizAktifMi()).toBe(true);
    expect(faturaPrizAdresi()).toBe(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent",
    );
    expect(faturaPrizAdresi()).not.toContain("key=");
    expect(faturaPrizAnahtari()).toBe("AIzaSyFakeGeminiKey123");
    expect(faturaPrizBasliklari(faturaPrizAnahtari())).toEqual({
      "Content-Type": "application/json",
      "x-goog-api-key": "AIzaSyFakeGeminiKey123",
    });
  });

  it("FATURA_PRIZ_URL acikca baska saglayiciya ayarlanirsa GEMINI_API_KEY varken bile OpenRouter veya ozel saglayici devreye girer", () => {
    vi.stubEnv("OPENROUTER_API_KEY", "sk-or-real-openrouter-key");
    vi.stubEnv("GEMINI_API_KEY", "AIzaSyFakeGeminiKey123");
    vi.stubEnv("FATURA_PRIZ_URL", VARSAYILAN_PRIZ_ADRESI);

    expect(geminiPrizAktifMi()).toBe(false);
    expect(faturaPrizAdresi()).toBe(VARSAYILAN_PRIZ_ADRESI);
    expect(faturaPrizAnahtari()).toBe("sk-or-real-openrouter-key");
    expect(faturaPrizBasliklari(faturaPrizAnahtari())).toEqual({
      "Content-Type": "application/json",
      Authorization: "Bearer sk-or-real-openrouter-key",
      "HTTP-Referer": "https://vixrex.com",
      "X-Title": "Vixrex Fatura",
    });
  });

  it("GEMINI_FATURA_MODEL ile model esnek secilir, bos degerde gemini-3.8-flash korunur", () => {
    vi.stubEnv("GOOGLE_API_KEY", "AIzaSyGoogleModelKey");
    vi.stubEnv("GEMINI_FATURA_MODEL", "gemini-2.5-pro");
    expect(faturaPrizAdresi()).toBe(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent",
    );

    vi.stubEnv("GEMINI_FATURA_MODEL", "   ");
    expect(faturaPrizAdresi()).toBe(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent",
    );
  });

  it("sadece GEMINI_API_KEY varken Gemini prizi devreye girer", () => {
    vi.stubEnv("OPENROUTER_API_KEY", "");
    vi.stubEnv("FATURA_PRIZ_API_KEY", "");
    vi.stubEnv("GEMINI_API_KEY", "AIzaSyGeminiOnlyKey");

    expect(faturaPrizAdresi()).toContain("generativelanguage.googleapis.com");
    expect(faturaPrizAdresi()).not.toContain("key=");
    expect(faturaPrizAnahtari()).toBe("AIzaSyGeminiOnlyKey");
    expect(faturaPrizBasliklari(faturaPrizAnahtari())).toEqual({
      "Content-Type": "application/json",
      "x-goog-api-key": "AIzaSyGeminiOnlyKey",
    });
  });

  it("FATURA_PRIZ_URL icinde yanlislikla ?key= verilse bile URL temizlenir", () => {
    vi.stubEnv("GEMINI_API_KEY", "AIzaSyGoogleKey");
    vi.stubEnv(
      "FATURA_PRIZ_URL",
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSySizdirilacakKey",
    );

    expect(faturaPrizAdresi()).toBe(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
    );
    expect(faturaPrizAdresi()).not.toContain("AIzaSySizdirilacakKey");
    expect(faturaPrizAnahtari()).toBe("AIzaSyGoogleKey");
  });

  it("geminiGovdesineCevir json_schema icin responseJsonSchema uretir", () => {
    const sema = {
      type: "object",
      properties: {
        faturaNo: { type: "string" },
        kalemler: { type: "array" },
      },
      required: ["faturaNo"],
    };
    const govde = {
      messages: [{ role: "user", content: "Faturayi oku" }],
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "fatura_semasi",
          schema: sema,
        },
      },
    };

    const geminiGovde = geminiGovdesineCevir(govde);
    expect(geminiGovde.generationConfig).toEqual({
      responseMimeType: "application/json",
      responseJsonSchema: sema,
    });
  });

  it("GOOGLE_FATURA_URUN_KARTI_SEMASI Kural 32 geregi 4 sutunlu ticari sir alanlarini icermez, unit_price alanini kar marji verisi olarak acar", () => {
    const itemProps = GOOGLE_FATURA_URUN_KARTI_SEMASI.properties.items.items.properties;
    const keys = Object.keys(itemProps);
    expect(keys).toEqual([
      "row_id",
      "title",
      "brand",
      "model",
      "barcode",
      "variant",
      "size",
      "quantity",
      "unit",
      "unit_price",
      "category",
      "short_description",
      "official_domain",
      "official_product_url",
      "selected_image_url",
      "image_urls",
    ]);
    expect(keys).toContain("unit_price");
    expect(keys).not.toContain("total_amount");
    expect(keys).not.toContain("vkn");
    expect(keys).not.toContain("tckn");
    expect(keys).not.toContain("iban");
    expect(keys).not.toContain("ettn");
    expect(keys).not.toContain("iskonto");
    expect(keys).not.toContain("fatura_no");
  });

  it("googleFaturaUrunKartlariUret inlineData/fileData ile tek adimda urun karti, unit_price ve grounding gorseli dondurur", async () => {
    vi.stubEnv("GEMINI_API_KEY", "AIzaSyDirectSocketKey");
    let yakalananUrl = "";
    let yakalananBasliklar: Record<string, string> = {};
    let yakalananGovde: Record<string, unknown> = {};

    const mockFetcher = vi.fn(async (url, init) => {
      yakalananUrl = String(url);
      yakalananBasliklar = (init?.headers ?? {}) as Record<string, string>;
      yakalananGovde = JSON.parse(String(init?.body ?? "{}"));
      return {
        ok: true,
        json: async () => ({
          candidates: [
            {
              content: {
                parts: [
                  { thought: true, text: "thinking..." },
                  {
                    text: JSON.stringify({
                      items: [
                        {
                          row_id: "1",
                          title: "Vestel 55UA9600 Smart TV VKN 1234567890",
                          brand: "Vestel",
                          model: "55UA9600",
                          barcode: "8698902700012",
                          variant: "55 inç",
                          size: null,
                          quantity: 2,
                          unit: "adet",
                          unit_price: 15000,
                          category: "Televizyon",
                          short_description: "4K UHD Smart LED TV 12345678901",
                          official_domain: "vestel.com.tr",
                          official_product_url: "https://www.vestel.com.tr/vestel-55ua9600",
                          image_urls: [
                            "https://cdn.dsmcdn.com/korsan.jpg",
                            "https://www.vestel.com.tr/media/55ua9600-front.jpg",
                          ],
                        },
                      ],
                    }),
                  },
                ],
              },
              groundingMetadata: {
                groundingChunks: [
                  { web: { uri: "https://www.trendyol.com/vestel/55ua9600" } },
                  { web: { uri: "https://www.vestel.com.tr/vestel-55ua9600" } },
                  { image: { uri: "https://www.vestel.com.tr/media/55ua9600-side.webp" } },
                ],
              },
            },
          ],
        }),
      };
    }) as unknown as typeof fetch;

    const kartlar = await googleFaturaUrunKartlariUret(
      ["data:image/png;base64,iVBORw0KGgo=", "https://cdn.example.com/fatura-2.jpg"],
      mockFetcher,
    );

    expect(yakalananUrl).toBe(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent",
    );
    expect(yakalananUrl).not.toContain("key=");
    expect(yakalananBasliklar["x-goog-api-key"]).toBe("AIzaSyDirectSocketKey");
    expect(yakalananGovde.tools).toEqual([
      { googleSearch: {} },
      { urlContext: {} },
    ]);
    expect(yakalananGovde.generationConfig).toEqual({
      temperature: 0.1,
      responseMimeType: "application/json",
      responseJsonSchema: GOOGLE_FATURA_URUN_KARTI_SEMASI,
    });
    const parts = ((yakalananGovde.contents as Array<{ parts: unknown[] }>)[0]?.parts ?? []) as Array<Record<string, unknown>>;
    expect(parts[0]).toEqual({
      text: expect.stringContaining("unit_price"),
    });
    expect((parts[0] as { text: string }).text).toContain("VKN/TCKN, IBAN");
    expect(parts[1]).toEqual({ inlineData: { mimeType: "image/png", data: "iVBORw0KGgo=" } });
    expect(parts[2]).toEqual({ fileData: { fileUri: "https://cdn.example.com/fatura-2.jpg" } });

    expect(kartlar).toHaveLength(1);
    expect(kartlar[0]).toEqual({
      row_id: "1",
      title: "Vestel 55UA9600 Smart TV VKN",
      brand: "Vestel",
      model: "55UA9600",
      barcode: "8698902700012",
      variant: "55 inç",
      size: null,
      quantity: 2,
      unit: "adet",
      unit_price: 15000,
      category: "Televizyon",
      short_description: "4K UHD Smart LED TV",
      official_domain: "vestel.com.tr",
      official_product_url: "https://www.vestel.com.tr/vestel-55ua9600",
      selected_image_url: "https://www.vestel.com.tr/media/55ua9600-front.jpg",
      image_urls: [
        "https://www.vestel.com.tr/media/55ua9600-front.jpg",
        "https://www.vestel.com.tr/media/55ua9600-side.webp",
      ],
      grounding_sources: ["https://www.vestel.com.tr/vestel-55ua9600"],
    });
  });

  it("googleFaturaUrunKartlariUret gecersiz veya negatif unit_price degerini null olarak dondurur", async () => {
    vi.stubEnv("GEMINI_API_KEY", "AIzaSyNegPriceKey");
    const negFetcher = vi.fn(async () => ({
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
                        title: "Negatif Fiyatlı Ürün",
                        brand: "Marka",
                        model: "M-1",
                        barcode: null,
                        variant: null,
                        size: null,
                        quantity: 2,
                        unit: "adet",
                        unit_price: -50,
                        category: null,
                        short_description: null,
                        official_domain: null,
                        official_product_url: null,
                        selected_image_url: null,
                        image_urls: [],
                      },
                      {
                        row_id: "2",
                        title: "Metin Fiyatlı Ürün",
                        brand: "Marka",
                        model: "M-2",
                        barcode: null,
                        variant: null,
                        size: null,
                        quantity: 1,
                        unit: "adet",
                        unit_price: "250",
                        category: null,
                        short_description: null,
                        official_domain: null,
                        official_product_url: null,
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
    })) as unknown as typeof fetch;

    const kartlar = await googleFaturaUrunKartlariUret("data:image/png;base64,AA==", negFetcher);
    expect(kartlar).toHaveLength(2);
    expect(kartlar[0].unit_price).toBeNull();
    expect(kartlar[1].unit_price).toBeNull();
  });

  it("googleFaturaUrunKartlariUret official_product_url varken gorsel eksikse bile HTML kaziyici ek fetch atmaz", async () => {
    vi.stubEnv("GEMINI_API_KEY", "AIzaSyNoScrapeKey");
    const singleFetch = vi.fn(async () => ({
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
                        title: "Resmi Sayfali Gorselsiz Urun",
                        brand: "Vestel",
                        model: "V-10",
                        barcode: null,
                        variant: null,
                        size: null,
                        quantity: 1,
                        unit: "adet",
                        unit_price: 500,
                        category: "Elektronik",
                        short_description: "Aciklama",
                        official_domain: "vestel.com.tr",
                        official_product_url: "https://www.vestel.com.tr/v-10",
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
    })) as unknown as typeof fetch;

    const kartlar = await googleFaturaUrunKartlariUret("data:image/png;base64,AA==", singleFetch);
    expect(singleFetch).toHaveBeenCalledTimes(1);
    expect(kartlar).toHaveLength(1);
    expect(kartlar[0].official_product_url).toBe("https://www.vestel.com.tr/v-10");
    expect(kartlar[0].image_urls).toEqual([]);
  });

  it("googleFaturaUrunKartlariUret bos girdi, eksik anahtar ve hata durumlarinda dogru davranir", async () => {
    const spyFetcher = vi.fn() as unknown as typeof fetch;
    expect(await googleFaturaUrunKartlariUret([], spyFetcher)).toEqual([]);
    expect(await googleFaturaUrunKartlariUret("   ", spyFetcher)).toEqual([]);
    expect(spyFetcher).not.toHaveBeenCalled();

    vi.stubEnv("GEMINI_API_KEY", "");
    vi.stubEnv("GOOGLE_API_KEY", "");
    await expect(googleFaturaUrunKartlariUret("data:image/png;base64,AA==")).rejects.toThrow("OKUYUCU_HAZIR_DEGIL");

    vi.stubEnv("GEMINI_API_KEY", "AIzaSyErrKey");
    const timeoutFetcher = vi.fn(async () => {
      const err = new Error("timeout");
      err.name = "TimeoutError";
      throw err;
    }) as unknown as typeof fetch;
    await expect(
      googleFaturaUrunKartlariUret("data:image/png;base64,AA==", timeoutFetcher),
    ).rejects.toThrow("OKUYUCU_ZAMAN_ASIMI");

    const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});
    const http500Fetcher = vi.fn(async () => ({
      ok: false,
      status: 500,
      text: async () => "Backend error at https://generativelanguage.googleapis.com?key=AIzaSyErrKey",
    })) as unknown as typeof fetch;
    await expect(
      googleFaturaUrunKartlariUret("data:image/png;base64,AA==", http500Fetcher),
    ).rejects.toThrow("OKUYUCU_CEVAP_VERMEDI");
    expect(warnSpy).toHaveBeenCalledWith(
      "[faturaPriz] Gemini yanıt hatası:",
      expect.objectContaining({ status: 500 }),
    );
    expect(JSON.stringify(warnSpy.mock.calls)).not.toContain("AIzaSyErrKey");
    warnSpy.mockRestore();

    const badJsonFetcher = vi.fn(async () => ({
      ok: true,
      json: async () => ({ candidates: [{ content: { parts: [{ text: "not-json" }] } }] }),
    })) as unknown as typeof fetch;
    expect(
      await googleFaturaUrunKartlariUret("data:image/png;base64,AA==", badJsonFetcher),
    ).toEqual([]);
  });

  it("faturayiArkaPlanaGonder geminiPrizAktifMi true iken googleFaturaUrunKartlariUret uzerinden islemKaydet cagirir", async () => {
    vi.stubEnv("OPENROUTER_API_KEY", "");
    vi.stubEnv("FATURA_PRIZ_API_KEY", "");
    vi.stubEnv("GEMINI_API_KEY", "AIzaSyGeminiDirectFlow");

    const fetchMock = vi.fn(async () => ({
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
                        title: "Bosch TWK7203 Su Isıtıcı",
                        brand: "Bosch",
                        model: "TWK7203",
                        barcode: "4242002975658",
                        variant: "Inox",
                        size: "1.7 L",
                        quantity: 3,
                        unit: "adet",
                        unit_price: 420.5,
                        category: "Küçük Ev Aletleri",
                        short_description: "Paslanmaz çelik su ısıtıcı",
                        official_domain: "bosch-home.com.tr",
                        official_product_url: "https://www.bosch-home.com.tr/urun/TWK7203",
                        image_urls: ["https://www.bosch-home.com.tr/media/twk7203.jpg"],
                      },
                    ],
                  }),
                },
              ],
            },
            groundingMetadata: {
              groundingChunks: [
                { web: { uri: "https://www.bosch-home.com.tr/urun/TWK7203" } },
              ],
            },
          },
        ],
      }),
    }));
    vi.stubGlobal("fetch", fetchMock);
    mockIslemKaydet.mockResolvedValue("islem-gemini-1");

    const rpcSpy = vi.fn();
    const admin = {
      from: (table: string) => ({
        select: () => ({
          eq: () => ({
            maybeSingle: async () => ({
              data: table === "stores" ? { slug: "ornek-esnaf" } : null,
              error: null,
            }),
          }),
        }),
      }),
      rpc: rpcSpy,
    } as unknown as SupabaseClient;

    const sonucId = await faturayiArkaPlanaGonder(
      admin,
      "store-1",
      "parmak-izi-1",
      ["data:image/png;base64,iVBORw0KGgo="],
    );

    expect(sonucId).toBe("islem-gemini-1");
    expect(rpcSpy).not.toHaveBeenCalled();
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(mockIslemKaydet).toHaveBeenCalledTimes(1);
    const kayitGirdisi = mockIslemKaydet.mock.calls[0][0];
    expect(kayitGirdisi.slug).toBe("ornek-esnaf");
    expect(kayitGirdisi.parmakIzi).toBe("parmak-izi-1");
    expect(kayitGirdisi.belgeAdedi).toBe(1);
    expect(kayitGirdisi.satirlar).toHaveLength(1);
    expect(kayitGirdisi.satirlar[0]).toMatchObject({
      ad: "Bosch TWK7203 Su Isıtıcı",
      marka: "Bosch",
      model: "TWK7203",
      barkod: "4242002975658",
      alisBirimFiyat: 420.5,
      satirToplam: 1261.5,
      sonuc: "kanitli",
      siteSayfa: "https://www.bosch-home.com.tr/urun/TWK7203",
      siteGorseller: ["https://www.bosch-home.com.tr/media/twk7203.jpg"],
    });

    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok: true,
        json: async () => ({
          candidates: [{ content: { parts: [{ text: JSON.stringify({ items: [] }) }] } }],
        }),
      })),
    );
    await expect(
      faturayiArkaPlanaGonder(admin, "store-1", "parmak-izi-2", ["data:image/png;base64,AA=="]),
    ).rejects.toThrow("FOTOGRAFTA_YAZI_YOK");
  });

  it("googleFaturaUrunKartlariUret fileSearch store adlarini opsiyonlar ve env uzerinden tools dizisine ekler", async () => {
    vi.stubEnv("GEMINI_API_KEY", "AIzaSyFileSearchKey");
    const yakalananAraclar: unknown[] = [];
    const fetcher = vi.fn(async (_url, init) => {
      const govde = JSON.parse(String(init?.body ?? "{}")) as { tools?: unknown[] };
      yakalananAraclar.push(govde.tools);
      return {
        ok: true,
        json: async () => ({
          candidates: [{ content: { parts: [{ text: JSON.stringify({ items: [] }) }] } }],
        }),
      };
    }) as unknown as typeof fetch;

    await googleFaturaUrunKartlariUret("data:image/png;base64,AA==", fetcher, {
      fileSearchStoreNames: ["fileSearchStores/katalog-1", "fileSearchStores/katalog-2"],
    });
    expect(yakalananAraclar[0]).toEqual([
      { googleSearch: {} },
      { urlContext: {} },
      { fileSearch: { fileSearchStoreNames: ["fileSearchStores/katalog-1", "fileSearchStores/katalog-2"] } },
    ]);

    vi.stubEnv("GEMINI_FILE_SEARCH_STORE_NAMES", "fileSearchStores/env-1, , fileSearchStores/env-2");
    await googleFaturaUrunKartlariUret("data:image/png;base64,AA==", fetcher);
    expect(yakalananAraclar[1]).toEqual([
      { googleSearch: {} },
      { urlContext: {} },
      { fileSearch: { fileSearchStoreNames: ["fileSearchStores/env-1", "fileSearchStores/env-2"] } },
    ]);

    vi.stubEnv("GEMINI_FILE_SEARCH_STORE_NAMES", "   ");
    await googleFaturaUrunKartlariUret("data:image/png;base64,AA==", fetcher);
    expect(yakalananAraclar[2]).toEqual([
      { googleSearch: {} },
      { urlContext: {} },
    ]);
  });

  it("hata durumunda firlatilan hatanin cause icerigi API anahtarini maskeler", async () => {
    vi.stubEnv("GEMINI_API_KEY", "AIzaSyGizliKey999999");
    const leakFetcher = vi.fn(async () => {
      throw new Error("fetch failed for https://generativelanguage.googleapis.com?key=AIzaSyGizliKey999999");
    }) as unknown as typeof fetch;

    let yakalananHata: Error | null = null;
    try {
      await googleFaturaUrunKartlariUret("data:image/png;base64,AA==", leakFetcher);
    } catch (err) {
      yakalananHata = err as Error;
    }
    expect(yakalananHata?.message).toBe("OKUYUCU_CEVAP_VERMEDI");
    expect(String(yakalananHata?.cause ?? "")).not.toContain("AIzaSyGizliKey999999");
  });
});