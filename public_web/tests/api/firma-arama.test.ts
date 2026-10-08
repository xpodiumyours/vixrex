import { describe, expect, it } from "vitest";

import { firmaSitesiniAra } from "@/lib/firmaArama";

function lunaYaniti(alan: string, kaynak: string) {
  const govde = {
    output: [
      {
        type: "message",
        content: [{ type: "output_text", text: JSON.stringify({ alan, kaynak }) }],
      },
    ],
    usage: { input_tokens: 100, output_tokens: 20 },
  };
  return (async () => ({
    ok: true,
    json: async () => govde,
  })) as unknown as typeof fetch;
}

function dogrulaHtml(html: string) {
  return async (input: string) => {
    const adres = String(input);
    if (adres.includes("openrouter.ai")) {
      return lunaYaniti("etigida.com.tr", "https://etigida.com.tr")(
        "https://openrouter.ai",
        {},
      );
    }
    return new Response(html, { status: 200, headers: { "content-type": "text/html" } });
  };
}

describe("firma resmi site arama", () => {
  it("anahtar yoksa arama kapalıdır, akış durmaz", async () => {
    const sonuc = await firmaSitesiniAra("Eti Gıda", { apiAnahtari: "" });

    expect(sonuc.durum).toBe("kapali");
  });

  it("Luna sonucunu doğrulanmış alan olarak döndürür", async () => {
    const sonuc = await firmaSitesiniAra("Eti Gıda Sanayi", {
      apiAnahtari: "test-anahtar",
      kimlik: { vergiNo: "1234567890", adres: "" },
      dogrula: { resolveHost: async () => ["8.8.8.8"] },
      fetcher: dogrulaHtml(
        "<html><title>Eti Gıda</title><body>Vergi No 1234567890</body></html>",
      ) as unknown as typeof fetch,
    });

    expect(sonuc.durum).toBe("bulundu");
    if (sonuc.durum === "bulundu") {
      expect(sonuc.alan).toBe("etigida.com.tr");
    }
  });

  it("pazaryeri döndüren Luna elenir", async () => {
    const sonuc = await firmaSitesiniAra("Tutku Tuhafiye", {
      apiAnahtari: "test-anahtar",
      kimlik: { vergiNo: "1234567890", adres: "" },
      dogrula: { resolveHost: async () => ["8.8.8.8"] },
      fetcher: (async () => ({
        ok: true,
        json: async () => ({
          output: [
            {
              type: "message",
              content: [
                {
                  type: "output_text",
                  text: JSON.stringify({ alan: "instagram.com", kaynak: "https://instagram.com/x" }),
                },
              ],
            },
          ],
        }),
      })) as unknown as typeof fetch,
    });

    expect(sonuc.durum).toBe("bulunamadi");
  });

  it("doğrulanamayan alan bulunamadı döner", async () => {
    const sonuc = await firmaSitesiniAra("Berrak İç Giyim", {
      apiAnahtari: "test-anahtar",
      kimlik: { vergiNo: "1234567890", adres: "" },
      dogrula: { resolveHost: async () => ["8.8.8.8"] },
      fetcher: (async (input: string) => {
        if (String(input).includes("openrouter.ai")) {
          return {
            ok: true,
            json: async () => ({
              output: [
                {
                  type: "message",
                  content: [
                    {
                      type: "output_text",
                      text: JSON.stringify({
                        alan: "baska-firma.com",
                        kaynak: "https://baska-firma.com",
                      }),
                    },
                  ],
                },
              ],
            }),
          };
        }
        return new Response("<html><title>Başka firma</title><body>Vergi No 9999999999</body></html>", {
          status: 200,
          headers: { "content-type": "text/html" },
        });
      }) as unknown as typeof fetch,
    });

    expect(sonuc.durum).toBe("bulunamadi");
  });

  it("arama servisine ulaşılamazsa bulunamadı döner, hata fırlatmaz", async () => {
    const sonuc = await firmaSitesiniAra("Ülker Çikolata", {
      apiAnahtari: "test-anahtar",
      fetcher: (async () => {
        throw new Error("ağ yok");
      }) as unknown as typeof fetch,
    });

    expect(sonuc.durum).toBe("bulunamadi");
  });

  it("çok kısa firma adıyla arama yapılmaz", async () => {
    const sonuc = await firmaSitesiniAra("AB", { apiAnahtari: "test-anahtar" });

    expect(sonuc.durum).toBe("bulunamadi");
  });

  it("Luna isteği web_search aracıyla gider", async () => {
    const govdeYakala: RequestInit[] = [];
    const lunaMock = async () => ({
      ok: true,
      json: async () => ({
        output: [
          {
            type: "message",
            content: [
              {
                type: "output_text",
                text: JSON.stringify({ alan: "etigida.com.tr", kaynak: "https://etigida.com.tr" }),
              },
            ],
          },
        ],
      }),
    });

    await firmaSitesiniAra("Eti Gıda", {
      apiAnahtari: "k",
      kimlik: { vergiNo: "", adres: "" },
      dogrula: {
        resolveHost: async () => ["8.8.8.8"],
        fetcher: (async () =>
          new Response("<html><title>Eti Gıda</title></html>", { status: 200 })) as unknown as typeof fetch,
      },
      fetcher: (async (url: string, init?: RequestInit) => {
        if (String(url).includes("openrouter.ai")) {
          if (init) govdeYakala.push(init);
          return lunaMock() as unknown as Response;
        }
        return new Response("<html><title>Eti Gıda</title></html>", { status: 200 });
      }) as unknown as typeof fetch,
    });

    expect(govdeYakala.length).toBe(1);
    const govde = JSON.parse(String(govdeYakala[0]?.body ?? "{}"));
    expect(govde.model).toBe("openai/gpt-5.6-luna");
    expect(JSON.stringify(govde.tools)).toContain("web_search");
  });
});
