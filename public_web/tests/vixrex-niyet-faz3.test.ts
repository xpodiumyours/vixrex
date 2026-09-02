import { describe, it, expect } from "vitest";
import { VIXREX_NIYET_SOZLUGU } from "../src/lib/vixrexNiyetSozlugu";
import { resolveVixrexIntent, resolveVixrexIntentsAll } from "../src/lib/vixrexIntentResolver";
import { extractVixrexValue } from "../src/lib/vixrexValueExtractor";
import { validateField } from "../src/lib/vitrinFieldValidation";

describe("Faz 3 – 32 isteğe-bağlı", () => {
  const kalan = [
    "kisaTanitim","konumMetni","isletmeTuru","telefon","eposta","haritaEtiketi","instagram","website","enlem","boylam",
    "kategoriBolumBaslik","urunBolumBaslik","bantEtiket","bantBaslik","bantAciklama","bantGorsel","bantFiyat",
    "hakkindaUstBaslik","hakkindaGorsel","hakkindaGorselAlt","galeriUstBaslik","galeriBaslik","galeriAksiyonMetni","galeriAksiyonLinki",
    "blogUstBaslik","blogBaslik","sssUstBaslik","sssBaslik","sssAciklama","puanGoster","yolTarifiGoster","referansLinki",
  ] as const;
  it("32 kalan sözlükte var", () => {
    for (const k of kalan) expect(VIXREX_NIYET_SOZLUGU.some(a=>a.anahtar===k)).toBe(true);
  });
  it("kalan niyet tanınır", () => {
    expect(resolveVixrexIntent("Kısa tanıtımı Merhaba yap")?.anahtar).toBe("kisaTanitim");
    expect(resolveVixrexIntent("E-postamı test@a.com yap")?.anahtar).toBe("eposta");
    expect(resolveVixrexIntent("Enlemi 41.0 yap")?.anahtar).toBe("enlem");
    expect(resolveVixrexIntent("Puanı göster")?.anahtar).toBe("puanGoster");
  });
  it("çok-alanlı resolveAll", () => {
    const all = resolveVixrexIntentsAll("telefonu 02121234567 yap, instagramı aymira yap");
    const ks = new Set(all.map(a=>a.anahtar));
    expect(ks.has("telefon")).toBe(true);
    expect(ks.has("instagram")).toBe(true);
  });
  it("validator kalan tipler", () => {
    expect(validateField("eposta","test@a.com").ok).toBe(true);
    expect(validateField("eposta","bad").ok).toBe(false);
    expect(validateField("enlem","41").ok).toBe(true);
    expect(validateField("enlem","100").ok).toBe(false);
    expect(validateField("puanGoster",true).ok).toBe(true);
  });
  it("değer ayıklama çok-alanlı her alan kendi değerini alır", () => {
    const tel = VIXREX_NIYET_SOZLUGU.find(a=>a.anahtar==="telefon")!;
    const insta = VIXREX_NIYET_SOZLUGU.find(a=>a.anahtar==="instagram")!;
    const vPhone = extractVixrexValue("telefonu 0212 123 45 67 yap", tel);
    expect(vPhone?.replace(/[^0-9]/g,"").includes("2121234567")).toBe(true);
    const v2 = extractVixrexValue("instagramı @aymira yap", insta);
    expect(v2?.includes("aymira")).toBe(true);
  });
});
