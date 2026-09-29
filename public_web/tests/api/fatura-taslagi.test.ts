import { describe, expect, it } from "vitest";
import {
  FATURA_TASLAK_KAYNAGI,
  faturaTaslaklari,
  satirdanFaturaTaslagi,
} from "@/lib/faturaTaslagi";
import type { EslesmisFaturaSatiri, KatalogBilgisi } from "@/lib/faturaEslestir";

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
    katalog: null,
    sonuc: "eksik",
    ...fazla,
  };
}

function katalog(fazla: Partial<KatalogBilgisi> = {}): KatalogBilgisi {
  return {
    firma: "Seher Mensucat",
    kaynakFirma: "Seher Mensucat",
    dayanak: "kod",
    izinDurumu: "var",
    resmiAd: "Elit Erkek Elastan Sıfır Yaka",
    marka: "Elit",
    aciklama: "Pamuklu, nefes alan kumaş.",
    gorseller: ["https://sehermensucat.com/elt1302-1.jpg", "https://sehermensucat.com/elt1302-2.jpg"],
    gorselAdaylari: ["https://sehermensucat.com/elt1302-1.jpg"],
    kaynak: "https://sehermensucat.com/elt1302",
    ...fazla,
  };
}

describe("faturadan taslak urun karti", () => {
  it("kanitli satirdan resmi adi, markayi, barkodu ve kaynagi taslaga baglar", () => {
    const taslak = satirdanFaturaTaslagi(satir({ sonuc: "kanitli", katalog: katalog() }), "is-1");

    expect(taslak).not.toBeNull();
    expect(taslak?.name).toBe("Elit Erkek Elastan Sıfır Yaka");
    expect(taslak?.brand).toBe("Elit");
    expect(taslak?.barcode).toBe("8681128321677");
    expect(taslak?.model).toBe("ELT1302");
    expect(taslak?.kaynak).toBe("https://sehermensucat.com/elt1302");
    expect(taslak?.izinDurumu).toBe("var");
    expect(taslak?.sonuc).toBe("kanitli");
    expect(taslak?.islemKimligi).toBe("is-1");
    expect(taslak?.sourceType).toBe(FATURA_TASLAK_KAYNAGI);
  });

  it("hicbir taslak kendiliginden onayli veya gorunur olmaz", () => {
    const taslak = satirdanFaturaTaslagi(satir({ sonuc: "kanitli", katalog: katalog() }));

    expect(taslak?.ownerApproved).toBe(false);
    expect(taslak?.isVisible).toBe(false);
  });

  it("izin yoksa tüketici kartina hicbir uretici fotografi gecmez, aday incelemede kalir", () => {
    const taslak = satirdanFaturaTaslagi(
      satir({
        sonuc: "kanitli",
        katalog: katalog({
          izinDurumu: "yok",
          gorseller: [],
          gorselAdaylari: ["https://sehermensucat.com/elt1302-1.jpg"],
        }),
      }),
    );

    expect(taslak?.imageUrls).toEqual([]);
    expect(taslak?.gorselAdaylari).toEqual(["https://sehermensucat.com/elt1302-1.jpg"]);
    expect(taslak?.izinDurumu).toBe("yok");
  });

  it("kanit olmayan satirdan kart uretilmez: eksik, celiski ve iz-yok uydurulmaz", () => {
    for (const sonuc of ["eksik", "celiski", "iz-yok"] as const) {
      expect(satirdanFaturaTaslagi(satir({ sonuc, katalog: null }))).toBeNull();
    }
    expect(faturaTaslaklari([satir({ sonuc: "eksik" }), satir({ sonuc: "celiski" })])).toEqual([]);
  });

  it("resmi ad yoksa faturadaki ad kullanilir, ikisi de yoksa kart uretilmez", () => {
    const adsiz = satirdanFaturaTaslagi(
      satir({ sonuc: "kanitli", katalog: katalog({ resmiAd: "" }) }),
    );
    expect(adsiz?.name).toBe("Elit Erkek Elastan");

    const bos = satirdanFaturaTaslagi(
      satir({ ad: "", sonuc: "kanitli", katalog: katalog({ resmiAd: "" }) }),
    );
    expect(bos).toBeNull();
  });

  it("barkod yoksa model kodu kimlik olarak taslaga tasinir", () => {
    const taslak = satirdanFaturaTaslagi(
      satir({ barkod: "", sonuc: "kanitli", katalog: katalog() }),
    );
    expect(taslak?.barcode).toBe("ELT1302");
  });

  it("karisik satir listesinden yalniz kanitli olanlar kart olur", () => {
    const taslaklar = faturaTaslaklari(
      [
        satir({ sonuc: "kanitli", katalog: katalog() }),
        satir({ sonuc: "celiski" }),
        satir({ sonuc: "iz-yok" }),
        satir({ sonuc: "kanitli", katalog: katalog({ kaynak: "https://sehermensucat.com/elt2" }) }),
      ],
      "is-9",
    );

    expect(taslaklar).toHaveLength(2);
    expect(taslaklar.map((taslak) => taslak.kaynak)).toEqual([
      "https://sehermensucat.com/elt1302",
      "https://sehermensucat.com/elt2",
    ]);
    expect(taslaklar.every((taslak) => taslak.islemKimligi === "is-9")).toBe(true);
    expect(taslaklar.every((taslak) => taslak.isVisible === false)).toBe(true);
  });
});
