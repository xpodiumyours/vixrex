import { describe, expect, it } from "vitest";
import { katalogOzeti, ureticiUrunuBul } from "@/lib/ureticiKatalog";

// Üretici kataloğu — faturadaki kod, üreticinin kendi yayınladığı ürüne bağlanır.
//
// Kural: eşleşme yalnız barkod veya model kodu birebir tuttuğunda kurulur.
// Ada bakarak tahmin yapılmaz; tutmazsa satır faturadaki hâliyle kalır.

/** Casper'ın gerçek faturasındaki 12 model kodu. */
const FATURA_KODLARI = [
  "ELT1302",
  "ELT1303",
  "ELT1306",
  "ELT2203",
  "ELT2204",
  "TEC0135",
  "TER0101",
  "TER0114",
  "TER0117",
  "TER0125",
  "TER0126",
  "TKC0835",
];

describe("üretici kataloğu", () => {
  it("katalog yüklü ve boş değil", () => {
    const ozet = katalogOzeti();
    expect(ozet.length).toBeGreaterThan(0);
    expect(ozet[0].urun).toBeGreaterThan(200);
  });

  it("gerçek faturadaki 12 kodun hepsi katalogda bulunur", () => {
    const bulunan = FATURA_KODLARI.filter((kod) => ureticiUrunuBul({ model: kod }) !== null);
    expect(bulunan).toHaveLength(FATURA_KODLARI.length);
  });

  it("eşleşen her ürün ürün kartı kuralını geçecek kadar fotoğraf taşır", () => {
    for (const kod of FATURA_KODLARI) {
      const eslesme = ureticiUrunuBul({ model: kod });
      expect(eslesme, kod).not.toBeNull();
      expect(eslesme!.urun.gorseller.length, kod).toBeGreaterThanOrEqual(3);
    }
  });

  it("resmî ad ve marka faturadaki ham addan daha zengin gelir", () => {
    const eslesme = ureticiUrunuBul({ model: "ELT1302" });
    expect(eslesme!.urun.ad).toContain("ELT1302");
    expect(eslesme!.urun.marka).toBeTruthy();
    expect(eslesme!.dayanak).toBe("kod");
  });

  it("model kodu küçük harf veya boşluklu gelse de eşleşir", () => {
    expect(ureticiUrunuBul({ model: " elt1302 " })).not.toBeNull();
    expect(ureticiUrunuBul({ model: "elt-1302" })).not.toBeNull();
  });

  it("barkod eşleşmesi model kodundan önce gelir", () => {
    const koddan = ureticiUrunuBul({ model: "ELT1302" });
    const barkod = koddan!.urun.barkod;
    expect(barkod.length).toBeGreaterThanOrEqual(8);

    const barkoddan = ureticiUrunuBul({ model: "TER0101", barkod });
    expect(barkoddan!.dayanak).toBe("barkod");
    expect(barkoddan!.urun.kod).toBe("ELT1302");
  });

  it("katalogda olmayan kod için tahmin üretmez", () => {
    expect(ureticiUrunuBul({ model: "ZZZ9999" })).toBeNull();
    expect(ureticiUrunuBul({ model: "", barkod: "" })).toBeNull();
    expect(ureticiUrunuBul({ model: null, barkod: null })).toBeNull();
  });

  it("çok kısa kod yanlışlıkla eşleşmez", () => {
    expect(ureticiUrunuBul({ model: "ELT" })).toBeNull();
  });

  it("izin alınmadan önce firma durumu 'var' değildir", () => {
    const eslesme = ureticiUrunuBul({ model: "ELT1302" });
    expect(eslesme!.firma.izinDurumu).not.toBe("var");
  });
});
