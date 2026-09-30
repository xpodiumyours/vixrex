import { describe, expect, it } from "vitest";
import {
  faturaSatirlariniDijitalIzle,
  sonucOzeti,
  type HamFaturaSatiri,
} from "@/lib/faturaEslestir";
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
    // Kilitli kapsam: fotoğraf taşınır; kullanım izni sonra istenir.
    expect(sonuc.satirlar[0].katalog?.gorseller).toEqual(["https://cdn.example/urun.jpg"]);
  });

  it("taninmayan tedarikci adi varken kod cakismasiyla baska firmaya baglanmaz", async () => {
    // Arama kapalı (anahtarsız) ve site ipucu yok: iz kurulmaz, satır
    // başka firmaya kilitlenmez.
    const sonuc = await faturaSatirlariniDijitalIzle([satir("ELT1302")], "Rastgele Tedarikçi", "", {
      resolveHost,
      firmaArama: { apiAnahtari: "" },
    });
    expect(sonuc.tedarikciIz).toBeNull();
    expect(sonuc.satirlar[0].katalog).toBeNull();
  });

  it("havuz disi firma aramada bulununca ayni kesif oradan yurur", async () => {
    // Kilitli kapsam: havuz SADECE hızlı yoldur. Eti gibi büyük üretici
    // listede yoksa adı aratılır, resmi sitesi bulununca ürünler eşleşir.
    const fetcher = async (input: string) => {
      if (input.includes("api.search.brave.com")) {
        return new Response(
          JSON.stringify({
            web: { results: [{ url: "https://www.etigida.com.tr", title: "Eti Gıda" }] },
          }),
          { status: 200, headers: { "content-type": "application/json" } },
        );
      }
      if (input.includes("etigida.com.tr/sitemap.xml")) {
        return new Response(
          `<urlset><url><loc>https://www.etigida.com.tr/urun/kakaolu-biskivi</loc></url></urlset>`,
          { status: 200, headers: { "content-type": "application/xml" } },
        );
      }
      if (input.includes("etigida.com.tr/urun/")) {
        return new Response(
          `<html><head><script type="application/ld+json">${JSON.stringify({
            "@type": "Product",
            name: "Eti Kakaolu Bisküvi",
            sku: "ETI-001",
            brand: "Eti",
            description: "Kakaolu bisküvi",
            image: ["https://www.etigida.com.tr/gorsel/biskuvi.jpg"],
          })}</script></head></html>`,
          { status: 200, headers: { "content-type": "text/html" } },
        );
      }
      return new Response("{}", { status: 404 });
    };

    const sonuc = await faturaSatirlariniDijitalIzle([satir("ETI-001")], "Eti Gıda", "", {
      fetcher,
      resolveHost,
      firmaArama: { apiAnahtari: "test-anahtar", fetcher },
    });

    expect(sonuc.tedarikciIz?.havuzda).toBe(false);
    expect(sonuc.tedarikciIz?.kaynak).toBe("https://etigida.com.tr");
    expect(sonuc.satirlar[0].sonuc).toBe("kanitli");
    expect(sonuc.satirlar[0].katalog?.resmiAd).toBe("Eti Kakaolu Bisküvi");
    expect(sonuc.satirlar[0].katalog?.gorseller).toEqual([
      "https://www.etigida.com.tr/gorsel/biskuvi.jpg",
    ]);
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
    // Kilitli kapsam: fotoğraf taşınır; kullanım izni sonra istenir.
    expect(sonuc.satirlar[0].katalog?.gorseller).toEqual(["https://dis.example/urun.jpg"]);
    expect(sonuc.satirlar[0].sonuc).toBe("kanitli");
  });

  it("ayni kod iki farkli urun sayfasina duserse eslesme kurmaz, celiski gosterir", async () => {
    const fetcher = async (input: string) => {
      if (input.includes("/products.json")) {
        return new Response(
          JSON.stringify({
            products: [
              {
                title: "Örnek A",
                handle: "ornek-a",
                variants: [{ sku: "ORTAK-1", barcode: "8690000000001", title: "Default Title" }],
              },
              {
                title: "Örnek B",
                handle: "ornek-b",
                variants: [{ sku: "ORTAK-1", barcode: "8690000000002", title: "Default Title" }],
              },
            ],
          }),
          { status: 200, headers: { "content-type": "application/json" } },
        );
      }
      return new Response("{}", { status: 404 });
    };

    const sonuc = await faturaSatirlariniDijitalIzle(
      [satir("ORTAK-1")],
      "Çakışan Site",
      "https://cakisan.example",
      { fetcher, resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("celiski");
    expect(sonuc.satirlar[0].katalog).toBeNull();
    expect(sonuc.satirlar[0].celiski?.dayanak).toBe("kod");
    expect(sonuc.satirlar[0].celiski?.adaylar.map((aday) => aday.kaynak)).toEqual([
      "https://cakisan.example/products/ornek-a",
      "https://cakisan.example/products/ornek-b",
    ]);
    expect(sonucOzeti(sonuc.satirlar)).toEqual({
      kanitli: 0,
      eksik: 0,
      celiski: 1,
      izYok: 0,
    });
  });

  it("kaynakta hicbir yerde bulunamayan kod iz bulunamadı sonucunu verir", async () => {
    const fetcher = async () => new Response("{}", { status: 404 });

    const sonuc = await faturaSatirlariniDijitalIzle(
      [satir("YOK1302")],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher, resolveHost },
    );

    expect(sonuc.tedarikciIz?.havuzda).toBe(false);
    expect(sonuc.satirlar[0].sonuc).toBe("iz-yok");
    expect(sonuc.satirlar[0].katalog).toBeNull();
    expect(sonucOzeti(sonuc.satirlar).izYok).toBe(1);
  });

  it("kodu olmayan ve markasi gecmeyen satir eksik bilgi sorar", async () => {
    const fetcher = async () => new Response("{}", { status: 404 });

    const sonuc = await faturaSatirlariniDijitalIzle(
      [{ ...satir(""), ad: "Bilinmeyen Ürün" }],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher, resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].uyari).toBeUndefined();
    expect(sonucOzeti(sonuc.satirlar).eksik).toBe(1);
  });

  it("faturada baska bir havuz firmasinin markasi geciyorsa satiri eksik diye isaretler ve ayrimi soyler", async () => {
    const fetcher = async () => new Response("{}", { status: 404 });

    const sonuc = await faturaSatirlariniDijitalIzle(
      [{ ...satir(""), ad: "Aycenk Gıda Ayçiçek Yağı 1 L" }],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher, resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].uyari).toContain("Aycenk Gıda");
    expect(sonuc.satirlar[0].uyari).toContain("marka ayrı");
  });

  it("JSON-LD urun sayfasi okuyarak sitemap uzerinden kaynak bulur", async () => {
    const html = `<html><head><script type="application/ld+json">{"@context":"https://schema.org","@type":"Product","name":"Örnek Gömlek","sku":"ABC123","gtin13":"8690000000777","brand":{"@type":"Brand","name":"Örnek Marka"},"description":"<p>Örnek açıklama</p>","image":["https://ornek-toptan.example/gorsel.jpg"],"url":"https://ornek-toptan.example/urun/abc-123"}</script></head><body></body></html>`;
    const fetcher = async (input: string) => {
      if (input.includes("/sitemap.xml")) {
        return new Response(
          "<urlset><loc>https://ornek-toptan.example/urun/abc-123</loc></urlset>",
          { status: 200, headers: { "content-type": "application/xml" } },
        );
      }
      if (input.includes("/urun/abc-123")) {
        return new Response(html, {
          status: 200,
          headers: { "content-type": "text/html" },
        });
      }
      return new Response("{}", { status: 404 });
    };

    const sonuc = await faturaSatirlariniDijitalIzle(
      [satir("ABC-123")],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher, resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("kanitli");
    expect(sonuc.satirlar[0].katalog?.resmiAd).toBe("Örnek Gömlek");
    expect(sonuc.satirlar[0].katalog?.marka).toBe("Örnek Marka");
    expect(sonuc.satirlar[0].katalog?.kaynak).toBe(
      "https://ornek-toptan.example/urun/abc-123",
    );
    // Kilitli kapsam: fotoğraf taşınır; kullanım izni sonra istenir.
    expect(sonuc.satirlar[0].katalog?.gorseller).toEqual([
      "https://ornek-toptan.example/gorsel.jpg",
    ]);
    expect(sonuc.satirlar[0].katalog?.gorselAdaylari).toEqual([
      "https://ornek-toptan.example/gorsel.jpg",
    ]);
    expect(sonuc.satirlar[0].katalog?.izinDurumu).toBe("yok");
  });
});

describe("hedefli arama ve erişim durumu", () => {
  function yanit(veri: unknown, durum = 200) {
    return new Response(JSON.stringify(veri), {
      status: durum,
      headers: { "content-type": "application/json" },
    });
  }

  it("ilk sayfalarda olmayan Shopify ürünü kodla aratılarak bulunur", async () => {
    const fetcher = async (input: string) => {
      if (input.includes("/products.json")) {
        return yanit({
          products: [
            { title: "Başka Ürün", vendor: "Goldfresh", handle: "baska", images: [], variants: [{ sku: "XX-1" }] },
          ],
        });
      }
      if (input.includes("/search/suggest.json")) {
        expect(input).toContain("q=GF-777");
        return yanit({ resources: { results: { products: [{ handle: "gizli-urun" }] } } });
      }
      if (input.includes("/products/gizli-urun.json")) {
        return yanit({
          product: {
            title: "Gizli Ürün",
            vendor: "Goldfresh",
            handle: "gizli-urun",
            images: [{ src: "https://cdn.example/gizli.jpg" }],
            variants: [{ sku: "GF-777", barcode: "", title: "Default Title" }],
          },
        });
      }
      return yanit({}, 404);
    };

    const sonuc = await faturaSatirlariniDijitalIzle([satir("GF-777")], "Goldfresh Mutfak", "", {
      fetcher,
      resolveHost,
    });

    expect(sonuc.satirlar[0].sonuc).toBe("kanitli");
    expect(sonuc.satirlar[0].katalog?.resmiAd).toBe("Gizli Ürün");
  });

  it("kaynağa erişilemezse satır iz-yok olur ama nedeni erişim olarak yazılır", async () => {
    const fetcher = async () => {
      throw new Error("ag hatasi");
    };
    const durum = { erisimHatasi: false, sinirDoldu: false };

    const sonuc = await faturaSatirlariniDijitalIzle([satir("GF-123")], "Goldfresh Mutfak", "", {
      fetcher,
      resolveHost,
      durum,
    });

    expect(durum.erisimHatasi).toBe(true);
    expect(sonuc.satirlar[0].sonuc).toBe("iz-yok");
    expect(sonuc.satirlar[0].uyari).toContain("erişilemedi");
  });

  it("kesif süresi dolarsa 'yok' denmez, süre doldu işaretlenir", async () => {
    let an = 0;
    const fetcher = async () => yanit({ products: [] });
    const durum = { erisimHatasi: false, sinirDoldu: false };

    const sonuc = await faturaSatirlariniDijitalIzle([satir("GF-123")], "Goldfresh Mutfak", "", {
      fetcher,
      resolveHost,
      durum,
      simdi: () => (an += 5000),
      kesifButcesiMs: 1000,
    });

    expect(durum.sinirDoldu).toBe(true);
    expect(sonuc.satirlar[0].uyari).toContain("süresi doldu");
  });
});
