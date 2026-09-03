import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

/**
 * Kirala tekniği senkron bekçisi (Akış 2 paritesi, 2026-09-03).
 *
 * NEDEN VAR
 * Kiralama reçetesi web'de İKİ yerde yaşıyor: `/rent-demo` köprü sayfası
 * (Flutter, eski APK'lar ve vitrin CTA'sı buraya gider) ve Keşfet kartındaki
 * inline akış (`useKesfetKirala`). İkisi de aynı zincire çıkmak zorunda
 * (hesaplı `/api/rent-demo/hesap`, misafir reCAPTCHA + native form POST →
 * owner-session → `/v/:slug`). Biri değişip diğeri unutulursa iki yüzey
 * farklı kiralar — bu test o ayrışmayı kilitler.
 *
 * Kapsam bilerek dar: tam davranış değil, üç çapa dizenin iki dosyada da
 * durması. Reçete bilerek değişirse İKİ dosya + bu test birlikte güncellenir.
 */
describe("Kirala reçetesi köprü + inline akışta aynı", () => {
  const kopru = oku("app/rent-demo/page.tsx");
  const inline = oku("lib/useKesfetKirala.ts");

  it("hesaplı yol aynı API'ye gider", () => {
    expect(kopru).toContain("/api/rent-demo/hesap");
    expect(inline).toContain("/api/rent-demo/hesap");
  });

  it("reCAPTCHA yokluğunda aynı yedek jetonla devam edilir", () => {
    expect(kopru).toContain("recaptcha-unavailable");
    expect(inline).toContain("recaptcha-unavailable");
  });

  it("iki yol da sahip-oturumu zincirine çıkar", () => {
    expect(kopru).toContain("owner-session");
    expect(inline).toContain("owner-session");
  });

  it("misafir yolu iki tarafta da native form POST kullanır", () => {
    expect(kopru).toContain('method="POST"');
    expect(kopru).toContain('action="/api/rent-demo"');
    // Inline akış formu kartta kurar, hook tetikler — zincir aynı.
    expect(inline).toContain("formRef.current");
  });
});
