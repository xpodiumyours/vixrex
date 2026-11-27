import { describe, expect, it } from "vitest";
import sharp from "sharp";
import { googleFaturaUrunKartlariVeKullanimUret } from "../src/lib/faturaPriz";
import { kaynakGorseliniDogrula } from "../src/lib/faturaGorsel";

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

  it("URL adinda logo gecen gorseli indirip yuklemeden eler", async () => {
    const sonuc = await kaynakGorseliniDogrula("https://cdn.example.com/assets/seher-logo.png", {
      fetcher: async () => {
        throw new Error("Logo URL indirilmemeli");
      },
      resolveHost: async () => ["93.184.216.34"],
    });
    expect(sonuc.tamam).toBe(false);
    expect(sonuc.sebep).toBe("logo-veya-yer-tutucu");
  });

  it("asiri yatay banner/logo oranina (>2.2) sahip gorseli eler", async () => {
    const yatayLogo = await sharp({
      create: { width: 900, height: 220, channels: 3, background: { r: 255, g: 255, b: 255 } },
    })
      .png()
      .toBuffer();

    const sonuc = await kaynakGorseliniDogrula("https://cdn.myikas.com/images/product-1.png", {
      fetcher: async () => new Response(new Uint8Array(yatayLogo), { status: 200 }),
      resolveHost: async () => ["93.184.216.34"],
    });
    expect(sonuc.tamam).toBe(false);
    expect(sonuc.sebep).toBe("logo-veya-yer-tutucu");
  });
});
