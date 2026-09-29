import { describe, expect, it } from "vitest";
import { faturaSatirlariniDijitalIzle, type HamFaturaSatiri } from "@/lib/faturaEslestir";
import { firmaAnahtariniCoz } from "@/lib/ureticiKatalog";

function satir(model: string, barkod = ""): HamFaturaSatiri {
  return {
    model,
    ad: "",
    barkod,
    varyant: "",
    beden: "",
    adet: 1,
    alisBirimFiyat: null,
    satirToplam: null,
    guven: 0.9,
  };
}

const resolveHost = async () => ["8.8.8.8"];

describe("fatura dinamik dijital iz", () => {
  it("hazir katalogu olmayan 55 havuz firmasini kimlik olarak cozer", () => {
    expect(firmaAnahtariniCoz("Goldfresh Mutfak")).toBe("goldfresh-mutfak");
  });

  it("havuzdaki katalogsuz Shopify firmasindan birebir kodla kaynak bulur", async () => {
    const fetcher = async (input: string) => {
      expect(input).toContain("goldfreshmutfak.com/products.json");
      return new Response(
        JSON.stringify({
          products: [
            {
              title: "Dondurulmuş Ürün",
              vendor: "Goldfresh",
              body_html: "<p>Resmi ürün açıklaması</p>",
              handle: "dondurulmus-urun",
              images: [{ src: "https://cdn.example/urun.jpg" }],
              variants: [{ sku: "GF-123", barcode: "8690000000123", title: "Default Title" }],
            },
          ],
        }),
        { status: 200, headers: { "content-type": "application/json" } },
      );
    };

    const sonuc = await faturaSatirlariniDijitalIzle(
      [satir("GF-123")],
      "Goldfresh Mutfak",
      "",
      { fetcher, resolveHost },
    );

    expect(sonuc.tedarikciIz?.anahtar).toBe("goldfresh-mutfak");
    expect(sonuc.satirlar[0].katalog?.resmiAd).toBe("Dondurulmuş Ürün");
    expect(sonuc.satirlar[0].katalog?.kaynak).toBe(
      "https://goldfreshmutfak.com/products/dondurulmus-urun",
    );
    expect(sonuc.satirlar[0].katalog?.gorseller).toEqual([]);
  });

  it("55 havuzu disindaki tedarikciyi faturadaki resmi siteyle ayirir ve kod cakismasini karistirmaz", async () => {
    const fetcher = async (input: string) => {
      if (input.includes("/products.json")) return new Response("{}", { status: 404 });
      if (input.includes("/wp-json/wc/store/v1/products")) {
        return new Response(
          JSON.stringify([
            {
              sku: "ELT1302",
              name: "Dış Firma Ürünü",
              brands: [{ name: "Dış Marka" }],
              short_description: "<p>Dış firma açıklaması</p>",
              images: [{ src: "https://dis.example/urun.jpg" }],
              permalink: "https://rastgelegida.example/urun/elt1302",
            },
          ]),
          { status: 200, headers: { "content-type": "application/json" } },
        );
      }
      return new Response("{}", { status: 404 });
    };

    const sonuc = await faturaSatirlariniDijitalIzle(
      [satir("ELT1302")],
      "Rastgele Gıda",
      "https://rastgelegida.example",
      { fetcher, resolveHost },
    );

    expect(sonuc.tedarikciIz?.havuzda).toBe(false);
    expect(sonuc.tedarikciIz?.kaynak).toBe("https://rastgelegida.example");
    expect(sonuc.satirlar[0].katalog?.firma).toBe("Rastgele Gıda");
    expect(sonuc.satirlar[0].katalog?.marka).toBe("Dış Marka");
    expect(sonuc.satirlar[0].katalog?.resmiAd).toBe("Dış Firma Ürünü");
    expect(sonuc.satirlar[0].katalog?.gorseller).toEqual([]);
  });
});
