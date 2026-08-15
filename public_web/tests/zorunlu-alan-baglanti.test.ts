import { describe, expect, it } from "vitest";
import { hazirlikRaporu } from "../src/lib/vitrinReadiness";
import { VITRIN_FIELDS } from "../src/lib/vitrinFieldSchema";

/**
 * Faz F (Tek Asistan planı) "sapma testi" — Next.js tarafı.
 *
 * PLAN.md: "CI'da sapma testi: iki taraf aynı taslak verisine aynı
 * 'sıradaki alan' cevabını vermeli." Dart ve TypeScript aynı süreçte
 * çalışmadığı için gerçek çapraz-dil çağrısı yapılmıyor; her iki taraf
 * ayrı ayrı KENDİ şema-bağlantısının eksiksiz olduğunu kanıtlıyor. Dart
 * tarafındaki eşleniği: test/zorunlu_alan_baglanti_test.dart.
 *
 * Next.js tarafında `doluMu()` şemadan JENERİK okuduğu için (Dart'ın
 * elle yazılmış `_alanDolu` switch'inin aksine) "yeni alan eklenip
 * sessizce dolu sayılma" riski yapısal olarak yok — ama bu test yine de
 * her zorunlu alanın gerçekten TEK BAŞINA eksikken doğru tespit
 * edildiğini kanıtlar. Asıl amaç: iki taraf aynı zorunlu alan kümesini
 * aynı şekilde yorumluyor mu, ampirik kanıt.
 */
describe("şemadaki her zorunlu alan hazirlikRaporu'da ayrı ele alınır", () => {
  const zorunluAlanlar = VITRIN_FIELDS.filter((a) => a.zorunlu);

  it("en az bir zorunlu alan var (kurulum akışı boşsa test anlamsız)", () => {
    expect(zorunluAlanlar.length).toBeGreaterThan(0);
  });

  for (const eksikAlan of zorunluAlanlar) {
    it(`yalnız "${eksikAlan.anahtar}" boşken eksikler listesinde tek başına görünür`, () => {
      const draft: Record<string, unknown> = {};
      for (const alan of zorunluAlanlar) {
        if (alan.anahtar === eksikAlan.anahtar) continue;
        draft[alan.kolon] = "dolu";
      }

      const rapor = hazirlikRaporu(draft);
      const eksikAnahtarlar = rapor.eksikler
        .filter((e) => e.onem === "temel")
        .map((e) => e.anahtar);

      expect(
        eksikAnahtarlar,
        `"${eksikAlan.anahtar}" boşken temel eksikler listesi ${JSON.stringify(
          eksikAnahtarlar,
        )} — beklenen: ["${eksikAlan.anahtar}"]. alanOnemi()/TEMEL_ALANLAR ` +
          "bu alanı doğru sınıflandırmıyor olabilir.",
      ).toEqual([eksikAlan.anahtar]);
    });
  }
});
