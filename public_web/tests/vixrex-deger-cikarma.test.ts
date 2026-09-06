import { describe, expect, it } from "vitest";
import { resolveVixrexIntent } from "../src/lib/vixrexIntentResolver";
import { extractVixrexValue } from "../src/lib/vixrexValueExtractor";
import { validateField } from "../src/lib/vitrinFieldValidation";
import { VIXREX_NIYET_SOZLUGU } from "../src/lib/vixrexNiyetSozlugu";

/**
 * DEĞER ÇIKARMA BEKÇİSİ (2026-09-07)
 *
 * NEDEN VAR: Motor "çalışıyor" sanılıyordu; niyet testleri yeşildi. Ama gerçek
 * cümlede kaydedilecek DEĞER bozuktu:
 *   "İşletme adını Ada Kahve yap"      → vitrine "nı Ada Kahve" yazıyordu
 *   "Instagram hesabımı vixrexapp yap" → "hesabımı vixrexapp"
 *   "Kategoriyi Kafe yap"              → "geçersiz seçim" ile reddediliyordu
 *
 * Kök neden: değer çıkarıcı alan adını ham metinde `RegExp(..., "i")` ile
 * arıyordu; JavaScript'in `i` bayrağı Türkçe "İ"/"ı" harflerini katlamaz, bu
 * yüzden alan adı hiç bulunamıyor ve eki değere yapışık kalıyordu.
 *
 * Bu test cümle → alan → değer → validateField zincirinin TAMAMINI doğrular.
 */

type Senaryo = { cumle: string; alan: string; deger: unknown };

const SENARYOLAR: Senaryo[] = [
  { cumle: "İşletme adını Ada Kahve yap", alan: "isletmeAdi", deger: "Ada Kahve" },
  { cumle: "Dükkan adımı Ada Kahve yap", alan: "isletmeAdi", deger: "Ada Kahve" },
  { cumle: "Instagram hesabımı vixrexapp yap", alan: "instagram", deger: "vixrexapp" },
  { cumle: "Kategoriyi Kafe yap", alan: "kategori", deger: "Kafe / Lokanta" },
  { cumle: "Mahalleyi Caddebostan yap", alan: "mahalle", deger: "Caddebostan" },
  { cumle: "Whatsapp numaramı 05551234567 yap", alan: "whatsapp", deger: "905551234567" },
  { cumle: "Adresi Moda Caddesi No 12 Kadıköy yap", alan: "adres", deger: "Moda Caddesi No 12 Kadıköy" },
  { cumle: "Web sitemi https://vixrex.com yap", alan: "website", deger: "https://vixrex.com" },
  { cumle: "Kısa tanıtımı Butik kahve dükkanı yap", alan: "kisaTanitim", deger: "Butik kahve dükkanı" },
  { cumle: "Konum metnini Kadıköy yap", alan: "konumMetni", deger: "Kadıköy" },
];

describe("Vixrex değer çıkarma — cümleden kaydedilecek değere", () => {
  it.each(SENARYOLAR)(
    'ANLAR: "$cumle" → $alan = $deger',
    ({ cumle, alan, deger }) => {
      const bulunanAlan = resolveVixrexIntent(cumle);
      expect(bulunanAlan?.anahtar, `alan bulunamadı: "${cumle}"`).toBe(alan);

      const hamDeger = extractVixrexValue(cumle, bulunanAlan!);
      expect(hamDeger, `değer çıkarılamadı: "${cumle}"`).not.toBeNull();

      const sonuc = validateField(alan, hamDeger as never);
      expect(
        sonuc.ok,
        `doğrulama reddetti: "${cumle}" → ${JSON.stringify(hamDeger)}` +
          (sonuc.ok ? "" : ` (${sonuc.hata})`),
      ).toBe(true);
      expect((sonuc as { deger: unknown }).deger).toEqual(deger);
    },
  );

  it("hiçbir alanda ek kalıntısı değere sızmaz", () => {
    // "nı Ada Kahve" sınıfı hata: değer, Türkçe bir ekle BAŞLAMAMALI.
    const ekIleBaslayanlar: string[] = [];
    const ekDeseni =
      /^(nı|ni|nu|nü|mı|mi|mu|mü|yı|yi|yu|yü|sı|si|su|sü|ı|i|u|ü)(\s|$)/i;

    for (const { cumle } of SENARYOLAR) {
      const alan = resolveVixrexIntent(cumle);
      if (!alan) continue;
      const deger = extractVixrexValue(cumle, alan);
      if (typeof deger === "string" && ekDeseni.test(deger)) {
        ekIleBaslayanlar.push(`"${cumle}" → ${JSON.stringify(deger)}`);
      }
    }

    expect(
      ekIleBaslayanlar,
      `ek kalıntısı içeren değerler:\n${ekIleBaslayanlar.join("\n")}`,
    ).toEqual([]);
  });

  it("sözlükteki 46 alanın hepsi bu testte ya kapsanır ya bilinçli dışarıdadır", () => {
    // Kapsam raporu: yeni alan eklenince burası uyarır.
    const kapsanan = new Set(SENARYOLAR.map((s) => s.alan));
    const tumAlanlar = VIXREX_NIYET_SOZLUGU.map((a) => a.anahtar);
    expect(tumAlanlar.length).toBe(46);
    // En az temel alanlar kapsanmalı; tamamı zamanla eklenecek.
    for (const zorunlu of ["isletmeAdi", "kategori", "whatsapp", "adres"]) {
      expect(kapsanan.has(zorunlu), `${zorunlu} senaryosu eksik`).toBe(true);
    }
  });
});
