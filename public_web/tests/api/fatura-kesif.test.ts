import { describe, expect, it, vi, afterEach } from "vitest";
import { firmaSitesiniModeldenBul, satirlariModeldenEslestir } from "@/lib/faturaKesif";

afterEach(() => {
  vi.unstubAllGlobals();
  delete process.env.OPENROUTER_API_KEY;
});

function modelCevabi(json: unknown) {
  return new Response(
    JSON.stringify({ choices: [{ message: { content: JSON.stringify(json) } }] }),
    { status: 200, headers: { "content-type": "application/json" } },
  );
}

describe("fatura kesfi", () => {
  it("anahtar yoksa site uydurmaz", async () => {
    delete process.env.OPENROUTER_API_KEY;
    const sonuc = await firmaSitesiniModeldenBul({
      tedarikci: "Voltaj",
      vergiNo: "",
      adres: "",
      markalar: [],
      urunAdlari: ["tisort"],
    });
    expect(sonuc).toBeNull();
  });

  it("model resmi site doner, pazaryerini atar", async () => {
    process.env.OPENROUTER_API_KEY = "test";
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => modelCevabi({ firma: "Voltaj", site: "voltaj.com.tr" })),
    );
    const sonuc = await firmaSitesiniModeldenBul({
      tedarikci: "Voltaj",
      vergiNo: "",
      adres: "",
      markalar: ["VOLTAJ"],
      urunAdlari: ["Mehr Erkek Tişört"],
    });
    expect(sonuc).toEqual({ firma: "Voltaj", site: "voltaj.com.tr" });
  });

  it("trendyol sitesini resmi kaynak saymaz", async () => {
    process.env.OPENROUTER_API_KEY = "test";
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => modelCevabi({ firma: "Voltaj", site: "trendyol.com" })),
    );
    const sonuc = await firmaSitesiniModeldenBul({
      tedarikci: "Voltaj",
      vergiNo: "",
      adres: "",
      markalar: [],
      urunAdlari: [],
    });
    expect(sonuc).toBeNull();
  });

  it("sitede olmayan urunu uydurmaz, listedeki urune baglar", async () => {
    process.env.OPENROUTER_API_KEY = "test";
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => modelCevabi({ eslesmeler: [{ satir: 0, urunler: [1] }] })),
    );
    const baglar = await satirlariModeldenEslestir(
      [{ model: "ABC", ad: "polo tisort", barkod: "", marka: "VOLTAJ" }],
      [
        {
          kod: "X1",
          ad: "Baska Urun",
          marka: "VOLTAJ",
          aciklama: "",
          barkod: "",
          gorseller: ["https://voltaj.com.tr/a.jpg"],
          kaynak: "https://voltaj.com.tr/a",
        },
        {
          kod: "201VOL0089",
          ad: "Jeremy Polo Erkek Tişört Beyaz",
          marka: "VOLTAJ",
          aciklama: "Resmi aciklama",
          barkod: "",
          gorseller: ["https://voltaj.com.tr/b.jpg"],
          kaynak: "https://voltaj.com.tr/products/jeremy",
        },
      ],
    );
    expect(baglar[0]).toEqual([1]);
  });
});
