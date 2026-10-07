import { describe, expect, it } from "vitest";
import { siteKartiniUygula, type EslesmisFaturaSatiri } from "@/lib/faturaEslestir";
import { aramaGorseliniDoldur, type GoruSatiri } from "@/lib/faturaGoru";

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

describe("site kartı", () => {
  it("firmanın sitesindeki fotoğraf ve açıklama kartı kurar", () => {
    const kart = siteKartiniUygula(satir({
      siteAciklama: "Sitede yazan açıklama",
      siteGorsel: "https://firma.example/urun.jpg",
      siteSayfa: "https://firma.example/urun",
    }));
    expect(kart.sonuc).toBe("kanitli");
    expect(kart.katalog?.aciklama).toBe("Sitede yazan açıklama");
    expect(kart.katalog?.gorseller).toEqual(["https://firma.example/urun.jpg"]);
    expect(kart.katalog?.kaynak).toBe("https://firma.example/urun");
  });

  it("site aramasındaki fotoğraf adresini boş satıra yazar", () => {
    const bos: GoruSatiri = {
      hamSatir: "ELT1302",
      model: "ELT1302",
      ad: "Fanila",
      barkod: "",
      varyant: "",
      beden: "",
      marka: "",
      adet: 1,
      birimFiyat: 10,
      tutar: 10,
      siteAciklama: "Sitede yazan açıklama",
      siteGorsel: "",
      siteSayfa: "",
    };
    const dolu = aramaGorseliniDoldur([bos], {
      output: [
        {
          type: "web_search_call",
          results: [
            {
              type: "image_result",
              image_url: "http://firma.example/urun.jpg",
              source_website_url: "https://firma.example/urun",
            },
            {
              type: "image_result",
              image_url: "https://firma.example/urun.jpg",
              source_website_url: "https://firma.example/urun",
            },
          ],
        },
      ],
    });
    expect(dolu[0].siteGorsel).toBe("https://firma.example/urun.jpg");
    expect(dolu[0].siteSayfa).toBe("https://firma.example/urun");
  });

  it("hazır liste tek başına kart sayılmaz", () => {
    const kart = siteKartiniUygula(satir());
    expect(kart.sonuc).toBe("eksik");
    expect(kart.katalog?.aciklama).toBe("");
    expect(kart.katalog?.gorseller).toEqual([]);
  });
});
