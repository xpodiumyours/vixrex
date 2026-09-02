import { describe, it, expect } from "vitest";
import { VIXREX_NIYET_SOZLUGU } from "../src/lib/vixrexNiyetSozlugu";
import { resolveVixrexIntent } from "../src/lib/vixrexIntentResolver";
import { extractVixrexValue } from "../src/lib/vixrexValueExtractor";
import { validateField } from "../src/lib/vitrinFieldValidation";
import { vixrexNormalizeDartParity } from "../src/lib/vixrexNormalizer";

describe("Faz 1 – 46 alan niyet sözlüğü parity (Dart ile eşit)", () => {
  it("sözlük 46 alan", () => {
    expect(VIXREX_NIYET_SOZLUGU.length).toBe(46);
  });

  it("her alan anahtar+esAnlamlar+ornekIfadeler+beklenenVeriTipi var", () => {
    for (const a of VIXREX_NIYET_SOZLUGU) {
      expect(a.anahtar.trim().length).toBeGreaterThan(0);
      expect(a.esAnlamlar.length).toBeGreaterThan(0);
      expect(a.ornekIfadeler.length).toBeGreaterThan(0);
      expect(a.beklenenVeriTipi.trim().length).toBeGreaterThan(0);
    }
  });

  it("Dart normalize ile parity – ı→i, ğ→g", () => {
    expect(vixrexNormalizeDartParity("İşletme Adı")).toBe("isletme adi");
    expect(vixrexNormalizeDartParity("Çalışma Saatleri")).toBe("calisma saatleri");
  });

  it("6 zorunlu alan tanınır (Dart ile aynı)", () => {
    expect(resolveVixrexIntent("İşletme adını Aymira yap")?.anahtar).toBe("isletmeAdi");
    expect(resolveVixrexIntent("Kategorimi Kuaför yap")?.anahtar).toBe("kategori");
    expect(resolveVixrexIntent("WhatsApp numaramı 0555 123 45 67 yap")?.anahtar).toBe("whatsapp");
    expect(resolveVixrexIntent("Adresimi Atatürk Cad. No:24 yap")?.anahtar).toBe("adres");
    expect(resolveVixrexIntent("İli İstanbul yap")?.anahtar).toBe("il");
    expect(resolveVixrexIntent("İlçeyi Kadıköy yap")?.anahtar).toBe("ilce");
  });

  it("uzun eş-anlam önceliği: işletme adı > ad", () => {
    expect(resolveVixrexIntent("işletme adını değiştir")?.anahtar).toBe("isletmeAdi");
  });

  it("tırnak ve : ile değer ayıklama (Dart ile aynı)", () => {
    const isletme = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === "isletmeAdi")!;
    const whatsapp = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === "whatsapp")!;
    expect(extractVixrexValue("İşletme adını 'Aymira Giyim' yap", isletme)).toBe("Aymira Giyim");
    expect(extractVixrexValue("İşletme adı: Aymira", isletme)).toBe("Aymira");
    expect(extractVixrexValue("whatsapp: 0555 123 45 67", whatsapp)).toBe("0555 123 45 67");
  });

  it("değer yok → null (netleştirme tetikler)", () => {
    const isletme = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === "isletmeAdi")!;
    const adres = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === "adres")!;
    expect(extractVixrexValue("İşletme adını değiştir", isletme)).toBeNull();
    expect(extractVixrexValue("adres yanlış", adres)).toBeNull();
  });

  it("validateField ile aynı kural – whatsapp tr_mobil, adres sokak+numara", () => {
    expect(validateField("whatsapp", "0555 123 45 67").ok).toBe(true);
    expect(validateField("whatsapp", "123").ok).toBe(false);
    expect(validateField("isletmeAdi", "A").ok).toBe(false);
    expect(validateField("isletmeAdi", "Aymira").ok).toBe(true);
  });
});

describe("Web ↔ Mobil parity – aynı cümle aynı anahtar/değer", () => {
  const cases: Array<{ input: string; anahtar: string; hamDeger: string }> = [
    { input: "İşletme adını 'Aymira Giyim' yap", anahtar: "isletmeAdi", hamDeger: "Aymira Giyim" },
    { input: "WhatsApp numaramı 0555 123 45 67 yap", anahtar: "whatsapp", hamDeger: "0555 123 45 67" },
    { input: "Adresimi Atatürk Cad. No:24 yap", anahtar: "adres", hamDeger: "Atatürk Cad. No:24" },
  ];
  for (const { input, anahtar, hamDeger } of cases) {
    it(`${input} → ${anahtar} / ${hamDeger}`, () => {
      const alan = resolveVixrexIntent(input);
      expect(alan?.anahtar).toBe(anahtar);
      if (alan) expect(extractVixrexValue(input, alan)).toBe(hamDeger);
    });
  }
});
