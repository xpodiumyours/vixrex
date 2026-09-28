import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  belgeGercegiUyuyorMu,
  belgeOzetiniAyikla,
  hamMetniSatirlaraAyir,
  urunSatirlari,
} from "@/lib/faturaSatirAyikla";

// GERÇEK ölçüm verisi: fis_4_15092026.png fotoğrafı, 2026-09-26'da gerçek
// okuyucuya (Kilo, ücretsiz) verildi; dönen ham metin aynen kaydedildi.
// Uydurma değil — bu yüzden okuma hataları da içinde duruyor.
const GERCEK_OCR = readFileSync("tests/veri/fis-4-gercek-ocr.txt", "utf8");

describe("belge gerçeği — satırlar belgenin toplamıyla karşılaştırılır", () => {
  it("belgenin kendi toplam satırını okur", () => {
    const ozet = belgeOzetiniAyikla(GERCEK_OCR);
    expect(ozet.adet).toBe(75);
    expect(ozet.toplam).toBe(6034);
  });

  it("gerçek fotoğrafta 13 ürün satırı okunur", () => {
    expect(urunSatirlari(hamMetniSatirlaraAyir(GERCEK_OCR))).toHaveLength(13);
  });

  it("birim fiyat ile satır tutarı ayrı ayrı okunur", () => {
    // Gerçek faturada birim fiyat 4 ondalıklı ("137,0000"). Yalnız 2
    // ondalık kabul edilirse satır tutarı alış fiyatı sanılır ve esnafın
    // kartına yanlış maliyet yazılır.
    const ilk = urunSatirlari(hamMetniSatirlaraAyir(GERCEK_OCR))[0];
    expect(ilk.alisBirimFiyat).toBe(137);
    expect(ilk.satirToplam).toBe(274);
  });

  it("okuma eksikse akış durur — tahminle düzeltilmez", () => {
    // Bu gerçek okumada satır sayısı doğru ama adet/tutar eksik çıktı.
    // Kapının görevi tam olarak bunu yakalamak.
    const satirlar = urunSatirlari(hamMetniSatirlaraAyir(GERCEK_OCR));
    const uyum = belgeGercegiUyuyorMu(satirlar, belgeOzetiniAyikla(GERCEK_OCR));

    expect(uyum.uyumlu).toBe(false);
    expect(uyum.belgeAdedi).toBe(75);
    expect(uyum.belgeToplami).toBe(6034);
    expect(uyum.sebep).toContain("tam okunamadı");
    // Ölçülen gerçek: satırlar 71 adet / 5.577 TL veriyor, belge 75 / 6.034
    // yazıyor. Fark buradan görünür.
    expect(uyum.okunanAdet).toBe(71);
    expect(uyum.okunanToplam).toBe(5577);
  });

  it("satırlar belgeyle tutuyorsa geçer", () => {
    const uyum = belgeGercegiUyuyorMu(
      [
        { adet: 2, satirToplam: 274 },
        { adet: 3, satirToplam: 345 },
      ].map((s) => ({ ...s, model: "", ad: "", barkod: "", varyant: "", beden: "", alisBirimFiyat: null, guven: 1 })),
      { adet: 5, toplam: 619 },
    );
    expect(uyum.uyumlu).toBe(true);
    expect(uyum.sebep).toBeNull();
  });

  it("belgenin toplamı hiç okunamadıysa 'doğru' sayılmaz", () => {
    const uyum = belgeGercegiUyuyorMu([], { adet: null, toplam: null });
    expect(uyum.uyumlu).toBe(false);
    expect(uyum.sebep).toContain("okunamadı");
  });
});
