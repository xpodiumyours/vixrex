import { describe, expect, it } from "vitest";
import { heroActions, type HeroActionVeri } from "../src/lib/vitrinHeroActions";
import { PROFILES, type VitrinCategoryProfile } from "../src/lib/vitrinProfile";

// Vitrin hero butonları kategori profiline göre üretilir (vitrinHeroActions).
// Kurallar: telefon evrensel ve ilk sırada; whatsapp/booking/ctaLabel
// etkileşimi; verisi olmayan buton çıkmaz; aynı anahtar iki kez dönmez.

const doluVeri: HeroActionVeri = {
  phoneUrl: "tel:+905551234567",
  whatsappNumarasi: "905551234567",
  mapsUrl: "https://www.google.com/maps/search/?api=1&query=41,29",
  websiteUrl: "https://teknofix.com",
};

const kuafor = PROFILES.find((p) => p.id === "kuafor")!;
const giyim = PROFILES.find((p) => p.id === "giyim")!;

describe("heroActions — kategori profiline göre butonlar", () => {
  it("kuaför + tüm veri → WhatsApp butonunun yazısı ctaLabel'dir (Randevu Sor)", () => {
    const butonlar = heroActions(kuafor, doluVeri);
    const whatsapp = butonlar.find((b) => b.anahtar === "whatsapp");
    expect(whatsapp?.etiket).toBe(kuafor.ctaLabel);
    expect(whatsapp?.etiket).toBe("Randevu Sor");
    expect(whatsapp?.href).toContain("wa.me/905551234567");
    expect(whatsapp?.href).toContain(encodeURIComponent("Merhaba, randevu almak istiyorum."));
  });

  it("kuaför profilinde → Web Sitesi butonu ÇIKMAZ", () => {
    const butonlar = heroActions(kuafor, doluVeri);
    expect(butonlar.some((b) => b.anahtar === "website")).toBe(false);
  });

  it("kuaför profilinde tek WhatsApp butonu vardır (booking ayrı buton üretmez)", () => {
    const butonlar = heroActions(kuafor, doluVeri);
    expect(butonlar.filter((b) => b.anahtar === "whatsapp")).toHaveLength(1);
  });

  it("giyim + tüm veri → WhatsApp yazısı 'WhatsApp' ve 'Web Sitesi' butonu çıkar", () => {
    const butonlar = heroActions(giyim, doluVeri);
    const whatsapp = butonlar.find((b) => b.anahtar === "whatsapp");
    expect(whatsapp?.etiket).toBe("WhatsApp");
    expect(whatsapp?.href).not.toContain("?text=");
    const website = butonlar.find((b) => b.anahtar === "website");
    expect(website?.etiket).toBe("Web Sitesi");
    expect(website?.href).toBe("https://teknofix.com");
  });

  it("whatsappNumarasi null → WhatsApp butonu hiç dönmez", () => {
    const butonlar = heroActions(kuafor, { ...doluVeri, whatsappNumarasi: null });
    expect(butonlar.some((b) => b.anahtar === "whatsapp")).toBe(false);
  });

  it("whatsappNumarasi yoksa ve primaryActions'ta whatsapp yoksa booking buton üretmez", () => {
    const butonlar = heroActions(kuafor, {
      phoneUrl: null,
      whatsappNumarasi: null,
      mapsUrl: null,
      websiteUrl: null,
    });
    expect(butonlar).toHaveLength(0);
  });

  it("phoneUrl varsa telefon her zaman ilk sıradadır", () => {
    for (const p of PROFILES) {
      const butonlar = heroActions(p, doluVeri);
      if (butonlar.length === 0) continue;
      expect(butonlar[0], p.id).toEqual(
        expect.objectContaining({ anahtar: "telefon", etiket: "Hemen Ara" })
      );
    }
  });

  it("phoneUrl yoksa ilk buton profil aksiyonlarının ilk çıkabilenidir ve birincil sıradır", () => {
    const butonlar = heroActions(kuafor, { ...doluVeri, phoneUrl: null });
    expect(butonlar[0]?.anahtar).toBe("whatsapp");
  });

  it("mapsUrl null → Yol Tarifi butonu çıkmaz", () => {
    const butonlar = heroActions(giyim, { ...doluVeri, mapsUrl: null });
    expect(butonlar.some((b) => b.anahtar === "maps")).toBe(false);
  });

  it("websiteUrl null → Web Sitesi butonu çıkmaz", () => {
    const butonlar = heroActions(giyim, { ...doluVeri, websiteUrl: null });
    expect(butonlar.some((b) => b.anahtar === "website")).toBe(false);
  });

  it("istisna: whatsapp yoksa booking kendi WhatsApp butonunu üretir", () => {
    const sadeceBooking: VitrinCategoryProfile = {
      id: "test_booking",
      label: "Test",
      family: "service",
      sectionTitle: "Test",
      ctaLabel: "Randevu Al",
      primaryActions: ["booking", "maps"],
      waMesaji: "Merhaba, test randevusu almak istiyorum.",
    };
    const butonlar = heroActions(sadeceBooking, doluVeri);
    const whatsapp = butonlar.filter((b) => b.anahtar === "whatsapp");
    expect(whatsapp).toHaveLength(1);
    expect(whatsapp[0].etiket).toBe("Randevu Al");
    expect(whatsapp[0].href).toContain(encodeURIComponent("Merhaba, test randevusu almak istiyorum."));
  });

  it("aynı anahtardan iki buton dönmez — 19 profilin hepsinde", () => {
    for (const p of PROFILES) {
      const butonlar = heroActions(p, doluVeri);
      const anahtarlar = butonlar.map((b) => b.anahtar);
      expect(new Set(anahtarlar).size, `${p.id} anahtar tekrarı`).toBe(anahtarlar.length);
    }
  });

  it("19 kategorinin HEPSİ patlamadan çalışır ve her butonun href'i boş değildir", () => {
    expect(PROFILES.length).toBe(19);
    for (const p of PROFILES) {
      const butonlar = heroActions(p, doluVeri);
      for (const b of butonlar) {
        expect(b.href.length, `${p.id}/${b.anahtar} href boş`).toBeGreaterThan(0);
        expect(b.etiket.length, `${p.id}/${b.anahtar} etiket boş`).toBeGreaterThan(0);
      }
    }
  });

  it("booking içeren HER kategoride waMesaji tanımlı ve boş değil", () => {
    const bookingli = PROFILES.filter((p) =>
      p.primaryActions.includes("booking")
    );
    expect(bookingli.length).toBeGreaterThan(0);
    for (const p of bookingli) {
      expect(p.waMesaji, `${p.id} waMesaji eksik`).toBeTruthy();
      expect(p.waMesaji!.trim().length, `${p.id} waMesaji boş`).toBeGreaterThan(0);
    }
  });

  it("teknik_servis: buton etiketi 'Servis Talebi' ve mesajı 'servis talebinde' içerir", () => {
    const teknikServis = PROFILES.find((p) => p.id === "teknik_servis")!;
    const butonlar = heroActions(teknikServis, doluVeri);
    const whatsapp = butonlar.find((b) => b.anahtar === "whatsapp");
    expect(whatsapp?.etiket).toBe("Servis Talebi");
    expect(decodeURIComponent(whatsapp!.href)).toContain("servis talebinde");
  });
});
