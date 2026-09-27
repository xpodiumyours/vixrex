import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const globals = readFileSync(
  resolve(__dirname, "../src/app/globals.css"),
  "utf-8"
);
const layout = readFileSync(
  resolve(__dirname, "../src/app/layout.tsx"),
  "utf-8"
);

const themeBlock = globals.slice(
  globals.indexOf("@theme {"),
  globals.indexOf("}", globals.indexOf("@theme {")) + 1
);

/**
 * Tasarım zemini sözleşmesi (#344, 2026-08-26).
 *
 * İki gerçek sorun vardı:
 *   1. Dosyada hiç `@theme` bloğu yoktu, yani `:root`'taki tokenlar
 *      Tailwind'e görünmüyordu. `layout.tsx` yıllardır `font-outfit`
 *      sınıfını yazıyordu ama o sınıf hiç üretilmemişti.
 *   2. Fontlar Google Fonts `@import`'uyla, render'ı bloklayarak
 *      geliyordu ve yalnız 300-800 ağırlıklarını kapsıyordu — landing
 *      başlıklarının tamamı ise w900.
 *
 * Bu test iki şeyi korur: @theme'in EKLEYİCİ kalması (vitrin paletine
 * dokunmaması) ve fontların next/font'tan gelmeye devam etmesi.
 */
describe("tasarım zemini — ekleyici @theme, next/font ile fontlar", () => {
  it("@theme bloğu var", () => {
    expect(globals).toContain("@theme {");
  });

  it("@theme yalnız yeni anahtar tanımlar, Tailwind varsayılanını ezmez", () => {
    const anahtarlar = [...themeBlock.matchAll(/^\s*(--[a-z0-9-]+):/gm)].map(
      (m) => m[1]
    );
    expect(anahtarlar.length).toBeGreaterThan(0);
    for (const anahtar of anahtarlar) {
      const izinli =
        anahtar === "--font-outfit" ||
        anahtar === "--font-vitrin-display" ||
        anahtar.startsWith("--color-lp-") ||
        anahtar.startsWith("--shadow-lp-") ||
        anahtar.startsWith("--spacing-lp-") ||
        anahtar.startsWith("--container-lp");
      expect(izinli, `beklenmeyen tema anahtarı: ${anahtar}`).toBe(true);
    }
  });

  it("vitrin paleti ayrı kalır — landing renkleri lp- önekiyle yaşar", () => {
    // 29 canlı vitrin --primary: #38A0E4 ailesini kullanıyor. Landing'in
    // #147DFF ailesi onu EZMEMELİ; iki palet yan yana durur.
    expect(globals).toContain("--primary: #38A0E4");
    expect(themeBlock).toContain("--color-lp-primary: #147DFF");
    expect(themeBlock).not.toContain("--color-primary:");
  });

  it("Google Fonts @import kaldırıldı, fontlar next/font'tan gelir", () => {
    expect(globals).not.toContain("fonts.googleapis.com");
    expect(layout).toContain('from "next/font/local"');
    expect(layout).toContain("--font-outfit-src");
  });

  it("Outfit w900 dahil yükleniyor — landing başlıkları Black", () => {
    const outfitBlok = layout.slice(
      layout.indexOf("const outfit = localFont("),
      layout.indexOf("const instrumentSerif")
    );
    expect(outfitBlok).toContain('"900"');
  });

  it("font-outfit sınıfı artık gerçek bir utility", () => {
    expect(themeBlock).toContain("--font-outfit:");
    expect(layout).toContain("font-outfit");
  });
});
