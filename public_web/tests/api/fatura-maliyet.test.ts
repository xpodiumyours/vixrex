import { describe, expect, it } from "vitest";
import { dolarHesapla } from "@/lib/faturaGoru";
import { gunlukTavanDolduMu, istanbulGunuBaslangici } from "@/lib/faturaMaliyet";

describe("fatura maliyet tavanı", () => {
  it("resmi fiyattan dolar hesaplar, akıl yürütme tokenını ikinci kez saymaz", () => {
    expect(dolarHesapla(1_000_000, 1_000_000, 0)).toBeCloseTo(1.4, 6);
    expect(dolarHesapla(1_000_000, 0, 1_000_000)).toBeCloseTo(0.02, 6);
  });

  it("mağaza günü bir dolar dolunca kapanır", () => {
    expect(gunlukTavanDolduMu(0.99)).toBe(false);
    expect(gunlukTavanDolduMu(1)).toBe(true);
  });

  it("gün İstanbul gece yarısından başlar", () => {
    const simdi = new Date("2026-10-06T12:00:00.000Z");
    const baslangic = new Date(istanbulGunuBaslangici(simdi));
    expect(baslangic.getTime()).toBeLessThanOrEqual(simdi.getTime());
    expect(simdi.getTime() - baslangic.getTime()).toBeLessThan(24 * 60 * 60 * 1000);
  });
});
