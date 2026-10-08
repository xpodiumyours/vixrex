import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { tedarikciAdiniAyikla } from "@/lib/faturaSatirAyikla";
import { firmaAnahtariniCoz, ureticiUrunuBul } from "@/lib/ureticiKatalog";

const GERCEK_OCR = readFileSync("tests/veri/fis-4-gercek-ocr.txt", "utf8");

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

});
