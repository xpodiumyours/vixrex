import { describe, expect, it } from "vitest";
import { googleFaturaUrunKartlariVeKullanimUret } from "../src/lib/faturaPriz";
import { gorselAdaylariniSuz, logoGorselUrliMi } from "../src/lib/faturaUrunHazirlama";

describe("fatura hiz, maliyet ve logo kilidi", () => {
  it("Gemini istegine varsayilan LOW thinkingConfig gonderir ve usageMetadata doner", async () => {
    const oncekiAnahtar = process.env.GEMINI_API_KEY;
    process.env.GEMINI_API_KEY = "test-gemini-key";
    let gonderilenGovde: Record<string, unknown> | null = null;
    try {
      const sahteFetch: typeof fetch = async (_input, init) => {
        gonderilenGovde = JSON.parse(String(init?.body ?? "{}")) as Record<string, unknown>;
        return new Response(
          JSON.stringify({
            usageMetadata: {
              promptTokenCount: 1200,
              candidatesTokenCount: 450,
              thoughtsTokenCount: 150,
              totalTokenCount: 1800,
            },
            candidates: [
              {
                groundingMetadata: { webSearchQueries: ["Tutku TER0126"] },
                content: {
                  parts: [
                    {
                      text: JSON.stringify({
                        items: [
                          {
                            row_id: "1",
                            title: "Tutku Erkek Thermal Fanila",
                            brand: "Tutku",
                            model: "TER0126",
                            barcode: null,
                            variant: null,
                            size: null,
                            quantity: 4,
                            unit: "AD",
                            unit_price: 120,
                            category: "Erkek İç Giyim",
                            short_description: "Termal fanila",
                            official_domain: "sehermensucat.com",
                            official_product_url: "https://sehermensucat.com/ter0126",
                            selected_image_url: "https://cdn.myikas.com/images/ter0126.webp",
                            image_urls: ["https://cdn.myikas.com/images/ter0126.webp"],
                          },
                        ],
                      }),
                    },
                  ],
                },
              },
            ],
          }),
          { status: 200, headers: { "content-type": "application/json" } },
        );
      };

      const { kartlar, kullanim } = await googleFaturaUrunKartlariVeKullanimUret(
        "data:image/png;base64,iVBORw0KGgo=",
        sahteFetch,
      );

      expect(kartlar).toHaveLength(1);
      const genCfg = (gonderilenGovde as unknown as Record<string, unknown> | null)?.generationConfig as Record<string, unknown>;
      expect(genCfg?.thinkingConfig).toEqual({ thinkingLevel: "LOW" });
      expect(kullanim.thinkingLevel).toBe("LOW");
      expect(kullanim.girdiToken).toBe(1200);
      expect(kullanim.ciktiToken).toBe(450);
      expect(kullanim.dusunmeToken).toBe(150);
      expect(kullanim.toplamToken).toBe(1800);
      expect(kullanim.aramaSorguSayisi).toBe(1);
    } finally {
      if (oncekiAnahtar === undefined) delete process.env.GEMINI_API_KEY;
      else process.env.GEMINI_API_KEY = oncekiAnahtar;
    }
  });

  it("URL adinda logo veya favicon gecen firma logosu adaylarini eler, gercek urun fotografini korur", () => {
    expect(logoGorselUrliMi("https://sehermensucat.com/assets/seher-logo.png")).toBe(true);
    expect(logoGorselUrliMi("https://cdn.myikas.com/images/header_logo.webp")).toBe(true);
    expect(logoGorselUrliMi("https://cdn.myikas.com/images/ter0126-front.webp")).toBe(false);

    const suzulen = gorselAdaylariniSuz({
      seciliGorsel: "https://sehermensucat.com/assets/seher-logo.png",
      adaylar: [
        "https://sehermensucat.com/favicon.ico",
        "https://cdn.myikas.com/images/ter0126-front.webp",
      ],
      tespitEdilenAlan: "sehermensucat.com",
    });

    expect(suzulen).toEqual(["https://cdn.myikas.com/images/ter0126-front.webp"]);
  });
});
