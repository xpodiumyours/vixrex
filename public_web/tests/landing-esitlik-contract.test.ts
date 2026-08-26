import { describe, expect, it } from "vitest";
import {
  flutterLandingMetinleri,
  webPlatformKaynagi,
} from "./yardimcilar/landingMetinleri";
import { LANDING_ESITLIK_ISTISNALARI } from "./yardimcilar/landingEsitlikIstisnalari";

/**
 * FLUTTER ↔ WEB LANDING EŞİTLİK BEKÇİSİ (2026-08-26).
 *
 * NEDEN VAR
 * Tanıtım yüzeyi artık iki yerde birden yaşıyor: uygulamanın açılış ekranı
 * (`lib/screens/landing_screen.dart` + `lib/widgets/landing/`) ve web ana
 * sayfası (`public_web/src/components/landing/`). İkisi bugün aynı şeyi
 * söylüyor ama hiçbir mekanizma bunu garanti etmiyordu — ilk metin
 * değişikliğinde sessizce ayrışırlardı ve kimse fark etmezdi.
 *
 * NASIL ÇALIŞIR
 * Flutter ASILDIR. Bu test Flutter kaynağından kullanıcıya görünen bütün
 * metinleri çıkarır ve her birinin web tarafında da bulunduğunu doğrular.
 * Bir metin webde yoksa üç seçenek vardır:
 *   1. webe eklenir,
 *   2. `landingEsitlikIstisnalari.ts`'e GEREKÇESİYLE yazılır,
 *   3. Flutter'dan kaldırılır.
 * Sessizce ayrışmak seçenek değil.
 *
 * Liste tek yönlü kilitler: Flutter'a yeni bir metin girdiğinde test kırılır.
 * Webin fazladan metin taşıması serbesttir (Keşfet dizini gibi yalnız webde
 * olan yüzeyler var).
 */
describe("landing eşitliği — Flutter asıl, web ondan eşitlenir", () => {
  const flutterMetinleri = flutterLandingMetinleri();
  const web = webPlatformKaynagi();
  const istisnaMetinleri = new Set(
    LANDING_ESITLIK_ISTISNALARI.map((istisna) => istisna.metin)
  );

  it("Flutter landing'inden anlamlı sayıda metin çıkarılabiliyor", () => {
    // Çıkarıcı bozulursa test sessizce yeşile döner: hiç metin bulamayan bir
    // tarayıcı hiçbir ayrışmayı yakalayamaz. Bu iddia o sessiz bozulmayı
    // yakalar (ölçüm 2026-08-26: 115 metin).
    expect(flutterMetinleri.size).toBeGreaterThan(80);
  });

  it("Flutter'daki her metin ya webde var ya da gerekçeli istisnada", () => {
    const kayipMetinler = [...flutterMetinleri].filter(
      (metin) => !web.includes(metin) && !istisnaMetinleri.has(metin)
    );

    expect(
      kayipMetinler,
      "Flutter landing'inde olup web ana sayfasında bulunmayan metinler. " +
        "Ya webe ekleyin ya da tests/yardimcilar/landingEsitlikIstisnalari.ts " +
        "dosyasına GEREKÇESİYLE yazın."
    ).toEqual([]);
  });

  it("istisna listesi bayat değil — hepsi Flutter'da hâlâ duruyor", () => {
    const bayatIstisnalar = [...istisnaMetinleri].filter(
      (metin) => !flutterMetinleri.has(metin)
    );

    expect(
      bayatIstisnalar,
      "Bu metinler Flutter landing'inde artık yok; istisna kaydı da " +
        "silinmeli. Bayat istisna, gerçek bir ayrışmayı gizleyebilir."
    ).toEqual([]);
  });

  it("her istisnanın açıklayıcı bir gerekçesi var", () => {
    for (const istisna of LANDING_ESITLIK_ISTISNALARI) {
      expect(
        istisna.neden.length,
        `Gerekçesiz istisna: "${istisna.metin}"`
      ).toBeGreaterThan(30);
    }
  });
});
