import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import manifest from "../src/app/manifest";

/**
 * Telefonda "uygulama gibi" davranmanın kilidi.
 *
 * 2026-09-09 ölçümü: vixrex.com'da manifest YOK, apple-touch-icon YOK,
 * standalone YOK, ana ekran ikonu YOK. Site telefonda açıldığında tarayıcı
 * çubuğuyla bir web sayfası olarak duruyordu.
 *
 * Bu ayrıca APK kararının ÖNKOŞULU: Google, bir siteyi Android kabuğuna
 * (Trusted Web Activity) sarabilmek için Chrome'un kurulabilirlik ölçütlerini
 * şart koşuyor.
 *
 * Ölçütler (web.dev/articles/install-criteria): name/short_name, icons içinde
 * 192px VE 512px, start_url, display ∈ {fullscreen, standalone, minimal-ui,
 * window-controls-overlay}, prefer_related_applications yok/false.
 * Service worker şart değil.
 */

const PUBLIC = resolve(__dirname, "../public");
const m = manifest();

describe("manifest — kurulabilirlik ölçütleri", () => {
  it("ad ve başlangıç adresi tanımlı", () => {
    expect(m.name || m.short_name).toBeTruthy();
    expect(m.start_url).toBeTruthy();
  });

  it("display kurulabilir bir değer", () => {
    expect(["fullscreen", "standalone", "minimal-ui", "window-controls-overlay"]).toContain(
      m.display
    );
  });

  it("192 ve 512 piksel ikon var ve dosyalar gerçekten duruyor", () => {
    const boyutlar = (m.icons ?? []).map((i) => i.sizes);
    expect(boyutlar, "Chrome 192 ve 512 ister").toContain("192x192");
    expect(boyutlar).toContain("512x512");

    for (const ikon of m.icons ?? []) {
      const yol = resolve(PUBLIC, String(ikon.src).replace(/^\//, ""));
      expect(existsSync(yol), `ikon dosyası yok: ${ikon.src}`).toBe(true);
    }
  });

  it("Android kırpması için maskeli ikon var", () => {
    const maskeli = (m.icons ?? []).some((i) => i.purpose === "maskable");
    expect(
      maskeli,
      "maskable ikon olmadan Android ikonu kenarlarından kırpar"
    ).toBe(true);
  });

  it("prefer_related_applications kurulumu engellemiyor", () => {
    const alan = (m as Record<string, unknown>).prefer_related_applications;
    expect(alan === undefined || alan === false).toBe(true);
  });

  it("iOS için apple-touch-icon ve standalone tanımlı", () => {
    // iOS manifest'i ana ekran ikonu için okumaz; bunlar layout.tsx'te
    // metadata olarak verilir. Kaldırılırsa iPhone'da ikon yerine sayfanın
    // ekran görüntüsü kullanılır ve site kendi penceresinde açılmaz.
    const layout = readFileSync(resolve(__dirname, "../src/app/layout.tsx"), "utf8");
    expect(layout).toContain("apple-icon-180.png");
    expect(layout).toContain("appleWebApp");
    // Next.js standart adı yazıyor; eski iOS yalnız Apple'ın adını tanıyor.
    expect(layout).toContain("apple-mobile-web-app-capable");
    expect(existsSync(resolve(PUBLIC, "apple-icon-180.png"))).toBe(true);
  });

  it("açılış zemini uygulamanın ilk boyadığı renkle aynı", () => {
    // Farklıysa açılışta beyaz/ters renk parlaması olur.
    expect(m.background_color).toBe("#050B1A");
  });
});
