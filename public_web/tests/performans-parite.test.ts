import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Performans matrisi parite testi (sözleşme §16).
 *
 * Sözleşme kuralı: "Bu bölümde ölçüm sonucu uydurulmamıştır. Sayısal
 * hedefler gerçek üretim ölçümü alındıktan sonra kilitlenmelidir."
 *
 * Bu test yalnız KAYNAK KODUN kanıtlayabildiği satırları kilitler:
 * mimari, görsel yükleme stratejisi, font stratejisi, sıkıştırma sözleşmesi.
 * LCP/INP/CLS/p95/bundle bütçesi satırları ölçüm gerektirir — burada
 * KAPATILMAZ, uydurma eşik konmaz (○/✗ olarak kalır).
 */

const flutterShell = readFileSync(
  resolve(__dirname, "../../lib/screens/home_shell_screen.dart"),
  "utf8",
);
const flutterImg = readFileSync(
  resolve(__dirname, "../../lib/services/image_optimization_service.dart"),
  "utf8",
);
const nextLayout = readFileSync(
  resolve(__dirname, "../src/app/layout.tsx"),
  "utf8",
);
const nextGlobals = readFileSync(
  resolve(__dirname, "../src/app/globals.css"),
  "utf8",
);
const nextShell = readFileSync(
  resolve(__dirname, "../src/components/app/AppShellBoundary.tsx"),
  "utf8",
);
const nextSidebar = readFileSync(
  resolve(__dirname, "../src/components/app/AppSidebar.tsx"),
  "utf8",
);
const nextProductCatalog = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/ProductCatalog.tsx"),
  "utf8",
);
// Ürün detayının görsel alanı artık sayfanın içinde değil, paylaşılan
// deneyim bileşeninde çiziliyor. Ölçüm dosya adına değil davranışa bakar.
const nextProductDetailExperience = readFileSync(
  resolve(__dirname, "../src/components/ProductDetailExperienceBase.tsx"),
  "utf8",
);
const nextSikistir = readFileSync(
  resolve(__dirname, "../src/lib/gorselSikistir.ts"),
  "utf8",
);

describe("Performans: sekme mimarisi (yeniden kurulum yok)", () => {
  it("Flutter IndexedStack ile sekme gövdesini korur", () => {
    expect(flutterShell).toContain("IndexedStack");
  });

  it("Next kalıcı sekme kabuğu + prefetch ile eşdeğer davranır", () => {
    expect(nextShell).toContain("AppShellBoundary");
    expect(nextShell).toContain("router.prefetch");
    expect(nextSidebar).toContain("prefetch");
  });
});

describe("Performans: görsel yükleme stratejisi", () => {
  it("public vitrin next/image kullanır (lazy varsayılan)", () => {
    expect(nextProductCatalog).toContain('from "next/image"');
  });

  it("ürün detayında ilk görsel öncelikli yüklenir", () => {
    // Ana görsel next/image ile ve priority ile yükleniyor (LCP).
    expect(nextProductDetailExperience).toMatch(/<Image[\s\S]*?priority/);
  });

  it("kapak gibi büyük görseller lazy işaretli", () => {
    const vitrinView = readFileSync(
      resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
      "utf8",
    );
    expect(vitrinView).toContain('loading="lazy"');
  });

  it("responsive sizes ile doğru boyut indirilir", () => {
    expect(nextProductCatalog).toContain("sizes=");
  });
});

describe("Performans: font stratejisi (render engelleme yok)", () => {
  it("fontlar next/font ile derlemede gelir (self-hosted)", () => {
    expect(nextLayout).toContain("next/font/local");
    expect(nextLayout).toContain("Outfit");
  });

  it("globals.css'te render engelleyen Google Fonts @import yok", () => {
    // #344: @import kaldırılıp next/font'a geçildi — geri dönüş olmasın.
    expect(nextGlobals).not.toMatch(/@import\s+url\(https:\/\/fonts/);
  });

  it("Outfit ağırlıkları eksiksiz tanımlı (300–900)", () => {
    for (const w of ["300", "400", "500", "600", "700", "800", "900"]) {
      expect(nextLayout).toContain(`"${w}"`);
    }
  });
});

describe("Performans: görsel sıkıştırma sözleşmesi (iki istemci aynı)", () => {
  it("Flutter: uzun kenar 1600, kalite 82, yedek 65", () => {
    expect(flutterImg).toContain("maxLongEdge = 1600");
    expect(flutterImg).toContain("quality: 82");
    expect(flutterImg).toContain("quality: 65");
  });

  it("Next: aynı sözleşme (1600 / 82 / mozjpeg)", () => {
    expect(nextSikistir).toContain("UZUN_KENAR = 1600");
    expect(nextSikistir).toContain("KALITE = 82");
    expect(nextSikistir).toContain("mozjpeg");
  });
});

describe("Performans: ölçüm kapısı DÜRÜST durumu", () => {
  it("zoom engellenmiyor (kullanıcı tarafı hız algısı)", () => {
    expect(nextLayout).toContain("maximumScale: 5");
  });

  it.todo(
    "LCP/INP/CLS sayısal bütçesi — gerçek üretim ölçümünden SONRA kilitlenir (sözleşme notu). " +
      "Ölçüm alınmadan eşik uydurmak yasak.",
  );
  it.todo(
    "JS bundle boyut bütçesi kapısı — `next build` çıktısı ölçülüp hedef belirlenince eklenir (✗ → ✓).",
  );
});
