import { describe, expect, it } from "vitest";
import sharp from "sharp";
import { adayGorselleriniSec, gorselSecimIstekGovdesi, GORSEL_SECIM_PRESET } from "@/lib/faturaGorselSecimi";
import type { GoruSatiri } from "@/lib/faturaGoru";

const resolveHost = async () => ["8.8.8.8"];

async function fotograf(genislik: number, yukseklik: number, tohum = 1): Promise<Buffer> {
  const gurultu = Buffer.alloc(genislik * yukseklik * 3);
  for (let i = 0; i < gurultu.length; i++) gurultu[i] = (i * 37 + (i >> 5) * 11 + tohum * 29) % 251;
  return sharp(gurultu, { raw: { width: genislik, height: yukseklik, channels: 3 } })
    .jpeg({ quality: 80 })
    .toBuffer();
}

function fetcherIle(haritasi: Record<string, Buffer | null>) {
  return async (input: string) => {
    const govde = haritasi[input];
    if (!govde) return new Response("yok", { status: 404 });
    return new Response(new Uint8Array(govde), { status: 200 });
  };
}

function satir(ek: Partial<GoruSatiri>): GoruSatiri {
  return {
    hamSatir: "ELT1302", model: "ELT1302", ad: "Elit Erkek Fanila", barkod: "",
    varyant: "", beden: "L", marka: "Tutku", adet: 2, birim: "Adet", birimFiyat: 100, tutar: 200,
    okumaGuveni: 0.9, siteSayfa: "https://sehermensucat.com/elt1302", dogrulamaDurumu: "Doğrulandı",
    ...ek,
  };
}

function modelYaniti(secimler: unknown, icerikMetni?: string) {
  return new Response(
    JSON.stringify({
      choices: [{
        message: { content: icerikMetni ?? JSON.stringify({ secimler }) },
        finish_reason: "stop",
      }],
    }),
    { status: 200, headers: { "content-type": "application/json" } },
  );
}

const A = "https://firma.example/urun-on.jpg";
const B = "https://firma.example/urun-arka.jpg";
const C = "https://firma.example/urun-detay.jpg";

async function gorselHaritasi() {
  return {
    [A]: await fotograf(800, 800, 1),
    [B]: await fotograf(800, 800, 2),
    [C]: await fotograf(800, 800, 3),
  };
}

describe("fatura görsel seçimi — OpenRouter kararı", () => {
  it("modelin seçtiği aday ilk sıraya geçer, sıralama kararı uygulanır", async () => {
    const harita = await gorselHaritasi();
    const satirlar = [satir({ siteGorsel: A, siteGorseller: [A, B] })];
    const kararlar: Array<Record<string, unknown>> = [];

    const sonuc = await adayGorselleriniSec({
      satirlar,
      bagimliliklar: {
        fetcher: fetcherIle(harita),
        resolveHost,
        modelCagrisi: async (govde) => {
          kararlar.push(govde);
          return modelYaniti([{ row_id: "1", secilen: 1, sira: [1, 0], red: [] }]);
        },
      },
    });

    expect(kararlar).toHaveLength(1);
    expect(sonuc[0].siteGorseller).toEqual([B, A]);
    expect(sonuc[0].siteGorsel).toBe(B);
  });

  it("ürün fotoğrafı olmayan aday listeden çıkarılır; hepsi elenirse satır görselsiz kalmaz", async () => {
    const harita = await gorselHaritasi();
    const kismi = [satir({ ad: "Kısmi", siteGorsel: A, siteGorseller: [A, B, C] })];
    const kismiSonuc = await adayGorselleriniSec({
      satirlar: kismi,
      bagimliliklar: {
        fetcher: fetcherIle(harita),
        resolveHost,
        modelCagrisi: async () => modelYaniti([{ row_id: "1", secilen: 2, sira: [2], red: [0] }]),
      },
    });
    expect(kismiSonuc[0].siteGorseller).toEqual([C, B]);
    expect(kismiSonuc[0].siteGorsel).toBe(C);

    const tumu = [satir({ ad: "Hepsi", siteGorsel: A, siteGorseller: [A, B] })];
    const tumuSonuc = await adayGorselleriniSec({
      satirlar: tumu,
      bagimliliklar: {
        fetcher: fetcherIle(harita),
        resolveHost,
        modelCagrisi: async () => modelYaniti([{ row_id: "1", secilen: null, sira: [], red: [0, 1] }]),
      },
    });
    expect(tumuSonuc[0].siteGorseller).toEqual([A, B]);
  });

  it("model çağrısı patlarsa satırlar aynen kalır", async () => {
    const harita = await gorselHaritasi();
    const satirlar = [satir({ siteGorsel: A, siteGorseller: [A, B] })];

    const sonuc = await adayGorselleriniSec({
      satirlar,
      bagimliliklar: {
        fetcher: fetcherIle(harita),
        resolveHost,
        modelCagrisi: async () => {
          throw new Error("ag hatasi");
        },
      },
    });

    expect(sonuc).toEqual(satirlar);
    expect(sonuc[0].siteGorsel).toBe(A);
    expect(sonuc[0].siteGorseller).toEqual([A, B]);
  });

  it("anlaşılmaz model cevabında satırlar aynen kalır", async () => {
    const harita = await gorselHaritasi();
    const satirlar = [satir({ siteGorsel: A, siteGorseller: [A, B] })];

    const sonuc = await adayGorselleriniSec({
      satirlar,
      bagimliliklar: {
        fetcher: fetcherIle(harita),
        resolveHost,
        modelCagrisi: async () => modelYaniti([], "bu bir json degil"),
      },
    });

    expect(sonuc).toEqual(satirlar);
  });

  it("güvenli olmayan adaylar modele gitmez, adresleri istek gövdesine sızmaz", async () => {
    const harita = await gorselHaritasi();
    const guvenliDegil = "http://firma.example/guvenli-degil.jpg";
    const ozel = "https://192.168.1.5/ozel-ag.jpg";
    const satirlar = [satir({ siteGorsel: guvenliDegil, siteGorseller: [guvenliDegil, A, ozel] })];
    const govdeler: Array<Record<string, unknown>> = [];

    const sonuc = await adayGorselleriniSec({
      satirlar,
      bagimliliklar: {
        fetcher: fetcherIle(harita),
        resolveHost,
        modelCagrisi: async (govde) => {
          govdeler.push(govde);
          return modelYaniti([{ row_id: "1", secilen: 0, sira: [], red: [] }]);
        },
      },
    });

    expect(govdeler).toHaveLength(1);
    const ham = JSON.stringify(govdeler[0]);
    expect(ham).not.toContain("guvenli-degil");
    expect(ham).not.toContain("192.168");
    const parcalar = (govdeler[0].messages as Array<{ content: Array<Record<string, unknown>> }>)[0].content;
    expect(parcalar.filter((parca) => parca.type === "image_url")).toHaveLength(1);
    expect(String(parcalar[0].text)).toContain('"aday_indeksleri":[0]');
    expect(sonuc[0].siteGorsel).toBe(A);
    expect(sonuc[0].siteGorseller).toEqual([A, guvenliDegil, ozel]);
  });

  it("tek adaylı satırlarda model hiç çağrılmaz", async () => {
    const harita = await gorselHaritasi();
    const satirlar = [satir({ siteGorsel: A, siteGorseller: [A] })];
    let cagri = 0;

    const sonuc = await adayGorselleriniSec({
      satirlar,
      bagimliliklar: {
        fetcher: fetcherIle(harita),
        resolveHost,
        modelCagrisi: async () => {
          cagri++;
          return modelYaniti([]);
        },
      },
    });

    expect(cagri).toBe(0);
    expect(sonuc).toEqual(satirlar);
  });

  it("karar doğru satıra uygulanır, karar verilmeyen satıra dokunulmaz", async () => {
    const harita = await gorselHaritasi();
    const D = "https://firma.example/urun-dorduncu.jpg";
    const tamHarita = { ...harita, [D]: await fotograf(800, 800, 4) };
    const satirlar = [
      satir({ ad: "Bir", siteGorsel: A, siteGorseller: [A, B] }),
      satir({ ad: "Iki", siteGorsel: C, siteGorseller: [C] }),
      satir({ ad: "Uc", siteGorsel: D, siteGorseller: [D, A] }),
    ];

    const sonuc = await adayGorselleriniSec({
      satirlar,
      bagimliliklar: {
        fetcher: fetcherIle(tamHarita),
        resolveHost,
        modelCagrisi: async () => modelYaniti([
          { row_id: "1", secilen: 1, sira: [1, 0], red: [] },
          { row_id: "3", secilen: 1, sira: [], red: [] },
        ]),
      },
    });

    expect(sonuc[0].siteGorseller).toEqual([B, A]);
    expect(sonuc[1].siteGorseller).toEqual([C]);
    expect(sonuc[2].siteGorseller).toEqual([A, D]);
    expect(sonuc[2].siteGorsel).toBe(A);
  });

  it("bilinmeyen satır numarası ve uydurma indeksler sessizce yok sayılır", async () => {
    const harita = await gorselHaritasi();
    const satirlar = [satir({ siteGorsel: A, siteGorseller: [A, B] })];

    const sonuc = await adayGorselleriniSec({
      satirlar,
      bagimliliklar: {
        fetcher: fetcherIle(harita),
        resolveHost,
        modelCagrisi: async () => modelYaniti([
          { row_id: "9", secilen: 0, sira: [0], red: [] },
          { row_id: "1", secilen: 42, sira: [7], red: [3] },
        ]),
      },
    });

    expect(sonuc[0].siteGorseller).toEqual([A, B]);
    expect(sonuc[0].siteGorsel).toBe(A);
  });

  it("istek gövdesi preset adını ve aday görselleri veri adresiyle gönderir", async () => {
    const govde = gorselSecimIstekGovdesi(
      [{ row_id: "1", ad: "Elit Erkek Fanila", marka: "Tutku", aday_indeksleri: [0, 1] }],
      ["data:image/webp;base64,AAA", "data:image/webp;base64,BBB"],
    );

    expect(govde.model).toBe(GORSEL_SECIM_PRESET);
    expect(govde.stream).toBe(true);
    const icerik = (govde.messages as Array<{ content: unknown }>)[0].content as Array<Record<string, unknown>>;
    const gorseller = icerik.filter((parca) => parca.type === "image_url");
    expect(gorseller).toHaveLength(2);
    expect(JSON.stringify(govde)).toContain("Elit Erkek Fanila");
  });
});
