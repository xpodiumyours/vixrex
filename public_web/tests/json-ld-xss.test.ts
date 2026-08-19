import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";
import { safeJsonLdHtml } from "@/lib/jsonLd";

// V-02/V-03/V-17/V-18 (attack-vectors.md, 2026-08-18) nöbetçisi.
//
// JSON.stringify çıktısında `<` kaçmaz. Mağaza/ürün/yazı adı gibi
// kullanıcı girdisi JSON-LD içine gömülüp dangerouslySetInnerHTML ile
// basılıyor — adına `</script><script>...` yazan biri erken kapanan
// bloğun arkasına çalışan bir <script> ekleyebilir (saklı XSS).

describe("safeJsonLdHtml", () => {
  it("< karakterini kaçırır — </script> olarak okunamaz", () => {
    const kotu = { name: '</script><script>alert(1)</script>' };
    const cikti = safeJsonLdHtml(kotu);
    expect(cikti).not.toContain("</script>");
    expect(cikti).toContain("\\u003cscript>");
  });

  it("normal veriyi bozmaz — JSON.parse ile geri okunabilir", () => {
    const veri = { name: "Kadıköy Butik", price: 199.9, ok: true };
    const cikti = safeJsonLdHtml(veri);
    expect(JSON.parse(cikti)).toEqual(veri);
  });
});

// Kapsam nöbetçisi: 4 sayfanın hepsi JSON.stringify yerine safeJsonLdHtml
// kullanmalı. Yeni bir dangerouslySetInnerHTML + ld+json eklenirse ve
// safeJsonLdHtml kullanılmazsa bu test kırmızı olur.
describe("Tüm JSON-LD scriptleri safeJsonLdHtml kullanıyor", () => {
  const dosyalar = [
    "../src/app/v/[slug]/page.tsx",
    "../src/app/v/[slug]/urun/[productSlug]/page.tsx",
    "../src/app/v/[slug]/yazilar/page.tsx",
    "../src/app/v/[slug]/yazilar/[articleSlug]/page.tsx",
  ];

  for (const yol of dosyalar) {
    it(`${yol} içinde çıplak JSON.stringify(...) ld+json'a basılmıyor`, () => {
      const icerik = readFileSync(resolve(__dirname, yol), "utf-8");
      // Yalnız type="application/ld+json" script'lerine bağlı olan bloklar —
      // dosyada başka amaçlı dangerouslySetInnerHTML (ör. sanitize edilmiş
      // yazı gövdesi) varsa ona dokunmayız.
      const ldBloklari = icerik.match(
        /type="application\/ld\+json"\s*\n?\s*dangerouslySetInnerHTML=\{\{\s*__html:\s*[^}]+\}\}/g
      );
      expect(ldBloklari).not.toBeNull();
      for (const blok of ldBloklari ?? []) {
        expect(blok).not.toMatch(/JSON\.stringify/);
        expect(blok).toContain("safeJsonLdHtml");
      }
    });
  }
});
