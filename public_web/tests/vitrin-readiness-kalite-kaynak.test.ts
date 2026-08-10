import { describe, expect, it } from "vitest";
import { hazirlikRaporu } from "../src/lib/vitrinReadiness";
import { VITRIN_FIELDS } from "../src/lib/vitrinFieldSchema";

// Faz 5/6, Issue #91 — vitrinReadiness.ts'teki KALITE_ALANLARI artık elle
// yazılmış ayrı bir liste değil, şemadaki `kalite` işaretinden geliyor
// (TEMEL_ALANLAR'ın `zorunlu`'dan gelmesiyle aynı desen). Bu test, taşıma
// sırasında davranışın DEĞİŞMEDİĞİNİ — yalnız kaynağın değiştiğini —
// doğrular: tamamen boş bir taslakta, eskiden elle sayılan 7 alanın hepsi
// hâlâ "kalite" önemiyle eksikler listesinde çıkmalı.

describe("hazırlık raporu — kalite önemi artık şemadan geliyor", () => {
  const bosTaslak: Record<string, unknown> = {};
  const rapor = hazirlikRaporu(bosTaslak);
  const kaliteEksikAnahtarlari = new Set(
    rapor.eksikler.filter((e) => e.onem === "kalite").map((e) => e.anahtar)
  );

  it("şemadaki her kalite:true alan, boş taslakta 'kalite' önemiyle eksik çıkar", () => {
    const kaliteAlanlari = VITRIN_FIELDS.filter((f) => f.kalite).map(
      (f) => f.anahtar
    );
    expect(kaliteAlanlari.length).toBeGreaterThan(0);
    for (const anahtar of kaliteAlanlari) {
      expect(kaliteEksikAnahtarlari.has(anahtar), anahtar).toBe(true);
    }
  });

  it("kalite:true OLMAYAN, zorunlu da olmayan bir alan hiç eksik sayılmaz (isteğe bağlı, eksikler listesine girmez)", () => {
    const digerAlan = VITRIN_FIELDS.find(
      (f) => !f.kalite && !f.zorunlu
    );
    expect(digerAlan).toBeDefined();
    const eksik = rapor.eksikler.find((e) => e.anahtar === digerAlan?.anahtar);
    expect(eksik).toBeUndefined();
  });
});
