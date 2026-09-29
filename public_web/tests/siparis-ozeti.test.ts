import { describe, expect, it } from "vitest";

import {
  kurusMetni,
  siparisOzetiMetni,
  whatsappBaglantisi,
  whatsappRakamlari,
} from "@/lib/siparisOzeti";

describe("kurusMetni", () => {
  it("tam tutarı TL olarak yazar", () => {
    expect(kurusMetni(25000)).toBe("250 TL");
  });

  it("kuruşu virgüllü gösterir", () => {
    expect(kurusMetni(15050)).toBe("150,50 TL");
    expect(kurusMetni(5)).toBe("0,05 TL");
  });
});

describe("siparisOzetiMetni", () => {
  const girdi = {
    storeName: "Teknofix Kahve",
    customerName: "Ayşe",
    customerPhone: "05551112233",
    customerNote: "Az şekerli",
    fulfillment: "delivery" as const,
    paymentMethod: "online" as const,
    items: [
      { productName: "Türk Kahvesi", quantity: 2, unitPriceKurus: 4500 },
      { productName: "Baklava", quantity: 1, unitPriceKurus: 12000 },
    ],
    amountKurus: 21000,
  };

  it("ürün adet ve tutarları listeler", () => {
    const metin = siparisOzetiMetni(girdi);
    expect(metin).toContain("- Türk Kahvesi x2 = 90 TL");
    expect(metin).toContain("- Baklava x1 = 120 TL");
  });

  it("teslim, ödeme ve toplamı yazar", () => {
    const metin = siparisOzetiMetni(girdi);
    expect(metin).toContain("Teslim: Kurye ile teslim");
    expect(metin).toContain("Ödeme: Online ödeme");
    expect(metin).toContain("Toplam: 210 TL");
  });

  it("not varsa ekler, yoksa satır üretmez", () => {
    expect(siparisOzetiMetni(girdi)).toContain("Not: Az şekerli");
    const notsuz = siparisOzetiMetni({ ...girdi, customerNote: "" });
    expect(notsuz).not.toContain("Not:");
  });
});

describe("whatsappBaglantisi", () => {
  it("telefon rakamlarını ayıklar", () => {
    expect(whatsappRakamlari("+90 (555) 111-22-33")).toBe("905551112233");
  });

  it("metni şifrelenmiş bağlantı üretir", () => {
    const baglanti = whatsappBaglantisi("05551112233", "Merhaba\nToplam: 50 TL");
    expect(baglanti).toContain("https://wa.me/05551112233?text=");
    expect(baglanti).toContain(encodeURIComponent("Merhaba\nToplam: 50 TL"));
  });

  it("kısa numarada bağlantı üretmez", () => {
    expect(whatsappBaglantisi("123", "selam")).toBeNull();
    expect(whatsappBaglantisi("", "selam")).toBeNull();
  });
});
