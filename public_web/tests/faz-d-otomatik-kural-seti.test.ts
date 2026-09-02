import { describe, expect, it } from "vitest";
import { FIELD_BY_KEY, VITRIN_FIELDS } from "@/lib/vitrinFieldSchema";
import { otomatikDeger } from "@/lib/otomatikVitrinIcerik";
import { BUSINESS_CATEGORIES } from "@/lib/businessCategories";

/**
 * Faz D (Tek Asistan planı, 2026-09-02) — kural seti kilidi.
 *
 * Bu testler "3 soru"nun kullanıcı tarafından bana bırakılan kararlarını
 * kilitliyor: hangi alanlar otomatik, hangileri KESİNLİKLE değil, ve
 * neden. Birini değiştirmek isteyen, önce bu yorumları okumalı.
 */
describe("otomatikDoldurulabilir bayrağı — kural seti", () => {
  it("gerçek işletme kimliği hiçbir zaman otomatik değil", () => {
    for (const anahtar of ["isletmeAdi", "whatsapp", "adres", "il", "ilce", "calismaSaatleri", "logo", "telefon", "eposta"]) {
      expect(FIELD_BY_KEY.get(anahtar)?.otomatikDoldurulabilir, anahtar).not.toBe(true);
    }
  });

  it("hakkındaMetin (hikaye) otomatik değil — sahtesi güven kırar", () => {
    expect(FIELD_BY_KEY.get("hakkindaMetin")?.otomatikDoldurulabilir).not.toBe(true);
  });

  it("işletmeTuru otomatik değil — yanlış tahmin boş bırakmaktan kötü", () => {
    expect(FIELD_BY_KEY.get("isletmeTuru")?.otomatikDoldurulabilir).not.toBe(true);
  });

  it("kampanya bandı (bant*) hiçbiri otomatik değil — sahte fiyat/indirim yazılmaz", () => {
    for (const anahtar of ["bantEtiket", "bantBaslik", "bantAciklama", "bantGorsel", "bantFiyat"]) {
      expect(FIELD_BY_KEY.get(anahtar)?.otomatikDoldurulabilir, anahtar).not.toBe(true);
    }
  });

  it("tam olarak 14 alan otomatik işaretli", () => {
    const otomatikler = VITRIN_FIELDS.filter((f) => f.otomatikDoldurulabilir).map((f) => f.anahtar);
    expect(otomatikler.sort()).toEqual(
      [
        "heroRozet", "kisaTanitim", "kapakGorseli",
        "kategoriBolumBaslik", "urunBolumBaslik", "hakkindaBaslik",
        "galeriUstBaslik", "galeriBaslik", "galeriAksiyonMetni",
        "blogUstBaslik", "blogBaslik",
        "sssUstBaslik", "sssBaslik", "sssAciklama",
      ].sort()
    );
  });
});

describe("otomatikDeger() — içerik üretimi", () => {
  it("otomatikDoldurulabilir olmayan alan için her zaman null döner", () => {
    expect(otomatikDeger({ anahtar: "isletmeAdi", otomatikDoldurulabilir: false }, "Giyim")).toBeNull();
    expect(otomatikDeger({ anahtar: "hakkindaMetin" }, "Giyim")).toBeNull();
  });

  it("evrensel alan kategoriden bağımsız aynı metni döner", () => {
    expect(otomatikDeger({ anahtar: "sssBaslik", otomatikDoldurulabilir: true }, "Giyim"))
      .toBe(otomatikDeger({ anahtar: "sssBaslik", otomatikDoldurulabilir: true }, "Kuaför"));
    expect(otomatikDeger({ anahtar: "sssBaslik", otomatikDoldurulabilir: true }, null))
      .toBe("Sıkça Sorulan Sorular");
  });

  it("kategoriye özel alan kategoriye göre gerçekten değişir", () => {
    const giyim = otomatikDeger({ anahtar: "heroRozet", otomatikDoldurulabilir: true }, "Giyim");
    const kuafor = otomatikDeger({ anahtar: "heroRozet", otomatikDoldurulabilir: true }, "Kuaför");
    expect(giyim).not.toBeNull();
    expect(kuafor).not.toBeNull();
    expect(giyim).not.toBe(kuafor);
  });

  it("kategori etiketi 'Kafe / Lokanta' gibi görünüm label'ından çözülür", () => {
    expect(otomatikDeger({ anahtar: "urunBolumBaslik", otomatikDoldurulabilir: true }, "Kafe / Lokanta"))
      .toBe("Menümüz");
  });

  it("'Diğer' kategorisi için kasıtlı olarak null döner", () => {
    expect(otomatikDeger({ anahtar: "heroRozet", otomatikDoldurulabilir: true }, "Diğer")).toBeNull();
  });

  it("kategori hiç yoksa (henüz seçilmemiş) kategoriye-özel alan null döner", () => {
    expect(otomatikDeger({ anahtar: "heroRozet", otomatikDoldurulabilir: true }, null)).toBeNull();
  });

  it("18 kanonik kategorinin (Diğer hariç) hepsi için 4 alan da dolu", () => {
    const kategoriyeOzelAlanlar = ["heroRozet", "kisaTanitim", "kategoriBolumBaslik", "urunBolumBaslik"];
    for (const kategori of BUSINESS_CATEGORIES) {
      if (kategori.id === "diger") continue;
      for (const anahtar of kategoriyeOzelAlanlar) {
        const deger = otomatikDeger({ anahtar, otomatikDoldurulabilir: true }, kategori.label);
        expect(deger, `${kategori.id}.${anahtar}`).toBeTruthy();
      }
    }
  });
});
