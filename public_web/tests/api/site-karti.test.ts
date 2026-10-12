import { describe, expect, it } from "vitest";
import { siteAdayiniKoru, siteKartiniUygula, type EslesmisFaturaSatiri } from "@/lib/faturaEslestir";

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


describe("C1 - kaynak adayi ile gorsel kanitini ayirma", () => {
  it("urun arastirma adayi kaybolmaz ama goruntu olmadan kanitli ya da yayina hazir sayilmaz", () => {
    const sonuc = siteAdayiniKoru(siteKartiniUygula(satir({
      sonuc: "eksik", katalog: null,
      siteAd: "Elit fanila",
      siteDayanak: "kod",
      siteAciklama: "Pamuklu fanila",
      siteSayfa: "https://firma.example/elt1302",
      siteGorsel: "https://cdn.example/elt1302.jpg",
      sayfaDogrulandi: false,
    })));
    expect(sonuc.sonuc).toBe("eksik");
    expect(sonuc.katalog?.resmiAd).toBe("Elit fanila");
    expect(sonuc.katalog?.kaynak).toBe("https://firma.example/elt1302");
    expect(sonuc.katalog?.gorseller).toEqual(["https://cdn.example/elt1302.jpg"]);
    expect(sonuc.katalog?.gorselAdaylari).toEqual(["https://cdn.example/elt1302.jpg"]);
    expect(sonuc.uyari).toContain("fotoğraf kartta");
  });

  it("resmi sayfasi veya uretici kodu kaniti olmayan model iddiasini aday diye bile eklemez", () => {
    const ham = satir({ sonuc: "eksik", katalog: null, siteAd: "Benzer", siteSayfa: "https://firma.example/benzer" });
    expect(siteAdayiniKoru(ham).katalog).toBeNull();
    expect(siteAdayiniKoru({ ...ham, siteDayanak: "kod", siteSayfa: "http://firma.example/benzer" }).katalog).toBeNull();
  });

  it("kanitlanmis fotografli urunu asla aday seviyesine dusurmez", () => {
    const kanitli = satir({ sonuc: "kanitli" });
    expect(siteAdayiniKoru(kanitli)).toBe(kanitli);
  });
});

describe("site kartı", () => {
  it("firma kaynağındaki gerçek görsel ve açıklama satırı kanıtlı yapar", () => {
    const sonuc = siteKartiniUygula(satir({
      siteAd: "Elit fanila",
      siteEslesti: true,
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
