import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

function yorumsuz(kaynak: string): string {
  return kaynak
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
}

const sitemap = yorumsuz(
  readFileSync(resolve(__dirname, "../src/app/sitemap.xml/route.ts"), "utf-8")
);
const robots = readFileSync(
  resolve(__dirname, "../src/app/robots.txt/route.ts"),
  "utf-8"
);
const vitrin = yorumsuz(
  readFileSync(resolve(__dirname, "../src/app/v/[slug]/page.tsx"), "utf-8")
);
const urun = yorumsuz(
  readFileSync(
    resolve(__dirname, "../src/app/v/[slug]/urun/[productSlug]/page.tsx"),
    "utf-8"
  )
);

/**
 * #345 — site haritası demo/kiralık vitrinlerle doluydu.
 *
 * Demo vitrinler gerçek bir işletme değil, kiralanmayı bekleyen
 * şablonlardır. Arama sonuçlarında gerçek müşteri vitrinleriyle yarışırlarsa
 * hem ziyaretçiyi yanıltır hem de aynı içeriği çoğaltmış oluruz.
 *
 * Kapsam kararı (2026-08-26): YALNIZ `is_demo`. Kiralanmış kopyalar
 * (`cloned_from_slug` dolu ama `is_demo` false) gerçek müşterilerin
 * vitrinidir; onları gizlemek ödeme yapan işletmeyi cezalandırmak olurdu.
 */
describe("site haritası ve indeksleme kuralları (#345)", () => {
  it("site haritası demo vitrinleri dışarıda bırakır", () => {
    expect(sitemap).toContain('.eq("is_demo", false)');
  });

  it("demo vitrinin yazıları da dışarıda kalır", () => {
    // Makale sorgusu store_slug üzerinden geliyor, vitrin süzgecinden
    // habersiz — ayrıca süzülmesi gerekiyor.
    expect(sitemap).toContain("yayindakiSluglar");
  });

  it("platform sayfaları site haritasına girer (#344)", () => {
    expect(sitemap).toContain('yol: "/"');
    expect(sitemap).toContain('yol: "/kesfet"');
    expect(sitemap).toContain("BUSINESS_CATEGORIES.map");
    expect(sitemap).toContain('yol: "/legal/terms"');
  });

  it("robots.txt içeriksiz köprü sayfasını taramaya kapatır", () => {
    expect(robots).toContain("Disallow: /rent-demo");
  });

  it("demo vitrin sayfaları noindex, ama follow açık", () => {
    expect(vitrin).toContain("store.is_demo");
    expect(vitrin).toContain("robots: { index: false, follow: true }");
    expect(urun).toContain("store.is_demo");
    expect(urun).toContain("robots: { index: false, follow: true }");
  });
});
