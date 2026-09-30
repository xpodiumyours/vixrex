import { describe, expect, it } from "vitest";
import {
  faturaSatirlariniDijitalIzle,
  sonucOzeti,
  type HamFaturaSatiri,
} from "@/lib/faturaEslestir";
import { firmaAnahtariniCoz } from "@/lib/ureticiKatalog";
import { dinamikUrunIzleriniBul, pdfKatalogGorseliniOku, hamGet } from "@/lib/faturaDijitalIz";
import { kaynakGorseliniDogrula } from "@/lib/faturaGorsel";

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

function kaynakKimligiyle(fetcher: (input: string) => Promise<Response>) {
  return async (input: string) => {
    const url = new URL(input);
    const adlar: Record<string, string> = {
      "rastgelegida.example": "Rastgele Gıda", "cakisan.example": "Çakışan Site",
      "ornek-toptan.example": "Örnek Toptan", "goldfreshmutfak.com": "Goldfresh Mutfak",
    };
    const ad = adlar[url.hostname];
    if (ad && ["/", "/iletisim", "/contact", "/hakkimizda", "/about-us", "/kurumsal"].includes(url.pathname)) {
      return new Response(`<html><head><title>${ad}</title></head><body>${ad}</body></html>`, {
        headers: { "content-type": "text/html" },
      });
    }
    return fetcher(input);
  };
}


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
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
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
      fetcher: kaynakKimligiyle(fetcher),
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
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
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
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
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
    const fetcher = async (input: string) => kaynakKimligiyle(async () => new Response("{}", { status: 404 }))(input);

    const sonuc = await faturaSatirlariniDijitalIzle(
      [satir("YOK1302")],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.tedarikciIz?.havuzda).toBe(false);
    expect(sonuc.satirlar[0].sonuc).toBe("iz-yok");
    expect(sonuc.satirlar[0].katalog).toBeNull();
    expect(sonucOzeti(sonuc.satirlar).izYok).toBe(1);
  });

  it("kodu olmayan ve markasi gecmeyen satir eksik bilgi sorar", async () => {
    const fetcher = async (input: string) => kaynakKimligiyle(async () => new Response("{}", { status: 404 }))(input);

    const sonuc = await faturaSatirlariniDijitalIzle(
      [{ ...satir(""), ad: "Bilinmeyen Ürün" }],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].uyari).toBeUndefined();
    expect(sonucOzeti(sonuc.satirlar).eksik).toBe(1);
  });

  it("faturada baska bir havuz firmasinin markasi geciyorsa satiri eksik diye isaretler ve ayrimi soyler", async () => {
    const fetcher = async (input: string) => kaynakKimligiyle(async () => new Response("{}", { status: 404 }))(input);

    const sonuc = await faturaSatirlariniDijitalIzle(
      [{ ...satir(""), ad: "Aycenk Gıda Ayçiçek Yağı 1 L" }],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
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
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
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
      fetcher: kaynakKimligiyle(fetcher),
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
      fetcher: kaynakKimligiyle(fetcher),
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
      fetcher: kaynakKimligiyle(fetcher),
      resolveHost,
      durum,
      simdi: () => (an += 5000),
      kesifButcesiMs: 1000,
    });

    expect(durum.sinirDoldu).toBe(true);
    expect(sonuc.satirlar[0].uyari).toContain("süresi doldu");
  });
});

describe("çok markalı toptancı faturası", () => {
  function shopifyYaniti(kod: string) {
    return new Response(
      JSON.stringify({
        products: [
          {
            title: "Dondurulmuş Ürün",
            vendor: "Goldfresh",
            handle: "dondurulmus-urun",
            images: [{ src: "https://cdn.example/urun.jpg" }],
            variants: [{ sku: kod, barcode: "", title: "Default Title" }],
          },
        ],
      }),
      { status: 200 },
    );
  }

  it("satırdaki marka toptancıdan farklıysa markanın kendi kaynağında aranır", async () => {
    const gidilenAlanlar: string[] = [];
    const fetcher = async (input: string) => {
      const alan = new URL(input).hostname;
      gidilenAlanlar.push(alan);
      if (alan === "goldfreshmutfak.com" && input.includes("/products.json")) {
        return shopifyYaniti("GF-123");
      }
      return new Response("{}", { status: 404 });
    };

    const sonuc = await faturaSatirlariniDijitalIzle(
      [{ ...satir("GF-123"), marka: "Goldfresh" }],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(gidilenAlanlar).toContain("goldfreshmutfak.com");
    expect(sonuc.satirlar[0].sonuc).toBe("kanitli");
    expect(sonuc.satirlar[0].katalog?.firma).toBe("Goldfresh Mutfak");
    expect(sonuc.satirlar[0].katalog?.kaynak).toContain("goldfreshmutfak.com");
  });

  it("markanın kaynağında ürün yoksa 'markanın kaynağında bulunamadı' yazılır", async () => {
    const fetcher = async (input: string) => kaynakKimligiyle(async () => new Response("{}", { status: 404 }))(input);

    const sonuc = await faturaSatirlariniDijitalIzle(
      [{ ...satir("GF-999"), marka: "Goldfresh Mutfak" }],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("iz-yok");
    expect(sonuc.satirlar[0].uyari).toContain("markanın resmî kaynağında");
  });

  it("marka faturayı kesen firmayla aynıysa ayrı marka araması yapılmaz", async () => {
    const gidilenAlanlar: string[] = [];
    const fetcher = async (input: string) => {
      gidilenAlanlar.push(new URL(input).hostname);
      return new Response("{}", { status: 404 });
    };

    await faturaSatirlariniDijitalIzle(
      [{ ...satir("GF-999"), marka: "Goldfresh" }],
      "Goldfresh Mutfak",
      "",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(new Set(gidilenAlanlar)).toEqual(new Set(["goldfreshmutfak.com"]));
  });
});


function gercekPdf(metin = "MODEL: ABC123 Cotton shirt"): Uint8Array {
  const resim = Buffer.alloc(800 * 800 * 3);
  for (let i = 0; i < resim.length; i++) resim[i] = (i * 37) % 255;
  const icerik = Buffer.from(`BT /F1 18 Tf 40 700 Td (${metin}) Tj ET q 400 0 0 400 40 250 cm /Im1 Do Q`);
  const nesneler = [
    Buffer.from("<< /Type /Catalog /Pages 2 0 R >>"),
    Buffer.from("<< /Type /Pages /Kids [3 0 R] /Count 1 >>"),
    Buffer.from("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 600 800] /Resources << /Font << /F1 4 0 R >> /XObject << /Im1 5 0 R >> >> /Contents 6 0 R >>"),
    Buffer.from("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"),
    Buffer.concat([Buffer.from(`<< /Type /XObject /Subtype /Image /Width 800 /Height 800 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Length ${resim.length} >>\nstream\n`), resim, Buffer.from("\nendstream")]),
    Buffer.concat([Buffer.from(`<< /Length ${icerik.length} >>\nstream\n`), icerik, Buffer.from("\nendstream")]),
  ];
  const parcalar = [Buffer.from("%PDF-1.4\n")];
  const offsetler: number[] = [];
  let offset = parcalar[0].length;
  nesneler.forEach((nesne, i) => {
    offsetler.push(offset);
    const parca = Buffer.concat([Buffer.from(`${i + 1} 0 obj\n`), nesne, Buffer.from("\nendobj\n")]);
    parcalar.push(parca);
    offset += parca.length;
  });
  parcalar.push(Buffer.from(`xref\n0 7\n0000000000 65535 f \n` +
    offsetler.map((n) => `${String(n).padStart(10, "0")} 00000 n \n`).join("") +
    `trailer\n<< /Size 7 /Root 1 0 R >>\nstartxref\n${offset}\n%%EOF`));
  return new Uint8Array(Buffer.concat(parcalar));
}

const pdfKaynak = "https://resmi.example/katalog.pdf";
const resmiIz = {
  anahtar: null, firma: "Resmi", alan: "resmi.example", platform: "shopify",
  izinDurumu: "yok" as const, kaynak: "https://resmi.example", havuzda: false,
  dogrulama: {
    guc: "guclu" as const, kanitlar: ["vergi_no"], bagliHesaplar: [],
    katalogDosyalari: [pdfKaynak],
  },
};

function pdfFetch(pdf: Uint8Array) {
  return async (input: string) => input === pdfKaynak
    ? new Response(pdf.slice(), { headers: { "content-type": "application/pdf" } })
    : new Response("{}", { status: 404 });
}

describe("resmi PDF ve sosyal katalog baglantisi", () => {
  it("gercek PDF metni ve 800px gomulu resmi kalite yoluna tasir", async () => {
    const fetcher = pdfFetch(gercekPdf());
    const sonuc = await dinamikUrunIzleriniBul([{ model: "ABC123", barkod: "" }], resmiIz, { fetcher, resolveHost });
    const hedef = sonuc[0];
    if (!hedef || "celiski" in hedef) throw new Error("PDF urunu bekleniyordu");
    expect(hedef.urun.kaynak).toBe(`${pdfKaynak}#page=1`);
    expect(hedef.urun.barkod).toBe("");
    const adres = hedef.urun.gorseller[0];
    const bayt = await pdfKatalogGorseliniOku(adres, { fetcher, resolveHost });
    expect(Buffer.from(bayt ?? []).subarray(0, 8)).toEqual(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
    const kalite = await kaynakGorseliniDogrula(adres, { fetcher, resolveHost });
    expect(kalite.tamam).toBe(true);
    expect(kalite.genislik).toBe(800);
    const url = new URL(adres);
    const hash = new URLSearchParams(url.hash.slice(1));
    hash.set("vixrex-sha256", "0".repeat(64));
    url.hash = hash.toString();
    expect(await pdfKatalogGorseliniOku(url.toString(), { fetcher, resolveHost })).toBeNull();
  });

  it("yalniz acik GTIN bulunan PDF urununu model uydurmadan bulur", async () => {
    const fetcher = pdfFetch(gercekPdf("GTIN: 8690000000123 Cotton shirt"));
    const sonuc = await dinamikUrunIzleriniBul([{ model: "", barkod: "8690000000123" }], resmiIz, { fetcher, resolveHost });
    const hedef = sonuc[0];
    if (!hedef || "celiski" in hedef) throw new Error("GTIN urunu bekleniyordu");
    expect(hedef.dayanak).toBe("barkod");
    expect(hedef.urun.kod).toBe("");
    expect(hedef.urun.barkod).toBe("8690000000123");
  });

  it("iki urun koduna bir fotografi kesin baglamaz", async () => {
    const fetcher = pdfFetch(gercekPdf("MODEL: ABC123 MODEL: DEF456 Two products"));
    expect(await dinamikUrunIzleriniBul([{ model: "ABC123", barkod: "" }], resmiIz, { fetcher, resolveHost })).toEqual([null]);
  });

  it("resmi hesabin ItemList urununu baglar", async () => {
    const hesap = "https://www.instagram.com/resmi/";
    const html = `<script type="application/ld+json">${JSON.stringify({
      "@type": "ItemList", itemListElement: [{ "@type": "ListItem", item: {
        "@type": "Product", name: "Resmi Gomlek", sku: "ABC123", brand: { name: "Resmi" },
        image: "https://resmi.example/abc123.jpg", url: hesap,
      } }],
    })}</script>`;
    const fetcher = async (input: string) => input === hesap ? new Response(html) : new Response("{}", { status: 404 });
    const sonuc = await dinamikUrunIzleriniBul([{ model: "ABC123", barkod: "", marka: "Resmi" }], {
      ...resmiIz, dogrulama: { ...resmiIz.dogrulama, bagliHesaplar: [hesap], katalogDosyalari: [] },
    }, { fetcher, resolveHost });
    const hedef = sonuc[0];
    if (!hedef || "celiski" in hedef) throw new Error("Resmi urun bekleniyordu");
    expect(hedef.urun.ad).toBe("Resmi Gomlek");
  });

  it("ozel IP PDF kaynagini indirmez", async () => {
    let cagrildi = false;
    const hash = new URLSearchParams({ "vixrex-page": "1", "vixrex-image": "0", "vixrex-sha256": "0".repeat(64) });
    expect(await pdfKatalogGorseliniOku(`${pdfKaynak}#${hash}`, {
      resolveHost: async () => ["127.0.0.1"], fetcher: async () => {
        cagrildi = true; return new Response(Buffer.from(gercekPdf()));
      },
    })).toBeNull();
    expect(cagrildi).toBe(false);
  });

  it("boyut basligi olmadan siniri asan PDF akisinin kalanini okumaz", async () => {
    let iptal = false;
    let parca = 0;
    const fetcher = async () => new Response(new ReadableStream<Uint8Array>({
      pull(controller) { parca++; controller.enqueue(new Uint8Array(1024 * 1024)); },
      cancel() { iptal = true; },
    }), { headers: { "content-type": "application/pdf" } });
    expect(await hamGet(pdfKaynak, fetcher, resolveHost)).toBeNull();
    expect(iptal).toBe(true);
    expect(parca).toBeLessThanOrEqual(23);
  });
});
