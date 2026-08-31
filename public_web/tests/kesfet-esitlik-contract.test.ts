import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

/**
 * Keşfet eşitlik sözleşmesi (#344, 2026-08-27).
 *
 * Flutter ve web aynı başlık ve alt başlığı göstermeli.
 * Bu test iki tarafın aynı metinleri kullandığını kilitler.
 *
 * Etkileşimli arama ve filtreler ayrı istemci modülünde tutulur; sayfa SEO
 * metadata ve başlığı sunucu tarafında üretmeye devam eder.
 */
describe("Keşfet eşitlik sözleşmesi", () => {
  const webKaynak = readFileSync(
    resolve(__dirname, "../src/app/(site)/kesfet/page.tsx"),
    "utf-8"
  );
  const flutterKaynak = readFileSync(
    resolve(__dirname, "../../lib/screens/explore_screen.dart"),
    "utf-8"
  );

  it("başlık her iki tarafta aynı", () => {
    // Flutter: `"Vixrex'leri Keşfet"` (onlyRentalTemplates=false)
    expect(flutterKaynak).toContain("Vixrex'leri Keşfet");
    expect(webKaynak).toContain("Vixrex'leri Keşfet");
  });

  it("alt başlığın ortak gövdesi iki tarafta aynı", () => {
    // Ortak gövde birebir aynı kalmalı — asıl eşitlik iddiası bu.
    for (const kaynak of [flutterKaynak, webKaynak]) {
      expect(kaynak).toContain("Yayındaki tüm Vixrex vitrinlerini inceleyin");
    }
  });

  it("web'deki ek açıklama cümlesi korunuyor — BİLİNÇLİ FARK", () => {
    // Web'de fazladan bir cümle var ve KALMALI:
    //   "Beğendiğin hazır vitrini kirala, kendi işletmenin vitrini olsun."
    //
    // Bu bir ayrışma değil, izleyici farkı. Web'deki Keşfet'i arama
    // motorundan gelen, Vixrex'i hiç duymamış biri açıyor — kiralama
    // fikrini orada öğreniyor. Uygulamadaki Keşfet'i açan kişi zaten
    // uygulamayı indirmiş, o cümleye ihtiyacı yok.
    //
    // 2026-08-27'de bir ajan bu cümleyi "eşitlik" adına sildi; Casper
    // geri koydurdu. Bu iddia aynı silmenin tekrarını engelliyor.
    expect(
      webKaynak,
      "Web Keşfet'indeki açıklama cümlesi silinmiş. Bu cümle bilinçli " +
        "olarak yalnız webde duruyor — arama motorundan gelen ziyaretçi " +
        "kiralama fikrini oradan öğreniyor."
    ).toContain("Beğendiğin hazır vitrini");
  });

  it("kiralık fiyat vaadi her iki tarafta aynı", () => {
    const kart = readFileSync(
      resolve(__dirname, "../src/components/kesfet/VitrinKarti.tsx"),
      "utf-8"
    );
    expect(kart).toContain("Aylık 299 TL");
    expect(kart).toContain("14 gün ücretsiz dene");
    // Flutter: VitrinStoreCard içinde aynı metinler
    const flutterKart = readFileSync(
      resolve(__dirname, "../../lib/widgets/vitrin_store_card.dart"),
      "utf-8"
    );
    expect(flutterKart).toContain("Aylık 299 TL");
    expect(flutterKart).toContain("14 gün ücretsiz dene");
  });

  it("KİRALIK rozeti her iki tarafta aynı", () => {
    const kart = readFileSync(
      resolve(__dirname, "../src/components/kesfet/VitrinKarti.tsx"),
      "utf-8"
    );
    expect(kart).toContain("KİRALIK");
    const flutterKart = readFileSync(
      resolve(__dirname, "../../lib/widgets/vitrin_store_card.dart"),
      "utf-8"
    );
    expect(flutterKart).toContain("KİRALIK");
  });

  it("CANLI/KAPALI rozeti her iki tarafta aynı", () => {
    const kart = readFileSync(
      resolve(__dirname, "../src/components/kesfet/VitrinKarti.tsx"),
      "utf-8"
    );
    expect(kart).toContain("CANLI");
    expect(kart).toContain("KAPALI");
    const flutterKart = readFileSync(
      resolve(__dirname, "../../lib/widgets/vitrin_store_card.dart"),
      "utf-8"
    );
    expect(flutterKart).toContain("CANLI");
    expect(flutterKart).toContain("KAPALI");
  });

  it("kiralık kart butonları her iki tarafta aynı", () => {
    const kart = readFileSync(
      resolve(__dirname, "../src/components/kesfet/VitrinKarti.tsx"),
      "utf-8"
    );
    expect(kart).toContain("İncele");
    expect(kart).toContain("Kirala");
    const flutterKart = readFileSync(
      resolve(__dirname, "../../lib/widgets/vitrin_store_card.dart"),
      "utf-8"
    );
    expect(flutterKart).toContain("İncele");
    expect(flutterKart).toContain("Kirala");
  });

  it("kategori etiketi her iki tarafta büyük harf", () => {
    const kart = readFileSync(
      resolve(__dirname, "../src/components/kesfet/VitrinKarti.tsx"),
      "utf-8"
    );
    expect(kart).toContain("uppercase");
    const flutterKart = readFileSync(
      resolve(__dirname, "../../lib/widgets/vitrin_store_card.dart"),
      "utf-8"
    );
    expect(flutterKart).toContain(".toUpperCase()");
  });

  it("masaüstü Keşfet görünümünde sol gezinme menüsü var", () => {
    const icerik = readFileSync(
      resolve(__dirname, "../src/components/kesfet/KesfetIcerik.tsx"),
      "utf-8"
    );
    const yanMenu = readFileSync(
      resolve(__dirname, "../src/components/kesfet/KesfetYanMenu.tsx"),
      "utf-8"
    );
    expect(webKaynak).toContain("<KesfetIcerik");
    expect(icerik).toContain("<KesfetYanMenu");
    for (const etiket of ["Vitrinim", "Keşfet", "Vixrex", "Profil"]) {
      expect(yanMenu).toContain(etiket);
    }
  });
});
