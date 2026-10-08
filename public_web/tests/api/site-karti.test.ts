import { describe, expect, it } from "vitest";
import { siteKartiniUygula, type EslesmisFaturaSatiri } from "@/lib/faturaEslestir";
import { satiraAitAramaGorseli } from "@/lib/faturaGoru";

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
      sayfaDogrulandi: true,
    }));
    expect(kart.sonuc).toBe("kanitli");
    expect(kart.katalog?.aciklama).toBe("Sitede yazan açıklama");
    expect(kart.katalog?.gorseller).toEqual(["https://firma.example/urun.jpg"]);
    expect(kart.katalog?.kaynak).toBe("https://firma.example/urun");
  });

  it("arama resmi yalnız kilitlenen firmanın sayfasından alınır", () => {
    const govde = {
      output: [
        {
          type: "web_search_call",
          results: [
            {
              type: "image_result",
              image_url: "https://baska.example/urun.jpg",
              source_website_url: "https://baska.example/urun",
            },
            {
              type: "image_result",
              image_url: "http://firma.example/urun.jpg",
              source_website_url: "https://firma.example/urun",
            },
            {
              type: "image_result",
              image_url: "https://cdn.example/urun.jpg",
              source_website_url: "https://firma.example/urun",
            },
          ],
        },
      ],
    };
    expect(satiraAitAramaGorseli("firma.example", govde)).toEqual({
      gorsel: "https://cdn.example/urun.jpg",
      sayfa: "https://firma.example/urun",
    });
    expect(satiraAitAramaGorseli("sehermensucat.com", govde)).toBeNull();
  });

  it("arama kaydındaki firma sayfası fotoğrafsız da satıra bağlanır", () => {
    const govde = {
      output: [
        {
          type: "message",
          content: [
            {
              type: "output_text",
              text: "bulundu",
              annotations: [
                { type: "url_citation", url: "https://baska.example/urun" },
                { type: "url_citation", url: "https://firma.example/elt1302" },
              ],
            },
          ],
        },
      ],
    };
    expect(satiraAitAramaGorseli("firma.example", govde)).toEqual({
      gorsel: "",
      sayfa: "https://firma.example/elt1302",
    });
    const icIce = {
      output: [{
        type: "message",
        content: [{
          type: "output_text",
          text: "bulundu",
          annotations: [{
            type: "url_citation",
            url_citation: { url: "https://firma.example/elt1302" },
          }],
        }],
      }],
    };
    expect(satiraAitAramaGorseli("firma.example", icIce)).toEqual({
      gorsel: "",
      sayfa: "https://firma.example/elt1302",
    });
  });

  it("sayfası doğrulanmamış site metni kart kurmaz", () => {
    const kart = siteKartiniUygula(satir({
      siteAciklama: "Sitede yazan açıklama",
      siteGorsel: "https://firma.example/urun.jpg",
      siteSayfa: "https://firma.example/urun",
    }));
    expect(kart.sonuc).toBe("eksik");
    expect(kart.katalog?.gorseller).toEqual([]);
  });

  it("hazır liste tek başına kart sayılmaz", () => {
    const kart = siteKartiniUygula(satir());
    expect(kart.sonuc).toBe("eksik");
    expect(kart.katalog?.aciklama).toBe("");
    expect(kart.katalog?.gorseller).toEqual([]);
  });
});
