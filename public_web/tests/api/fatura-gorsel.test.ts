import { describe, expect, it } from "vitest";
import sharp from "sharp";
import { kartaGirecekGorsel, kaynakGorseliniDogrula, kaynakGorselleriniHazirla, urunSayfasindaGorselKaniti } from "@/lib/faturaGorsel";

const resolveHost = async () => ["8.8.8.8"];

async function fotograf(genislik: number, yukseklik: number): Promise<Buffer> {
  const gurultu = Buffer.alloc(genislik * yukseklik * 3);
  for (let i = 0; i < gurultu.length; i++) gurultu[i] = (i * 37 + (i >> 5) * 11) % 251;
  return sharp(gurultu, { raw: { width: genislik, height: yukseklik, channels: 3 } })
    .jpeg({ quality: 80 })
    .toBuffer();
}

async function duzRenk(genislik: number, yukseklik: number): Promise<Buffer> {
  return sharp({
    create: { width: genislik, height: yukseklik, channels: 3, background: { r: 255, g: 255, b: 255 } },
  })
    .jpeg()
    .toBuffer();
}

function fetcherIle(haritasi: Record<string, { govde: Buffer | string; durum?: number }>) {
  return async (input: string) => {
    const kayit = haritasi[input];
    if (!kayit) return new Response("yok", { status: 404 });
    return new Response(new Uint8Array(Buffer.from(kayit.govde)), { status: kayit.durum ?? 200 });
  };
}

describe("kaynak görseli doğrulama", () => {
  it("açılan, yeterince büyük gerçek fotoğrafı kabul eder", async () => {
    const adres = "https://firma.example/urun.jpg";
    const sonuc = await kaynakGorseliniDogrula(adres, {
      fetcher: fetcherIle({ [adres]: { govde: await fotograf(1200, 1200) } }),
      resolveHost,
    });

    expect(sonuc.tamam).toBe(true);
    expect(sonuc.genislik).toBe(1200);
  });

  it("kırık bağlantı, küçük görsel, boş görsel ve logo ürün fotoğrafı sayılmaz", async () => {
    const kirik = "https://firma.example/yok.jpg";
    const kucuk = "https://firma.example/kucuk.jpg";
    const bos = "https://firma.example/beyaz.jpg";
    const logo = "https://firma.example/assets/logo.jpg";
    const fetcher = fetcherIle({
      [kucuk]: { govde: await fotograf(200, 200) },
      [bos]: { govde: await duzRenk(1200, 1200) },
      [logo]: { govde: await fotograf(900, 900) },
    });

    expect((await kaynakGorseliniDogrula(kirik, { fetcher, resolveHost })).sebep).toBe("acilmadi");
    expect((await kaynakGorseliniDogrula(kucuk, { fetcher, resolveHost })).sebep).toBe("cok-kucuk");
    expect((await kaynakGorseliniDogrula(bos, { fetcher, resolveHost })).sebep).toBe("bos");
    expect((await kaynakGorseliniDogrula(logo, { fetcher, resolveHost })).sebep).toBe(
      "logo-veya-yer-tutucu",
    );
  });

  it("görsel olmayan içerik ve çok geniş banner reddedilir", async () => {
    const html = "https://firma.example/sayfa.jpg";
    const banner = "https://firma.example/kapak.jpg";
    const fetcher = fetcherIle({
      [html]: { govde: "<html>merhaba dunya bu bir gorsel degil</html>" },
      [banner]: { govde: await fotograf(4800, 1200) },
    });

    expect((await kaynakGorseliniDogrula(html, { fetcher, resolveHost })).sebep).toBe("gorsel-degil");
    expect((await kaynakGorseliniDogrula(banner, { fetcher, resolveHost })).sebep).toBe(
      "urun-fotografi-degil",
    );
  });

  it("ağ hatası 'erişilemedi' olur; içerik hatasıyla karıştırılmaz", async () => {
    const sonuc = await kaynakGorseliniDogrula("https://firma.example/a.jpg", {
      fetcher: async () => {
        throw new Error("ag");
      },
      resolveHost,
    });

    expect(sonuc.sebep).toBe("erisilemedi");
  });

  it("küçük, boş, logo ve açılamayan adres karttan düşer", async () => {
    const buyuk = "https://firma.example/buyuk.jpg";
    const kucuk = "https://firma.example/kucuk.jpg";
    const kapali = "https://firma.example/kapali.jpg";
    const fetcher = fetcherIle({
      [buyuk]: { govde: await fotograf(1200, 1200) },
      [kucuk]: { govde: await fotograf(200, 200) },
    });
    const bag = { fetcher, resolveHost };
    expect(await kartaGirecekGorsel(buyuk, bag)).toBe(buyuk);
    expect(await kartaGirecekGorsel(kucuk, bag)).toBe("");
    expect(await kartaGirecekGorsel(kapali, bag)).toBe("");
  });
});


describe("resmî ürün sayfasından fotoğraf ve varyant kanıtı", () => {
  const kaynak = "https://firma.example/urun/siyah";
  const gorsel = "https://cdn.example/siyah.jpg";
  const html = (metin: string) => new Response("<html><body>" + metin + "</body></html>", {
    status: 200, headers: { "content-type": "text/html" },
  });

  it("sayfa gerçekten bu URL'yi ve ilgili rengi taşıyorsa kanıt döner", async () => {
    const kanit = await urunSayfasindaGorselKaniti(kaynak, gorsel, "Siyah", {
      resolveHost,
      fetcher: async () => html('<img alt="Fanila Siyah" src="' + gorsel + '">'),
    });
    expect(kanit?.kaynakAlintisi).toContain(gorsel);
    expect(kanit?.kaynakAlintisi).toContain("Siyah");
  });

  it("modelin uydurduğu fotoğraf adresi gerçek sayfada yoksa kanıt çıkmaz", async () => {
    const kanit = await urunSayfasindaGorselKaniti(kaynak, gorsel, "Siyah", {
      resolveHost,
      fetcher: async () => html('<img alt="Fanila Siyah" src="https://cdn.example/baska.jpg">'),
    });
    expect(kanit).toBeNull();
  });

  it("fotoğraf doğru sayfada olsa da farklı renk adı bağlıysa kanıt sayılmaz", async () => {
    const kanit = await urunSayfasindaGorselKaniti(kaynak, gorsel, "Siyah", {
      resolveHost,
      fetcher: async () => html('<img alt="Fanila Beyaz" src="' + gorsel + '">'),
    });
    expect(kanit).toBeNull();
  });

  it("doğrulanmayan kaynak site ve görsel dışındaki yönlendirmeyi kabul etmez", async () => {
    const fetcher = async () => new Response("redirect", {
      status: 302, headers: { location: "https://baska.example/urun", "content-type": "text/html" },
    });
    expect(await urunSayfasindaGorselKaniti(kaynak, gorsel, "Siyah", { resolveHost, fetcher })).toBeNull();
  });

  it("HTML değilse ve sayfa aşırı büyükse kanıt uydurmaz", async () => {
    expect(await urunSayfasindaGorselKaniti(kaynak, gorsel, "", {
      resolveHost,
      fetcher: async () => new Response('{"image":"'+gorsel+'"}', {
        headers: { "content-type": "application/json" },
      }),
    })).toBeNull();
    expect(await urunSayfasindaGorselKaniti(kaynak, gorsel, "", {
      resolveHost,
      fetcher: async () => new Response("x", {
        headers: { "content-type": "text/html", "content-length": "9999999" },
      }),
    })).toBeNull();
  });
});

describe("kaynak görsellerini kendi depomuza alma", () => {
  function depo(hataVer = false) {
    const yuklenen: string[] = [];
    return {
      yuklenen,
      admin: {
        storage: {
          from: () => ({
            upload: async (yol: string) => {
              if (hataVer) return { error: { message: "depo hatasi" } };
              yuklenen.push(yol);
              return { error: null };
            },
            getPublicUrl: (yol: string) => ({ data: { publicUrl: `https://depo.example/${yol}` } }),
          }),
        },
      },
    };
  }

  it("doğrulanan görsel depoya yazılır ve kaynağa geri bağlanır; kötü olan atılır", async () => {
    const iyi = "https://firma.example/iyi.jpg";
    const bos = "https://firma.example/bos.jpg";
    const { admin, yuklenen } = depo();

    const sonuc = await kaynakGorselleriniHazirla({
      admin,
      slug: "deneme-vitrin",
      kaynakSayfa: "https://firma.example/urun/16747",
      adaylar: [iyi, bos],
      bagimliliklar: {
        fetcher: fetcherIle({
          [iyi]: { govde: await fotograf(1200, 1200) },
          [bos]: { govde: await duzRenk(1200, 1200) },
        }),
        resolveHost,
      },
    });

    expect(sonuc.gorseller).toHaveLength(1);
    expect(sonuc.gorseller[0].kaynakGorsel).toBe(iyi);
    expect(sonuc.gorseller[0].kaynakSayfa).toBe("https://firma.example/urun/16747");
    expect(sonuc.gorseller[0].url).toContain("https://depo.example/deneme-vitrin/products/fatura/");
    expect(yuklenen).toHaveLength(1);
    expect(sonuc.reddedilenler).toEqual([{ kaynakGorsel: bos, sebep: "bos" }]);
    expect(sonuc.altyapiSorunu).toBe(false);
  });

  it("depo yazma hatası altyapı sorunu sayılır, görsel sessizce kaybolmaz", async () => {
    const iyi = "https://firma.example/iyi.jpg";
    const { admin } = depo(true);

    const sonuc = await kaynakGorselleriniHazirla({
      admin,
      slug: "deneme-vitrin",
      kaynakSayfa: "",
      adaylar: [iyi],
      bagimliliklar: {
        fetcher: fetcherIle({ [iyi]: { govde: await fotograf(1200, 1200) } }),
        resolveHost,
      },
    });

    expect(sonuc.gorseller).toHaveLength(0);
    expect(sonuc.altyapiSorunu).toBe(true);
    expect(sonuc.reddedilenler[0].sebep).toBe("depoya-yazilamadi");
  });
});
