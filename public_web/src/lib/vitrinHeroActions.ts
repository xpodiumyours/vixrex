// Vitrin hero butonları — kategori profiline göre üretilir.
//
// vitrinProfile.ts'teki her kategorinin `primaryActions` ve `ctaLabel`'ı
// burada tüketilir: kuaförde randevu (WhatsApp) ve yol tarifi, giyimde
// whatsapp, yol tarifi ve web sitesi. Veri hazırdı, kullanılmıyordu.
//
// SAF FONKSİYON: React, fetch, tarayıcı nesnesi yok. Girdi → liste.
//
// KURALLAR (sırayla):
//  1. Telefon evrenseldir ve her zaman ilk sıradadır; primaryActions'a bakmaz.
//  2. primaryActions sırayla gezilir; "booking" tek başına buton üretmez,
//     yalnız WhatsApp butonunun yazısını ctaLabel yapar (istisna: whatsapp
//     yoksa booking kendi WhatsApp butonunu üretir). Hazır mesaj
//     profile.waMesaji'dır; tanımlı değilse mesajsız düz wa.me linki gider.
//  3. Verisi olmayan buton çıkmaz — ölü buton üretmek yasak.
//  4. Aynı anahtardan iki buton dönmez.

import type { VitrinCategoryProfile } from "./vitrinProfile";

export interface HeroAction {
  anahtar: string;
  etiket: string;
  href: string;
  disKapi: boolean;
}

export interface HeroActionVeri {
  phoneUrl: string | null;
  whatsappNumarasi: string | null;
  mapsUrl: string | null;
  websiteUrl: string | null;
}

function waLinki(numara: string, mesaj?: string): string {
  return mesaj
    ? `https://wa.me/${numara}?text=${encodeURIComponent(mesaj)}`
    : `https://wa.me/${numara}`;
}

export function heroActions(
  profile: VitrinCategoryProfile,
  veri: HeroActionVeri
): HeroAction[] {
  const butonlar: HeroAction[] = [];

  // 1. Telefon — her zaman ilk sırada, kategoriden bağımsız.
  if (veri.phoneUrl) {
    butonlar.push({
      anahtar: "telefon",
      etiket: "Hemen Ara",
      href: veri.phoneUrl,
      disKapi: false,
    });
  }

  const aksiyonlar = profile.primaryActions;
  const whatsappVar = aksiyonlar.includes("whatsapp");
  const bookingVar = aksiyonlar.includes("booking");

  for (const aksiyon of aksiyonlar) {
    if (aksiyon === "whatsapp") {
      if (!veri.whatsappNumarasi) continue;
      if (butonlar.some((b) => b.anahtar === "whatsapp")) continue;
      butonlar.push({
        anahtar: "whatsapp",
        etiket: bookingVar ? profile.ctaLabel : "WhatsApp",
        href: waLinki(veri.whatsappNumarasi, bookingVar ? profile.waMesaji : undefined),
        disKapi: true,
      });
    } else if (aksiyon === "booking") {
      // Tek başına buton üretmez; whatsapp'ın yazısını ctaLabel yapar.
      // İstisna: whatsapp hiç yoksa booking kendi WhatsApp butonunu üretir.
      if (whatsappVar) continue;
      if (!veri.whatsappNumarasi) continue;
      butonlar.push({
        anahtar: "whatsapp",
        etiket: profile.ctaLabel,
        href: waLinki(veri.whatsappNumarasi, profile.waMesaji),
        disKapi: true,
      });
    } else if (aksiyon === "maps") {
      if (!veri.mapsUrl) continue;
      if (butonlar.some((b) => b.anahtar === "maps")) continue;
      butonlar.push({
        anahtar: "maps",
        etiket: "Yol Tarifi",
        href: veri.mapsUrl,
        disKapi: true,
      });
    } else if (aksiyon === "website") {
      if (!veri.websiteUrl) continue;
      if (butonlar.some((b) => b.anahtar === "website")) continue;
      butonlar.push({
        anahtar: "website",
        etiket: "Web Sitesi",
        href: veri.websiteUrl,
        disKapi: true,
      });
    }
  }

  return butonlar;
}
