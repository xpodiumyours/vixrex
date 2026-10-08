import { describe, expect, it } from "vitest";
import sharp from "sharp";
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
const faturaKimligi = { vergiNo: "1234567890", adres: "" };

function izle(
  satirlar: HamFaturaSatiri[],
  tedarikci = "",
  site = "",
  bag: Parameters<typeof faturaSatirlariniDijitalIzle>[3] = {},
) {
  return faturaSatirlariniDijitalIzle(satirlar, tedarikci, site, {
    resolveHost,
    tedarikciKimligi: faturaKimligi,
    ...bag,
  });
}

function kaynakKimligiyle(fetcher: (input: string, init?: RequestInit) => Promise<Response>) {
  return async (input: string, init?: RequestInit) => {
    const url = new URL(input);
    const adlar: Record<string, string> = {
      "rastgelegida.example": "Rastgele Gıda", "cakisan.example": "Çakışan Site",
      "ornek-toptan.example": "Örnek Toptan", "goldfreshmutfak.com": "Goldfresh Mutfak",
      "etigida.com.tr": "Eti Gıda",
    };
    const ad = adlar[url.hostname];
    if (ad && ["/", "/iletisim", "/contact", "/hakkimizda", "/about-us", "/kurumsal"].includes(url.pathname)) {
      return new Response(
        `<html><head><title>${ad}</title></head><body>${ad} Vergi No 1234567890</body></html>`,
        { headers: { "content-type": "text/html" } },
      );
    }
    return fetcher(input, init);
  };
}


describe("fatura dinamik dijital iz", () => {
  it("hazir katalogu olmayan 55 havuz firmasini kimlik olarak cozer", () => {
    expect(firmaAnahtariniCoz("Goldfresh Mutfak")).toBe("goldfresh-mutfak");
  });

  it("Luna yoksa havuz taraması koşmaz, satır eksik kalır", async () => {
    const fetcher = async (input: string) => {
      expect(input).not.toContain("openrouter.ai");
      return new Response("{}", { status: 404 });
    };

    const sonuc = await izle(
      [satir("GF-123")],
      "Goldfresh Mutfak",
      "",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.tedarikciIz).toBeNull();
    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].katalog).toBeNull();
  });

  it("Luna yoksa ada göre tahmin kurulmaz", async () => {
    const fetcher = async () => new Response("{}", { status: 404 });

    const sonuc = await izle(
      [{ ...satir("YOK-999"), ad: "Dondurulmuş Bezelye 1 kg" }],
      "Goldfresh Mutfak",
      "",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].katalog).toBeNull();
  });

  it("Luna yoksa yakın adlar çelişki üretmez", async () => {
    const fetcher = async () => new Response("{}", { status: 404 });

    const sonuc = await izle(
      [{ ...satir("YOK-999"), ad: "Dondurulmuş Bezelye" }],
      "Goldfresh Mutfak",
      "",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].katalog).toBeNull();
  });

  it("listede adi duran firmanin sitesi baska firmaya aitse baglanmaz", async () => {
    const gidilen: string[] = [];
    const fetcher = async (input: string) => {
      gidilen.push(input);
      const yol = new URL(input).pathname;
      if (["/", "/iletisim", "/contact", "/hakkimizda", "/about-us", "/kurumsal"].includes(yol)) {
        return new Response("<html><head><title>Bambaşka Firma</title></head><body>Bambaşka Firma</body></html>", {
          status: 200,
          headers: { "content-type": "text/html" },
        });
      }
      return new Response(
        JSON.stringify({ products: [{ title: "Yanlış ürün", variants: [{ sku: "GF-123" }] }] }),
        { status: 200, headers: { "content-type": "application/json" } },
      );
    };

    const sonuc = await izle([satir("GF-123")], "Goldfresh Mutfak", "", {
      fetcher,
      resolveHost,
      firmaArama: { apiAnahtari: "" },
    });

    expect(sonuc.tedarikciIz).toBeNull();
    expect(sonuc.satirlar[0].katalog).toBeNull();
    expect(sonuc.aramaDurumu.siteDurumu?.durum).toBe("arama_kapali");
    expect(gidilen.some((adres) => adres.includes("products.json"))).toBe(false);
  });

  it("taninmayan tedarikci adi varken kod cakismasiyla baska firmaya baglanmaz", async () => {
    // Arama kapalı (anahtarsız) ve site ipucu yok: iz kurulmaz, satır
    // başka firmaya kilitlenmez.
    const sonuc = await izle([satir("ELT1302")], "Rastgele Tedarikçi", "", {
      resolveHost,
      firmaArama: { apiAnahtari: "" },
    });
    expect(sonuc.tedarikciIz).toBeNull();
    expect(sonuc.satirlar[0].katalog).toBeNull();
  });

  it("Luna siteyi bulup sayfadan kart kurar", async () => {
    const gurultu = Buffer.alloc(1200 * 1200 * 3);
    for (let i = 0; i < gurultu.length; i += 97) gurultu[i] = (i * 13) % 251;
    const foto = await sharp(gurultu, { raw: { width: 1200, height: 1200, channels: 3 } }).jpeg({ quality: 80 }).toBuffer();
    const sayfa = "https://www.etigida.com.tr/urun/kakaolu-biskivi";
    const gorsel = "https://www.etigida.com.tr/gorsel/biskuvi.jpg";
    const fetcher = async (input: string, init?: RequestInit) => {
      if (input.includes("openrouter.ai")) {
        const govde = JSON.parse(String(init?.body ?? "{}"));
        const metin = JSON.stringify(govde.input ?? "");
        if (metin.includes("resmi web sitesi")) {
          return new Response(JSON.stringify({
            output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify({ alan: "etigida.com.tr", kaynak: "https://etigida.com.tr" }) }] }],
          }), { status: 200 });
        }
        if (govde.tools) {
          return new Response(JSON.stringify({
            output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify({ sayfa, gorsel }) }] }],
          }), { status: 200 });
        }
        if (metin.includes("SAYFA:")) {
          return new Response(JSON.stringify({
            output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify({ aciklama: "ETI-001 Kakaolu bisküvi" }) }] }],
          }), { status: 200 });
        }
        if (metin.includes("gerçek ürün fotoğrafı")) {
          return new Response(JSON.stringify({
            output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify({ uygun: true }) }] }],
          }), { status: 200 });
        }
        return new Response(JSON.stringify({
          output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify({ alan: "etigida.com.tr", kaynak: "https://etigida.com.tr" }) }] }],
        }), { status: 200 });
      }
      if (input === sayfa) {
        return new Response("<html><body>ETI-001 Kakaolu bisküvi detaylı metin</body></html>", { status: 200 });
      }
      if (input === gorsel) return new Response(new Uint8Array(foto), { status: 200 });
      return new Response("{}", { status: 404 });
    };

    const sonuc = await izle([satir("ETI-001")], "Eti Gıda", "", {
      fetcher: kaynakKimligiyle(fetcher),
      resolveHost,
      firmaArama: { apiAnahtari: "test-anahtar", fetcher },
    });

    expect(sonuc.tedarikciIz?.havuzda).toBe(false);
    expect(sonuc.tedarikciIz?.kaynak).toBe("https://etigida.com.tr");
    expect(sonuc.satirlar[0].sonuc).toBe("kanitli");
    expect(sonuc.satirlar[0].katalog?.kaynak).toBe(sayfa);
    expect(sonuc.satirlar[0].katalog?.gorseller).toEqual([gorsel]);
  });

  it("Luna yoksa site bilinse bile tahmin kurulmaz", async () => {
    const fetcher = async () => new Response("{}", { status: 404 });

    const sonuc = await izle(
      [satir("ELT1302")],
      "Rastgele Gıda",
      "https://rastgelegida.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.tedarikciIz?.havuzda).toBe(false);
    expect(sonuc.tedarikciIz?.kaynak).toBe("https://rastgelegida.example");
    expect(sonuc.satirlar[0].katalog).toBeNull();
    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
  });

  it("Luna yoksa ortak kod çelişki üretmez", async () => {
    const fetcher = async () => new Response("{}", { status: 404 });

    const sonuc = await izle(
      [satir("ORTAK-1")],
      "Çakışan Site",
      "https://cakisan.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].katalog).toBeNull();
    expect(sonucOzeti(sonuc.satirlar)).toEqual({
      kanitli: 0,
      eksik: 1,
      celiski: 0,
      izYok: 0,
    });
  });

  it("Luna yoksa bulunamayan kod eksik döner", async () => {
    const fetcher = async (input: string) => kaynakKimligiyle(async () => new Response("{}", { status: 404 }))(input);

    const sonuc = await izle(
      [satir("YOK1302")],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.tedarikciIz?.havuzda).toBe(false);
    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].katalog).toBeNull();
    expect(sonucOzeti(sonuc.satirlar).eksik).toBe(1);
  });

  it("kodu olmayan ve markasi gecmeyen satir eksik bilgi sorar", async () => {
    const fetcher = async (input: string) => kaynakKimligiyle(async () => new Response("{}", { status: 404 }))(input);

    const sonuc = await izle(
      [{ ...satir(""), ad: "Bilinmeyen Ürün" }],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].uyari).toBeUndefined();
    expect(sonucOzeti(sonuc.satirlar).eksik).toBe(1);
  });

  it("Luna yoksa marka ayrımı uyarısı yazılmaz", async () => {
    const fetcher = async (input: string) => kaynakKimligiyle(async () => new Response("{}", { status: 404 }))(input);

    const sonuc = await izle(
      [{ ...satir(""), ad: "Aycenk Gıda Ayçiçek Yağı 1 L" }],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].uyari).toBeUndefined();
  });

  it("Luna yoksa sitemap taraması koşmaz", async () => {
    const fetcher = async () => new Response("{}", { status: 404 });

    const sonuc = await izle(
      [satir("ABC-123")],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].katalog).toBeNull();
  });
});

describe("hedefli arama ve erişim durumu", () => {
  function yanit(veri: unknown, durum = 200) {
    return new Response(JSON.stringify(veri), {
      status: durum,
      headers: { "content-type": "application/json" },
    });
  }

  it("Luna yoksa hedefli kod araması koşmaz", async () => {
    const fetcher = async () => new Response("{}", { status: 404 });

    const sonuc = await izle([satir("GF-777")], "Goldfresh Mutfak", "", {
      fetcher: kaynakKimligiyle(fetcher),
      resolveHost,
    });

    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].katalog).toBeNull();
  });

  it("Luna yoksa erişim hatası üretilmez, satır eksik kalır", async () => {
    const fetcher = async () => {
      throw new Error("ag hatasi");
    };
    const durum = { erisimHatasi: false, sinirDoldu: false };

    const sonuc = await izle([satir("GF-123")], "Goldfresh Mutfak", "", {
      fetcher,
      resolveHost,
      durum,
    });

    expect(durum.erisimHatasi).toBe(false);
    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].uyari).toBeUndefined();
  });

  it("Luna yoksa süre bütçesi işletilmez", async () => {
    let an = 0;
    const fetcher = async () => new Response("{}", { status: 404 });
    const durum = { erisimHatasi: false, sinirDoldu: false };

    const sonuc = await izle([satir("GF-123")], "Goldfresh Mutfak", "", {
      fetcher: kaynakKimligiyle(fetcher),
      resolveHost,
      durum,
      simdi: () => (an += 5000),
      kesifButcesiMs: 1000,
    });

    expect(durum.sinirDoldu).toBe(false);
    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
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

  it("Luna yoksa marka kaynağına gidilmez", async () => {
    const gidilenAlanlar: string[] = [];
    const fetcher = async (input: string) => {
      gidilenAlanlar.push(new URL(input).hostname);
      return new Response("{}", { status: 404 });
    };

    const sonuc = await izle(
      [{ ...satir("GF-123"), marka: "Goldfresh" }],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].katalog).toBeNull();
    expect(gidilenAlanlar).not.toContain("goldfreshmutfak.com");
  });

  it("Luna yoksa marka uyarısı yazılmaz", async () => {
    const fetcher = async (input: string) => kaynakKimligiyle(async () => new Response("{}", { status: 404 }))(input);

    const sonuc = await izle(
      [{ ...satir("GF-999"), marka: "Goldfresh Mutfak" }],
      "Örnek Toptan",
      "https://ornek-toptan.example",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(sonuc.satirlar[0].sonuc).toBe("eksik");
    expect(sonuc.satirlar[0].uyari).toBeUndefined();
  });

  it("Luna yoksa marka araması için ağa çıkılmaz", async () => {
    const gidilenAlanlar: string[] = [];
    const fetcher = async (input: string) => {
      gidilenAlanlar.push(new URL(input).hostname);
      return new Response("{}", { status: 404 });
    };

    await izle(
      [{ ...satir("GF-999"), marka: "Goldfresh" }],
      "Goldfresh Mutfak",
      "",
      { fetcher: kaynakKimligiyle(fetcher), resolveHost },
    );

    expect(gidilenAlanlar).toEqual([]);
  });
});


function gercekPdf(metin = "MODEL: ABC123 Cotton shirt"): Uint8Array {
  const resim = Buffer.alloc(1200 * 1200 * 3);
  for (let i = 0; i < resim.length; i++) resim[i] = (i * 37) % 255;
  const icerik = Buffer.from(`BT /F1 18 Tf 40 700 Td (${metin}) Tj ET q 400 0 0 400 40 250 cm /Im1 Do Q`);
  const nesneler = [
    Buffer.from("<< /Type /Catalog /Pages 2 0 R >>"),
    Buffer.from("<< /Type /Pages /Kids [3 0 R] /Count 1 >>"),
    Buffer.from("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 600 800] /Resources << /Font << /F1 4 0 R >> /XObject << /Im1 5 0 R >> >> /Contents 6 0 R >>"),
    Buffer.from("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"),
    Buffer.concat([Buffer.from(`<< /Type /XObject /Subtype /Image /Width 1200 /Height 1200 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Length ${resim.length} >>\nstream\n`), resim, Buffer.from("\nendstream")]),
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
  it("gercek PDF metni ve 1200px gomulu resmi kalite yoluna tasir", async () => {
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
    expect(kalite.genislik).toBe(1200);
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


describe("ayni modelin assorti katalog eslesmesi", () => {
  const iz = { anahtar: null, firma: "Resmi", alan: "resmi.example", platform: "shopify", izinDurumu: "yok" as const, kaynak: "https://resmi.example", havuzda: false };
  const fetcher = async (input: string) => input.includes("/products.json") ? new Response(JSON.stringify({ products: [{
    title: "Erkek Takim", vendor: "Resmi", handle: "16747", images: [{ src: "https://resmi.example/takim.jpg" }],
    variants: ["M", "L", "XL", "XXL"].map((title) => ({ sku: "16747", title })),
  }] })) : new Response("{}", { status: 404 });
  it("M L XL XXL ayni modelde tek katalog eslesmesi olur", async () => {
    const sonuc = await dinamikUrunIzleriniBul([{ model: "16747", barkod: "", beden: "M/L/XL/XXL" }], iz, { fetcher, resolveHost });
    const hedef = sonuc[0];
    if (!hedef || "celiski" in hedef) throw new Error("Tek model eslesmesi bekleniyordu");
    expect(hedef.urun.ad).toBe("Erkek Takim");
    expect(hedef.varyantlar?.map((v) => v.ad)).toEqual(["M", "L", "XL", "XXL"]);
  });
  it("kaynakta olmayan XS bedeni varmis gibi kabul etmez", async () => {
    expect(await dinamikUrunIzleriniBul([{ model: "16747", barkod: "", beden: "M/XS" }], iz, { fetcher, resolveHost })).toEqual([null]);
  });
  it("ayni kod farkli resmi urun sayfasinda ise hala celiski olur", async () => {
    const farkliFetch = async (input: string) => input.includes("/products.json") ? new Response(JSON.stringify({ products: [
      { title: "Takim A", vendor: "Resmi", handle: "takim-a", variants: [{ sku: "16747", title: "M" }] },
      { title: "Takim B", vendor: "Resmi", handle: "takim-b", variants: [{ sku: "16747", title: "L" }] },
    ] })) : new Response("{}", { status: 404 });
    const sonuc = await dinamikUrunIzleriniBul([{ model: "16747", barkod: "" }], iz, { fetcher: farkliFetch, resolveHost });
    expect(sonuc[0]).toHaveProperty("celiski", true);
  });
});
