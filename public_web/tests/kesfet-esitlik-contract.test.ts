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
    // Gezinme artık Keşfet'e özgü değil: dört ana yüzeyin paylaştığı ortak
    // kabukta duruyor (Flutter HomeShellScreen karşılığı). Keşfet o kabuğun
    // içinde bir sekme olduğu için menü yine ekranda.
    const kabuk = readFileSync(
      resolve(__dirname, "../src/components/app/AppShellBoundary.tsx"),
      "utf-8"
    );
    const yanMenu = readFileSync(
      resolve(__dirname, "../src/components/app/AppSidebar.tsx"),
      "utf-8"
    );
    expect(webKaynak).toContain("<KesfetIcerik");
    expect(kabuk).toContain('pathname === "/kesfet"');
    expect(kabuk).toContain("<AppSidebar />");
    for (const etiket of ["Vitrinim", "Keşfet", "Vixrex", "Profil"]) {
      expect(yanMenu).toContain(etiket);
    }
  });

  it("ana Keşfet sayfası canlı veriyi build sırasında istemez", () => {
    expect(webKaynak).toContain('export const dynamic = "force-dynamic"');
  });

  it("mobil sabit alt menü aynı dört hedefle var — masaüstü gizli kuralı yakalar", () => {
    const yanMenu = readFileSync(
      resolve(__dirname, "../src/components/app/AppSidebar.tsx"),
      "utf-8"
    );
    // Masaüstü menü 901px üstünde görünür
    expect(yanMenu).toContain("min-[901px]:flex");
    // Mobil menü 901px altında sabit ve masaüstünde gizli
    expect(yanMenu).toContain("fixed");
    expect(yanMenu).toContain("bottom-0");
    expect(yanMenu).toContain("min-[901px]:hidden");
    expect(yanMenu).toContain('aria-label="Mobil uygulama menüsü"');
    // Aynı dört hedef mobilde de render ediliyor — yeni akış yok, mevcut MENU reuse
    for (const etiket of ["Vitrinim", "Keşfet", "Vixrex", "Profil"]) {
      expect(yanMenu).toContain(etiket);
    }
    // Mevcut akışlar korunuyor — /app, /kesfet, /app/profil ve Vixrex tetikleyici
    expect(yanMenu).toContain('"/app"');
    expect(yanMenu).toContain('"/kesfet"');
    expect(yanMenu).toContain('"/app/profil"');
    // Vixrex artık sayfa üstüne açılan kutu değil, dördün içinde gerçek sekme.
    expect(yanMenu).toContain('"/app/vixrex"');
  });

  it("mobil alt menü dört butonu da içerir", () => {
    const yanMenu = readFileSync(
      resolve(__dirname, "../src/components/app/AppSidebar.tsx"),
      "utf-8"
    );
    // NAV dizisi tek kaynak — dört etiket de orada
    const menuBlok = yanMenu.slice(yanMenu.indexOf("const NAV"));
    for (const etiket of ["Vitrinim", "Keşfet", "Vixrex", "Profil"]) {
      expect(menuBlok).toContain(`"${etiket}"`);
    }
    // Mobil nav MENU.map ile üretiliyor — ayrı hardcode menü yok
    expect(yanMenu).toContain("NAV.map");
    // Mobil nav fixed class'ı ile mobil boşluk ve maskot offset'i birlikte çalışır
    const icerik = readFileSync(
      resolve(__dirname, "../src/components/kesfet/KesfetIcerik.tsx"),
      "utf-8"
    );
    expect(icerik).toContain("pb-[84px]");
    expect(icerik).toContain("min-[901px]:pb-0");
    const mascot = readFileSync(
      resolve(__dirname, "../src/components/landing/MascotFab.tsx"),
      "utf-8"
    );
    expect(mascot).toContain("bottom-[80px]");
    expect(mascot).toContain("min-[901px]:bottom-5");
  });
});
