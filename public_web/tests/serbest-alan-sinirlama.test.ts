import { describe, expect, it } from "vitest";
import { VIXREX_NIYET_SOZLUGU } from "@/lib/vixrexNiyetSozlugu";
import { extractVixrexValue } from "@/lib/vixrexValueExtractor";
import { resolveVixrexIntentsAll } from "@/lib/vixrexIntentResolver";

// 2026-09-03 (Casper canlıda buldu, kiralık-kafe vitrini): "İşletme Adı"
// kutusuna "işletme adım Konak Kafe, whatsapp numaram 0542 180 25 73" gibi
// zengin bir cümle yazılınca, isim alanı whatsapp numarasını da yutuyordu
// ("KONAK KAFE 05421802573"). Kök sebep serbest metin alanlarının (isim,
// adres gibi) "eş-anlamdan sonra cümlenin SONUNA kadar her şeyi al" mantığı
// — başka bir alana ait ipucuyla nerede durması gerektiğini bilmiyordu.
// Bu dosya o sınırı kilitler.
const isletme = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === "isletmeAdi")!;
const whatsapp = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === "whatsapp")!;
const adres = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === "adres")!;

describe("Serbest metin alanları — başka alana ait ipucunda durur", () => {
  it("Casper'ın gerçek örneği: işletme adı whatsapp'ı yutmaz", () => {
    const cumle = "işletme adım Konak Kafe, whatsapp numaram 0542 180 25 73";
    expect(extractVixrexValue(cumle, isletme)).toBe("Konak Kafe");
    expect(extractVixrexValue(cumle, whatsapp)).toBe("0542 180 25 73");
  });

  it("3. tekil iyelik hâliyle de (işletme adı) aynı sonuç", () => {
    const cumle = "işletme adı Konak Kafe, whatsapp numaram 0542 180 25 73";
    expect(extractVixrexValue(cumle, isletme)).toBe("Konak Kafe");
  });

  it("adres de aynı şekilde whatsapp'tan önce kesilir", () => {
    const cumle = "adresimiz Atatürk Cad. No:24 Kadıköy, whatsapp numaram 0542 180 25 73";
    expect(extractVixrexValue(cumle, adres)).toBe("Atatürk Cad. No:24 Kadıköy");
  });

  it("resolveVixrexIntentsAll ile uçtan uca: iki alan da doğru alana gider", () => {
    const cumle = "işletme adım Konak Kafe, whatsapp numaram 0542 180 25 73";
    const bulunanlar = resolveVixrexIntentsAll(cumle);
    expect(bulunanlar.map((a) => a.anahtar).sort()).toEqual(["isletmeAdi", "whatsapp"]);
    for (const alan of bulunanlar) {
      const deger = extractVixrexValue(cumle, alan);
      if (alan.anahtar === "isletmeAdi") expect(deger).toBe("Konak Kafe");
      if (alan.anahtar === "whatsapp") expect(deger).toBe("0542 180 25 73");
    }
  });

  it("virgülsüz normal cümlede kısa eş-anlamlar (il, tel gibi) yanlış sınır saymaz", () => {
    // "Kilo" ve "kartel" gibi kelimeler içinde "il"/"tel" geçse de, virgül
    // öncesi bir ayraç olmadığı için serbest metin kesilmemeli.
    expect(extractVixrexValue("işletme adı Kilogram Kartel Gıda", isletme)).toBe(
      "Kilogram Kartel Gıda"
    );
  });

  it("var olan tek-alan davranışı bozulmadı (verb'li klasik cümleler)", () => {
    expect(extractVixrexValue("İşletme adını 'Aymira Giyim' yap", isletme)).toBe("Aymira Giyim");
    expect(extractVixrexValue("Adresimi Atatürk Cad. No:24 yap", adres)).toBe(
      "Atatürk Cad. No:24"
    );
  });
});
