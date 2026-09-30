import { describe, expect, it } from "vitest";
import {
  KART_DURUMLARI,
  durumBilgisi,
  durumGecerliMi,
  kartDegerlendir,
  yayinEksikleri,
  type KartDurumu,
} from "@/lib/faturaKartDurumu";
import { MIN_PRODUCT_IMAGES } from "@/lib/productImagePolicy";
import type { EslesmisFaturaSatiri, KatalogBilgisi } from "@/lib/faturaEslestir";

function katalog(fazla: Partial<KatalogBilgisi> = {}): KatalogBilgisi {
  return {
    firma: "Seher Mensucat",
    kaynakFirma: "Seher Mensucat",
    dayanak: "kod",
    izinDurumu: "var",
    resmiAd: "Elit Erkek Elastan Sıfır Yaka",
    marka: "Elit",
    aciklama: "Pamuklu, nefes alan kumaş.",
    gorseller: [
      "https://sehermensucat.com/1.jpg",
      "https://sehermensucat.com/2.jpg",
      "https://sehermensucat.com/3.jpg",
    ],
    gorselAdaylari: [],
    kaynak: "https://sehermensucat.com/elt1302",
    ...fazla,
  };
}

function satir(fazla: Partial<EslesmisFaturaSatiri> = {}): EslesmisFaturaSatiri {
  return {
    hamSatir: "ELT1302 Elit Erkek 2 137,00 274,00",
    model: "ELT1302",
    ad: "Elit Erkek Elastan",
    barkod: "8681128321677",
    varyant: "Siyah",
    beden: "L",
    adet: 2,
    alisBirimFiyat: 137,
    satirToplam: 274,
    guven: 0.9,
    katalog: katalog(),
    sonuc: "kanitli",
    ...fazla,
  };
}

const ESNAF_GORSELLERI = [
  "https://cdn.vixrex.local/1.jpg",
  "https://cdn.vixrex.local/2.jpg",
  "https://cdn.vixrex.local/3.jpg",
];

describe("kart durumu tek karar kaynagi", () => {
  it("yalniz dort sonuc vardir; besincisi yoktur", () => {
    expect(KART_DURUMLARI).toEqual(["kanitli", "eksik", "celiski", "iz-yok"]);
    for (const durum of KART_DURUMLARI) expect(durumGecerliMi(durum)).toBe(true);
    expect(durumGecerliMi("hazir")).toBe(false);
    expect(durumGecerliMi(undefined)).toBe(false);
  });

  it("kanitli + fiyat + stok onayi + onay + fotograf varsa yayina hazirdir", () => {
    const degerlendirme = kartDegerlendir({
      satir: satir(),
      satisFiyati: 199,
      stok: 18,
      stokOnaylandi: true,
      onaylandi: true,
    });

    expect(degerlendirme.durum).toBe("kanitli");
    expect(degerlendirme.eksikler).toEqual([]);
    expect(degerlendirme.yayinaHazir).toBe(true);
  });

  it("bilgisi tam kart, onaylanmadan da onaylanabilir; onay yayina hazirlik degildir", () => {
    const degerlendirme = kartDegerlendir({
      satir: satir(),
      satisFiyati: 199,
      stok: 18,
      stokOnaylandi: true,
      onaylandi: false,
    });

    expect(degerlendirme.onaylanabilir).toBe(true);
    expect(degerlendirme.bilgiEksikleri).toEqual([]);
    expect(degerlendirme.yayinaHazir).toBe(false);
  });

  it("stok onaylanmamis kart onaylanamaz; toplu onay bunu kendiliginden vermez", () => {
    const degerlendirme = kartDegerlendir({
      satir: satir(),
      satisFiyati: 199,
      stok: 18,
      stokOnaylandi: false,
      onaylandi: false,
    });

    expect(degerlendirme.onaylanabilir).toBe(false);
    expect(degerlendirme.bilgiEksikleri.join(" ")).toContain("Stok onaylanmadı");
  });

  it("tek dogrulanmis urun fotografi karti hazirlamak icin yeterlidir", () => {
    const eksikler = yayinEksikleri({
      durum: "kanitli",
      satisFiyati: 199,
      stok: 18,
      stokOnaylandi: true,
      onaylandi: true,
      gorselSayisi: 1,
    });

    expect(eksikler).toEqual([]);
    expect(
      yayinEksikleri({
        durum: "kanitli",
        satisFiyati: 199,
        stok: 18,
        stokOnaylandi: true,
        onaylandi: true,
        gorselSayisi: 0,
      }).join(" "),
    ).toContain("fotoğraf");
  });

  it("sablonun zorunlu bilgisi (ornegin cinsiyet) girilmedikce kart onaylanamaz", () => {
    const eksik = kartDegerlendir({
      satir: satir(),
      eksikOzellikler: ["Cinsiyet"],
      satisFiyati: 199,
      stok: 18,
      stokOnaylandi: true,
      onaylandi: false,
    });

    expect(eksik.onaylanabilir).toBe(false);
    expect(eksik.bilgiEksikleri).toContain("Cinsiyet bilgisi girilmedi.");

    const tamam = kartDegerlendir({
      satir: satir(),
      eksikOzellikler: [],
      satisFiyati: 199,
      stok: 18,
      stokOnaylandi: true,
      onaylandi: false,
    });
    expect(tamam.onaylanabilir).toBe(true);
  });

  it("faturadaki adet stok yerine gecmez: stok onaylanmadan yayin yok", () => {
    const degerlendirme = kartDegerlendir({
      satir: satir(),
      satisFiyati: 199,
      stok: 2,
      stokOnaylandi: false,
      onaylandi: true,
    });

    expect(degerlendirme.yayinaHazir).toBe(false);
    expect(degerlendirme.eksikler.join(" ")).toContain("Stok onaylanmadı");
  });

  it("kart onaylanmadan ve fiyat girilmeden yayina cikmaz", () => {
    const eksikler = yayinEksikleri({
      durum: "kanitli",
      satisFiyati: null,
      stok: 5,
      stokOnaylandi: true,
      onaylandi: false,
      gorselSayisi: MIN_PRODUCT_IMAGES,
    });

    expect(eksikler).toContain("Satış fiyatı girilmedi.");
    expect(eksikler).toContain("Kart onaylanmadı.");
  });

  it("kanitli olmayan satirdan kart yayina cikmaz", () => {
    for (const durum of ["eksik", "celiski", "iz-yok"] as KartDurumu[]) {
      const degerlendirme = kartDegerlendir({
        satir: satir({ sonuc: durum, katalog: null }),
        satisFiyati: 199,
        stok: 5,
        stokOnaylandi: true,
        onaylandi: true,
        esnafGorselleri: ESNAF_GORSELLERI,
      });

      expect(degerlendirme.yayinaHazir).toBe(false);
      expect(degerlendirme.eksikler.join(" ")).toContain("kanıtlı değil");
    }
  });

  it("gecersiz stok adedi kabul edilmez", () => {
    const eksikler = yayinEksikleri({
      durum: "kanitli",
      satisFiyati: 10,
      stok: -1,
      stokOnaylandi: true,
      onaylandi: true,
      gorselSayisi: MIN_PRODUCT_IMAGES,
    });
    expect(eksikler).toContain("Stok adedi geçersiz.");
  });

  it("izin yoksa ureticinin fotografi karta hicbir sekilde girmez", () => {
    const izinsiz = satir({
      katalog: katalog({
        izinDurumu: "yok",
        gorseller: [],
        gorselAdaylari: ["https://sehermensucat.com/1.jpg"],
      }),
    });

    // Esnaf kendi fotografini eklemediyse kart yayina cikmaz.
    const esnafsiz = kartDegerlendir({
      satir: izinsiz,
      satisFiyati: 199,
      stok: 2,
      stokOnaylandi: true,
      onaylandi: true,
    });
    expect(esnafsiz.gorseller).toEqual([]);
    expect(esnafsiz.yayinaHazir).toBe(false);

    // Kendi fotograflarini eklediyse uretici fotografi yine de karta girmez.
    const esnafli = kartDegerlendir({
      satir: izinsiz,
      satisFiyati: 199,
      stok: 2,
      stokOnaylandi: true,
      onaylandi: true,
      esnafGorselleri: ESNAF_GORSELLERI,
    });
    expect(esnafli.gorseller).toEqual(ESNAF_GORSELLERI);
    expect(esnafli.gorseller).not.toContain("https://sehermensucat.com/1.jpg");
    expect(esnafli.yayinaHazir).toBe(true);
  });

  it("izni bekleyen gorsel de kullanilamaz — resmi sitede gorunmek izin degildir", () => {
    const bekleyen = satir({
      katalog: katalog({
        izinDurumu: "bekliyor",
        gorseller: [],
        gorselAdaylari: ["https://sehermensucat.com/1.jpg"],
      }),
    });

    const degerlendirme = kartDegerlendir({
      satir: bekleyen,
      satisFiyati: 199,
      stok: 2,
      stokOnaylandi: true,
      onaylandi: true,
    });
    expect(degerlendirme.gorseller).toEqual([]);
    expect(degerlendirme.yayinaHazir).toBe(false);
  });

  it("celiski halinde adaylar esnafa acikca gosterilir", () => {
    const bilgi = durumBilgisi(
      satir({
        sonuc: "celiski",
        katalog: null,
        celiski: {
          dayanak: "barkod",
          adaylar: [
            { ad: "Tutku Erkek Atlet Siyah L", kaynak: "https://sehermensucat.com/a" },
            { ad: "Tutku Erkek Atlet Siyah XL", kaynak: "https://sehermensucat.com/b" },
          ],
        },
      }),
    );

    expect(bilgi.etiket).toBe("Çelişki");
    expect(bilgi.detay).toContain("barkod");
    expect(bilgi.adaylar).toHaveLength(2);
  });

  it("iz bulunamayan satirda tahmin yapilmadigi soylenir", () => {
    const bilgi = durumBilgisi(satir({ sonuc: "iz-yok", katalog: null }));
    expect(bilgi.etiket).toBe("İz bulunamadı");
    expect(bilgi.detay).toContain("Tahmin yapılmadı");
    expect(bilgi.adaylar).toEqual([]);
  });

  it("eksik satirda somut uyari gosterilir", () => {
    const bilgi = durumBilgisi(
      satir({ sonuc: "eksik", katalog: null, uyari: "Faturadaki ad okunamadı." }),
    );
    expect(bilgi.etiket).toBe("Eksik bilgi");
    expect(bilgi.detay).toBe("Faturadaki ad okunamadı.");
  });
});
