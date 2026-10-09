import { describe, expect, it } from "vitest";
import { siteKartiniUygula, type EslesmisFaturaSatiri } from "@/lib/faturaEslestir";
import { satirAramaIstegi, satirAramaCevabi } from "@/lib/faturaGoru";

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
      sayfaDogrulandi: true,
    }));
    expect(sonuc.sonuc).toBe("kanitli");
    expect(sonuc.katalog?.resmiAd).toBe("Elit fanila");
    expect(sonuc.katalog?.gorseller).toEqual(["https://cdn.example/elt1302.jpg"]);
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
