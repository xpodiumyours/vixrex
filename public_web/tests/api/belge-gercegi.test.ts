import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  belgeGercegiUyuyorMu,
  belgeVergiToplamiUyuyorMu,
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
        { adet: 2, satirToplam: 274, alisBirimFiyat: 137 },
        { adet: 3, satirToplam: 345, alisBirimFiyat: 115 },
      ].map((s) => ({ ...s, model: "", ad: "", barkod: "", varyant: "", beden: "", guven: 1 })),
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
  it("genel toplam tutsa bile ürün hesabı yanlışsa durur", () => {
    const satirlar = [
      { adet: 1, alisBirimFiyat: 100, satirToplam: 200 },
      { adet: 1, alisBirimFiyat: 200, satirToplam: 100 },
    ].map((s) => ({ ...s, model: "K", ad: "Ürün", barkod: "", varyant: "", beden: "", guven: 1 }));
    const sonuc = belgeGercegiUyuyorMu(satirlar, { adet: 2, toplam: 300 });
    expect(sonuc.uyumlu).toBe(false);
    expect(sonuc.sebep).toContain("miktar × birim fiyat hesabı tutmuyor");
  });

  it("eksik fiyat veya adet yok sayılmaz", () => {
    const satirlar = [
      { adet: 2, alisBirimFiyat: null, satirToplam: 0 },
      { adet: null, alisBirimFiyat: 100, satirToplam: 0 },
    ].map((s) => ({ ...s, model: "K", ad: "Ürün", barkod: "", varyant: "", beden: "", guven: 1 }));
    const sonuc = belgeGercegiUyuyorMu(satirlar, { adet: 2, toplam: 0 });
    expect(sonuc.uyumlu).toBe(false);
    expect(sonuc.sebep).toContain("1. ürünün miktarı veya fiyatı okunamadı");
    expect(sonuc.sebep).toContain("2. ürünün miktarı veya fiyatı okunamadı");
  });

  it("dört ondalıklı alış fiyatında kuruş toleransı geçerlidir", () => {
    const satir = { model: "K", ad: "Ürün", barkod: "", varyant: "", beden: "",
      adet: 3, alisBirimFiyat: 19.995, satirToplam: 59.99, guven: 1 };
    expect(belgeGercegiUyuyorMu([satir], { adet: 3, toplam: 59.99 }).uyumlu).toBe(true);
  });

  it("farkli birimlerin miktarini toplamaz; para ve satir hesaplarini ayrica dogrular", () => {
    const urun = (adet: number, birim: string, fiyat: number) => ({
      model: "K", ad: "Ürün", barkod: "", varyant: "", beden: "",
      adet, birim, alisBirimFiyat: fiyat, satirToplam: adet * fiyat, guven: 1,
    });
    const sonuc = belgeGercegiUyuyorMu([urun(2.5, "KG", 100), urun(3, "ADET", 50)],
      { adet: 9, toplam: 400 });
    expect(sonuc.uyumlu).toBe(true);
    expect(sonuc.adetKarsilastirildi).toBe(false);
    const eksikTutar = belgeGercegiUyuyorMu([urun(2.5, "KG", 100), urun(3, "ADET", 50)],
      { adet: 9, toplam: 410 });
    expect(eksikTutar.uyumlu).toBe(false);
  });

  it("ad ve adet ayni satis birimi kabul edilir", () => {
    const urun = (birim: string) => ({
      model: "K", ad: "Ürün", barkod: "", varyant: "", beden: "", birim,
      adet: 1, alisBirimFiyat: 20, satirToplam: 20, guven: 1,
    });
    const sonuc = belgeGercegiUyuyorMu([urun("Ad."), urun("ADET")], { adet: 2, toplam: 40 });
    expect(sonuc.uyumlu).toBe(true);
    expect(sonuc.adetKarsilastirildi).toBe(true);
  });

  it("mal bedeli KDV indirim ve odenecek tutar uyuşmazsa reddeder", () => {
    const dogru = belgeVergiToplamiUyuyorMu({
      malBedeli: 200, kdvTutari: 20, indirimTutari: 10, odenecekToplam: 210,
    });
    expect(dogru).toMatchObject({ uyumlu: true, denetlendi: true });
    // Önceki kusur: "mal bedeli" KDV dahilmiş gibi alternatif sonuç da kabul ediliyordu.
    // UBL'de vergi hariç toplam ile ödenecek tutar aynı alan değildir.
    const sahteVergiDahil = belgeVergiToplamiUyuyorMu({
      malBedeli: 200, kdvTutari: 20, indirimTutari: 0, odenecekToplam: 200,
    });
    expect(sahteVergiDahil.uyumlu).toBe(false);
    expect(sahteVergiDahil.denetlendi).toBe(true);
    const yanlis = belgeVergiToplamiUyuyorMu({
      malBedeli: 200, kdvTutari: 20, indirimTutari: 10, odenecekToplam: 240,
    });
    expect(yanlis.uyumlu).toBe(false);
    expect(yanlis.sebep).toContain("KDV");
    const eksik = belgeVergiToplamiUyuyorMu({
      malBedeli: 200, kdvTutari: null, indirimTutari: 10, odenecekToplam: 210,
    });
    expect(eksik).toMatchObject({ uyumlu: true, denetlendi: false });
  });

});
