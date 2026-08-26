import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

function yorumsuz(kaynak: string): string {
  return kaynak
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
}

const kart = yorumsuz(
  readFileSync(
    resolve(__dirname, "../src/components/kesfet/VitrinKarti.tsx"),
    "utf-8"
  )
);
const seritKaynak = yorumsuz(
  readFileSync(
    resolve(__dirname, "../src/components/kesfet/KategoriSeridi.tsx"),
    "utf-8"
  )
);

/**
 * Keşfet kartındaki "Kirala" düğmesi — vitrin sayfasındaki CTA ile aynı
 * kuralı taşır (bkz. demo-kirala-cta-contract.test.ts).
 *
 * 2026-08-15'te kapatılan açık: `/api/rent-demo` GET'te hiçbir kimlik ya da
 * oran sınırlaması olmadan veritabanına yazıyordu. Doğru yol, reCAPTCHA
 * doğrulamasını yapan `/rent-demo` köprü sayfasıdır. Kart bu köprüyü
 * atlarsa aynı açık yeni bir yüzeyden geri gelir.
 */
describe("Keşfet kartı 'Kirala' CTA'sı", () => {
  it("güvenli köprü sayfasına gider, doğrudan API'ye değil", () => {
    expect(kart).toContain("/rent-demo?slug=");
    expect(kart).not.toContain("/api/rent-demo");
  });

  it("fiyat vaadi vitrin CTA'sıyla aynı", () => {
    expect(kart).toContain("Aylık 299 TL");
    expect(kart).toContain("14 gün ücretsiz dene");
  });

  it("kiralık ayrımı is_demo'dan gelen alana bakar", () => {
    expect(kart).toContain("vitrin.kiralikMi");
  });

  it("kategori süzgeci düz bağlantı — istemci bileşeni değil", () => {
    // JavaScript ile süzülen bir liste kategorileri arama motorundan gizler.
    expect(seritKaynak).not.toContain('"use client"');
    expect(seritKaynak).toContain('href={`/kesfet/');
  });
});
