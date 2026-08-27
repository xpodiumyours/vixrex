import { describe, expect, it } from "vitest";
import {
  flutterLandingMetinleri,
  webPlatformKaynagi,
} from "./yardimcilar/landingMetinleri";
import { LANDING_ESITLIK_ISTISNALARI } from "./yardimcilar/landingEsitlikIstisnalari";
import { webLandingMetinleri } from "./yardimcilar/landingMetinleriWeb";
import { LANDING_ESITLIK_ISTISNALARI_WEB } from "./yardimcilar/landingEsitlikIstisnalariWeb";

/**
 * FLUTTER ↔ WEB LANDING EŞİTLİK BEKÇİSİ (2026-08-27, çift yönlü).
 *
 * NEDEN VAR
 * Tanıtım yüzeyi artık iki yerde birden yaşıyor: uygulamanın açılış ekranı
 * (`lib/screens/landing_screen.dart` + `lib/widgets/landing/`) ve web ana
 * sayfası (`public_web/src/components/landing/`). İkisi bugün aynı şeyi
 * söylüyor ama hiçbir mekanizma bunu garanti etmiyordu — ilk metin
 * değişikliğinde sessizce ayrışırlardı ve kimse fark etmezdi.
 *
 * NASIL ÇALIŞIR
 * İki test bloğu vardır, ikisi de aynı mantıkla çalışır:
 *
 *   A) Flutter asıl, web ondan eşitlenir.
 *      Flutter'daki her metin webde de bulunmalı (ya da istisnada).
 *
 *   B) Web asıl, Flutter ondan eşitlenir.
 *      Web'deki her metin Flutter'da da bulunmalı (ya da istisnada).
 *
 * Her iki yönde de bayatlık kontrolü vardır: istisna listesinde olup
 * artık kaynakta bulunmayan metin varsa test kırılır.
 */

// ============================================================================
// A) FLUTTER → WEB (mevcut yön)
// ============================================================================

describe("A) landing eşitliği — Flutter asıl, web ondan eşitlenir", () => {
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

// ============================================================================
// B) WEB → FLUTTER (yeni yön)
// ============================================================================

describe("B) landing eşitliği — Web asıl, Flutter ondan eşitlenir", () => {
  const webMetinleri = webLandingMetinleri();
  const flutterMetinleri = flutterLandingMetinleri();
  const istisnaMetinleri = new Set(
    LANDING_ESITLIK_ISTISNALARI_WEB.map((istisna) => istisna.metin)
  );

  it("Web landing'inden anlamlı sayıda metin çıkarılabiliyor", () => {
    // Çıkarıcı bozulursa test sessizce yeşile döner. Bu iddia o sessiz
    // bozulmayı yakalar.
    expect(webMetinleri.size).toBeGreaterThan(40);
  });

  it("Web'deki her metin ya Flutter'da var ya da gerekçeli istisnada", () => {
    const kayipMetinler = [...webMetinleri].filter(
      (metin) => !flutterMetinleri.has(metin) && !istisnaMetinleri.has(metin)
    );

    expect(
      kayipMetinler,
      "Web landing'inde olup Flutter landing'inde bulunmayan metinler. " +
        "Ya Flutter'a ekleyin ya da tests/yardimcilar/landingEsitlikIstisnalariWeb.ts " +
        "dosyasına GEREKÇESİYLE yazın."
    ).toEqual([]);
  });

  it("web istisna listesi bayat değil — hepsi web'de hâlâ duruyor", () => {
    const bayatIstisnalar = [...istisnaMetinleri].filter(
      (metin) => !webMetinleri.has(metin)
    );

    expect(
      bayatIstisnalar,
      "Bu metinler web landing'inde artık yok; istisna kaydı da " +
        "silinmeli. Bayat istisna, gerçek bir ayrışmayı gizleyebilir."
    ).toEqual([]);
  });

  it("her web istisnasının açıklayıcı bir gerekçesi var", () => {
    for (const istisna of LANDING_ESITLIK_ISTISNALARI_WEB) {
      expect(
        istisna.neden.length,
        `Gerekçesiz web istisnası: "${istisna.metin}"`
      ).toBeGreaterThan(30);
    }
  });
});
