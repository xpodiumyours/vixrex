import { describe, expect, it } from "vitest";
import { siteAdayiniKoru, siteKartiniUygula, eslesmeyenSatir } from "@/lib/faturaEslestir";
import { satirKanitKayitlari } from "@/lib/faturaIslemKaydi";

const ORTAK = {
  model: "ELT1302",
  ad: "Elit fanila",
  barkod: "",
  varyant: "",
  beden: "",
  adet: 2,
  alisBirimFiyat: 137,
  satirToplam: 274,
  guven: 0.9,
  siteAd: "Elit fanila",
  siteDayanak: "kod" as const,
  siteAciklama: "Pamuklu fanila",
  siteSayfa: "https://firma.example/elt1302",
  siteGorsel: "https://cdn.example/elt1302.jpg",
};

describe("C1 kaynak adayinin kanit gucu", () => {
  it("gorsel kaniti olmayan urun adayi kaybolmaz fakat guclu kanit veya yayin etiketi olamaz", () => {
    const satir = siteAdayiniKoru(siteKartiniUygula(eslesmeyenSatir(ORTAK)));
    expect(satir.sonuc).toBe("eksik");
    expect(satir.katalog?.kaynak).toBe(ORTAK.siteSayfa);
    expect(satir.katalog?.gorseller).toEqual([ORTAK.siteGorsel]);
    const kayit = satirKanitKayitlari("satir-1", satir, "");
    expect(kayit.kanit).toHaveLength(2);
    expect(kayit.kanit[0].strength).toBe("partial");
    expect(kayit.kanit[1].strength).toBe("partial");
    expect(kayit.aday).toHaveLength(1);
  });

  it("gercek sayfa ve gorsel uyumu olan satirin guclu kanit derecesi korunur", () => {
    const satir = siteKartiniUygula(eslesmeyenSatir({
      ...ORTAK,
      sayfaDogrulandi: true,
      siteFotografKaniti: {
        kaynakSayfa: ORTAK.siteSayfa,
        kaynakGorsel: ORTAK.siteGorsel,
        kaynakAlintisi: '<img src="https://cdn.example/elt1302.jpg" alt="Elit fanila">',
        lunaGerekcesi: "Renk ve ürün çeşidi aynı.",
      },
    }));
    expect(satir.sonuc).toBe("kanitli");
    expect(satirKanitKayitlari("satir-1", satir, "").kanit.map((x) => x.strength))
      .toEqual(["strong", "strong"]);
  });
});
