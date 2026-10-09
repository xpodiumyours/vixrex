import { describe, expect, it, vi } from "vitest";
import { siteKartiniUygula, type EslesmisFaturaSatiri } from "@/lib/faturaEslestir";
import { markaSitesiniBul, satirAramaIstegi, satirAramaCevabi } from "@/lib/faturaGoru";

function satir(ek: Partial<EslesmisFaturaSatiri> = {}): EslesmisFaturaSatiri {
  return {
    model: "ELT1302",
    ad: "Elit fanila",
    barkod: "",
    varyant: "",
    beden: "",
    adet: 2,
    alisBirimFiyat: 137,
    satirToplam: 274,
    guven: 1,
    sonuc: "kanitli",
    katalog: {
      firma: "Seher",
      kaynakFirma: "Seher",
      dayanak: "kod",
      izinDurumu: "yok",
      resmiAd: "Hazır listedeki ad",
      marka: "Elit",
      aciklama: "Hazır listedeki açıklama",
      gorseller: ["https://katalog.example/foto.jpg"],
      gorselAdaylari: ["https://katalog.example/foto.jpg"],
      kaynak: "https://katalog.example/urun",
    },
    ...ek,
  };
}

describe("OpenRouter kaynak doğrulama", () => {
  const girdi = { alan: "firma.example", model: "ELT1302", ad: "Elit fanila", barkod: "" };
  const kanitli = (degisiklik: Record<string, unknown> = {}, fetchSayisi = 1) => ({
    status: "completed",
    usage: { server_tool_use: { web_fetch_requests: fetchSayisi } },
    output_text: JSON.stringify({
      eslesti: true,
      urun_adi: "Elit fanila",
      aciklama: "Resmi sitedeki pamuklu fanila",
      kaynak_sayfa: "https://firma.example/elt1302",
      gorsel_adresi: "https://cdn.example/elt1302.jpg",
      kanit: "ELT1302",
      site_kodu: "ELT1302",
      site_barkodu: "",
      site_markasi: "",
      site_rengi: "",
      site_bedeni: "",
      fotograf_rengi_dogrulandi: false,
      eslesme_dayanagi: "kod",
      ...degisiklik,
    }),
  });

  it("tek OpenRouter isteğinde arama, sayfa okuma ve katı çıktı kullanılır", () => {
    const istek = satirAramaIstegi(girdi);
    expect(istek?.model).toBe("openai/gpt-5.6-luna");
    expect(istek?.tools.map((t) => t.type)).toEqual(["openrouter:web_search", "openrouter:web_fetch"]);
    expect(istek?.tools[0].parameters.allowed_domains).toEqual(["firma.example"]);
    expect(istek?.tools[1].parameters.allowed_domains).toEqual(["firma.example"]);
    expect(istek?.text.format.strict).toBe(true);
    expect(JSON.stringify(istek)).not.toContain("image_generation");
  });

  it("kaynağı doğrulanmış ürün fotoğrafı ve açıklaması karta hazırlanır", () => {
    expect(satirAramaCevabi(girdi, kanitli())).toEqual({
      ad: "Elit fanila",
      aciklama: "Resmi sitedeki pamuklu fanila",
      gorsel: "https://cdn.example/elt1302.jpg",
      sayfa: "https://firma.example/elt1302",
      dayanak: "kod",
    });
  });

  it("gerçek web fetch kaydı yoksa modelin eşleşme iddiasına güvenilmez", () => {
    expect(satirAramaCevabi(girdi, kanitli({}, 0))).toBeNull();
    expect(satirAramaCevabi(girdi, { ...kanitli(), usage: undefined })).toBeNull();
  });

  it("yanlış firma, görselsiz veya kanıtsız yanıt reddedilir", () => {
    expect(satirAramaCevabi(girdi, kanitli({ kaynak_sayfa: "https://baska.example/urun" }))).toBeNull();
    expect(satirAramaCevabi(girdi, kanitli({ gorsel_adresi: "" }))).toBeNull();
    expect(satirAramaCevabi(girdi, kanitli({ kanit: "" }))).toBeNull();
    expect(satirAramaCevabi(girdi, kanitli({ eslesti: false }))).toBeNull();
  });

  it("olmayan barkodla barkod eşleştirmesi yapılamaz", () => {
    expect(satirAramaCevabi(girdi, kanitli({ eslesme_dayanagi: "barkod" }))).toBeNull();
  });

  it("kod faturada var ama sitede doğrulanmamışsa kart oluşmaz", () => {
    expect(satirAramaCevabi(girdi, kanitli({ site_kodu: "" }))).toBeNull();
    expect(satirAramaCevabi(girdi, kanitli({ site_kodu: "YABANCI" }))).toBeNull();
  });

  it("barkod ve markadaki çelişki reddedilir", () => {
    const barkodlu = { ...girdi, barkod: "8681128321677" };
    expect(satirAramaCevabi(barkodlu, kanitli({
      site_barkodu: "8681128321678", eslesme_dayanagi: "barkod",
    }))).toBeNull();
    expect(satirAramaCevabi({ ...girdi, marka: "Elit" }, kanitli({
      site_markasi: "Baska",
    }))).toBeNull();
  });

  it("renk, beden ve fotoğrafın varyantı ayrı doğrulanır", () => {
    const renkli = { ...girdi, marka: "Elit", varyant: "Siyah", beden: "L" };
    const dogru = { site_markasi: "Elit", site_rengi: "Siyah", site_bedeni: "L", fotograf_rengi_dogrulandi: true };
    expect(satirAramaCevabi(renkli, kanitli(dogru))?.dayanak).toBe("kod");
    expect(satirAramaCevabi(renkli, kanitli({ ...dogru, site_rengi: "Beyaz" }))).toBeNull();
    expect(satirAramaCevabi(renkli, kanitli({ ...dogru, site_bedeni: "M" }))).toBeNull();
    expect(satirAramaCevabi(renkli, kanitli({ ...dogru, fotograf_rengi_dogrulandi: false }))).toBeNull();
  });

  it("doğrulamanın gerçek dayanağı barkod veya ad olarak saklanır", () => {
    const barkodlu = { ...girdi, barkod: "8681128321677" };
    expect(satirAramaCevabi(barkodlu, kanitli({
      site_barkodu: "8681128321677", eslesme_dayanagi: "barkod",
    }))?.dayanak).toBe("barkod");
    const adsizKod = {
      alan: "firma.example", model: "", barkod: "", ad: "Elit fanila",
      marka: "Elit", varyant: "Siyah",
    };
    expect(satirAramaCevabi(adsizKod, kanitli({
      site_kodu: "", site_markasi: "Elit", site_rengi: "Siyah",
      fotograf_rengi_dogrulandi: true, eslesme_dayanagi: "ad-ve-ozellik",
    }))?.dayanak).toBe("ad");
    expect(satirAramaCevabi({ ...adsizKod, marka: "" }, kanitli({
      site_kodu: "", eslesme_dayanagi: "ad-ve-ozellik",
    }))).toBeNull();
  });

  it("resmî marka sayfası ancak arama ve sayfa okuma kanıtıyla seçilir", async () => {
    const fakeFetch = vi.fn(async (_url: string, init?: RequestInit) => new Response(JSON.stringify({
      status: "completed",
      usage: { server_tool_use: { web_fetch_requests: 1 }, input_tokens: 100, output_tokens: 40 },
      output_text: JSON.stringify({
        marka_adi: "Elit",
        resmi_site: "https://elit.example",
        kanit_sayfa: "https://elit.example/hakkimizda",
        marka_sahibi_dogrulandi: true,
        kanit: "Elit markası bu firmanın üretim markasıdır.",
      }),
    }), { status: 200 }));
    vi.stubEnv("OPENROUTER_API_KEY", "test-okuyucu-anahtari");
    vi.stubGlobal("fetch", fakeFetch);
    try {
      const sonuc = await markaSitesiniBul({
        marka: "Elit", tedarikci: "Örnek Toptan", tedarikciSitesi: "toptan.example",
        model: "ELT1302", ad: "Elit fanila",
      });
      expect(sonuc.alan).toBe("elit.example");
      const body = JSON.parse(String((fakeFetch.mock.calls[0]?.[1] as RequestInit).body));
      expect(body.tools.map((t: { type: string }) => t.type)).toEqual(["openrouter:web_search", "openrouter:web_fetch"]);
      expect(body.text.format.strict).toBe(true);
    } finally {
      vi.unstubAllGlobals();
      vi.unstubAllEnvs();
    }
  });

  it("ürünü satan toptancı sitesi marka sahibi değilse kabul edilmez", async () => {
    const fakeFetch = vi.fn(async () => new Response(JSON.stringify({
      status: "completed",
      usage: { server_tool_use: { web_fetch_requests: 1 } },
      output_text: JSON.stringify({
        marka_adi: "Elit", resmi_site: "https://toptan.example",
        kanit_sayfa: "https://toptan.example/urun",
        marka_sahibi_dogrulandi: false,
        kanit: "Sitede Elit markalı ürün yalnız satılıyor.",
      }),
    }), { status: 200 }));
    vi.stubEnv("OPENROUTER_API_KEY", "test-okuyucu-anahtari");
    vi.stubGlobal("fetch", fakeFetch);
    try {
      expect((await markaSitesiniBul({
        marka: "Elit", tedarikci: "Örnek Toptan", tedarikciSitesi: "toptan.example",
        model: "", ad: "Elit fanila",
      })).alan).toBe("");
    } finally {
      vi.unstubAllGlobals();
      vi.unstubAllEnvs();
    }
  });

  it("yarım veya bozuk cevap kart üretmez", () => {
    expect(satirAramaCevabi(girdi, { ...kanitli(), status: "incomplete" })).toBeNull();
    expect(satirAramaCevabi(girdi, { ...kanitli(), output_text: "{broken" })).toBeNull();
  });
});

describe("site kartı", () => {
  it("firma kaynağındaki gerçek görsel ve açıklama satırı kanıtlı yapar", () => {
    const sonuc = siteKartiniUygula(satir({
      siteAd: "Elit fanila",
      siteAciklama: "Pamuklu fanila",
      siteGorsel: "https://cdn.example/elt1302.jpg",
      siteSayfa: "https://firma.example/elt1302",
      siteFotografKaniti: {
        kaynakSayfa: "https://firma.example/elt1302",
        kaynakGorsel: "https://cdn.example/elt1302.jpg",
        kaynakAlintisi: '<img src="https://cdn.example/elt1302.jpg" alt="Elit fanila">',
        lunaGerekcesi: "Ürün ve renk fotoğrafta uyuşuyor.",
      },
      sayfaDogrulandi: true,
      siteDayanak: "barkod",
    }));
    expect(sonuc.sonuc).toBe("kanitli");
    expect(sonuc.katalog?.resmiAd).toBe("Elit fanila");
    expect(sonuc.katalog?.gorseller).toEqual(["https://cdn.example/elt1302.jpg"]);
    expect(sonuc.katalog?.dayanak).toBe("barkod");
  });

  it("doğrulanmamış sayfa ürün kartını kanıtlı saydırmaz", () => {
    const sonuc = siteKartiniUygula(satir({
      siteAciklama: "Pamuklu fanila",
      siteGorsel: "https://cdn.example/elt1302.jpg",
      siteSayfa: "https://firma.example/elt1302",
      sayfaDogrulandi: false,
    }));
    expect(sonuc.sonuc).toBe("eksik");
  });

  it("eski katalog fikstürü tek başına doğrulama sayılmaz", () => {
    const sonuc = siteKartiniUygula(satir());
    expect(sonuc.sonuc).toBe("eksik");
  });
});
