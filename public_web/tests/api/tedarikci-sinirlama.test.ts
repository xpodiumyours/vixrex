import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { faturaSatirlariniEslestir, type HamFaturaSatiri } from "@/lib/faturaEslestir";
import { tedarikciAdiniAyikla } from "@/lib/faturaSatirAyikla";
import { firmaAnahtariniCoz, ureticiUrunuBul } from "@/lib/ureticiKatalog";

const GERCEK_OCR = readFileSync("tests/veri/fis-4-gercek-ocr.txt", "utf8");

function satir(fazla: Partial<HamFaturaSatiri>): HamFaturaSatiri {
  return {
    model: "",
    ad: "",
    barkod: "",
    varyant: "",
    beden: "",
    adet: 1,
    alisBirimFiyat: null,
    satirToplam: null,
    guven: 0.9,
    ...fazla,
  };
}

describe("tedarikçi kimliği eşleştirmeyi sınırlar", () => {
  it("belgede tedarikçi yazmıyorsa boş döner — bu hata değildir", () => {
    // Ölçülen gerçek fatura: "İrsaliye Firma :" alanı boş.
    expect(tedarikciAdiniAyikla(GERCEK_OCR)).toBe("");
  });

  it("belgede tedarikçi yazıyorsa okunur", () => {
    expect(tedarikciAdiniAyikla("İrsaliye Firma : SEHER MENSUCAT SAN. TİC.")).toContain("SEHER");
    expect(tedarikciAdiniAyikla("Firma Ünvanı : Koza İçGiyim")).toBe("Koza İçGiyim");
  });

  it("tedarikçi adı havuzdaki firmaya çözülür", () => {
    expect(firmaAnahtariniCoz("SEHER MENSUCAT SAN. TİC. LTD. ŞTİ.")).toBe("seher-mensucat");
    expect(firmaAnahtariniCoz("sehermensucat.com")).toBe("seher-mensucat");
  });

  it("tanınmayan ad yanlış firmaya kilitlenmez", () => {
    expect(firmaAnahtariniCoz("Bilinmeyen Tekstil")).toBeNull();
    expect(firmaAnahtariniCoz("AB")).toBeNull();
  });

  it("tedarikçi verilince o firmanın kataloğu önce aranır", () => {
    const dogru = ureticiUrunuBul({ model: "ELT1302", firmaAnahtari: "seher-mensucat" });
    expect(dogru?.firma.anahtar).toBe("seher-mensucat");

    // Tedarikçi yanlış verilse bile eşleşme kaybolmaz; yalnız sıra değişir.
    const yine = ureticiUrunuBul({ model: "ELT1302", firmaAnahtari: "kul-gida" });
    expect(yine?.firma.anahtar).toBe("seher-mensucat");
  });

  it("çoğunluktan farklı firmadan gelen satır işaretlenir ve güveni düşer", () => {
    // Bir fatura tek tedarikçiden gelir. Çoğunluk Seher'den geliyorsa,
    // araya karışan başka firma eşleşmesi şüphelidir — aynı kod iki
    // firmada olabilir. Silinmez; işaretlenir ve esnafa sorulur.
    const satirlar = [
      satir({ model: "ELT1302" }),
      satir({ model: "ELT1303" }),
      satir({ model: "ELT1306" }),
      satir({ model: "KP160" }), // Aycenk Gıda kataloğundan
    ];

    const sonuc = faturaSatirlariniEslestir(satirlar);
    expect(sonuc.filter((s) => s.katalog !== null)).toHaveLength(4);

    const yabanci = sonuc[3];
    expect(yabanci.katalog?.firma).toContain("Aycenk");
    expect(yabanci.uyari).toContain("Kontrol et");
    expect(yabanci.guven).toBeLessThanOrEqual(0.5);

    // Çoğunluk satırları dokunulmadan kalır.
    expect(sonuc.slice(0, 3).every((s) => s.uyari === undefined)).toBe(true);
  });

  it("hepsi aynı firmadansa hiçbir satır işaretlenmez", () => {
    const sonuc = faturaSatirlariniEslestir(
      ["ELT1302", "ELT1303", "ELT1306"].map((kod) => satir({ model: kod })),
    );
    expect(sonuc.every((s) => s.uyari === undefined)).toBe(true);
    expect(sonuc.filter((s) => s.katalog !== null)).toHaveLength(3);
  });

});
