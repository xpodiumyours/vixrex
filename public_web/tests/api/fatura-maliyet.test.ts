import { describe, expect, it, vi } from "vitest";
import { dolarHesapla } from "@/lib/faturaGoru";
import { ARAMA_UCETI_USD, aramaCagrisiSigarMi, gunlukTavanDolduMu, istanbulGunuBaslangici, kullanimKaydet } from "@/lib/faturaMaliyet";

describe("fatura maliyet tavanı", () => {
  it("resmi fiyattan dolar hesaplar, akıl yürütme tokenını ikinci kez saymaz", () => {
    expect(dolarHesapla(1_000_000, 1_000_000, 0)).toBeCloseTo(1.4, 6);
    expect(dolarHesapla(1_000_000, 0, 1_000_000)).toBeCloseTo(0.02, 6);
  });

  it("mağaza günü bir dolar dolunca kapanır", () => {
    expect(gunlukTavanDolduMu(0.99)).toBe(false);
    expect(gunlukTavanDolduMu(1)).toBe(true);
  });

  it("arama ücreti tavana sığmazsa yeni arama açılmaz", () => {
    expect(ARAMA_UCETI_USD).toBe(0.02);
    expect(aramaCagrisiSigarMi(0.97)).toBe(true);
    expect(aramaCagrisiSigarMi(0.98)).toBe(false);
  });

  it("sağlayıcının gerçek ücretini bütçe rezervinden ayrı kaydeder", async () => {
    const insert = vi.fn(async () => ({ error: null }));
    const admin = { from: () => ({ insert }) } as never;
    await kullanimKaydet(admin, "test-store", {
      girdiToken: 100, ciktiToken: 10, akilToken: 0, maliyet: 0.024, gercekMaliyet: 0.004,
    }, 0.02);
    expect(insert).toHaveBeenCalledWith(expect.objectContaining({
      cost_usd: 0.024, provider_cost_usd: 0.004,
      budget_reserve_usd: 0.02, cost_basis: "reported",
    }));
  });

  it("OpenRouter usage.cost yoksa sahte gerçek maliyet yazılmaz", async () => {
    const insert = vi.fn(async () => ({ error: null }));
    const admin = { from: () => ({ insert }) } as never;
    await kullanimKaydet(admin, "test-store", {
      girdiToken: 100, ciktiToken: 10, akilToken: 0, maliyet: 0.025,
    }, 0.02);
    expect(insert).toHaveBeenCalledWith(expect.objectContaining({
      provider_cost_usd: null, budget_reserve_usd: 0.02,
      cost_basis: "estimated",
    }));
  });

  it("gün İstanbul gece yarısından başlar", () => {
    const simdi = new Date("2026-10-06T12:00:00.000Z");
    const baslangic = new Date(istanbulGunuBaslangici(simdi));
    expect(baslangic.getTime()).toBeLessThanOrEqual(simdi.getTime());
    expect(simdi.getTime() - baslangic.getTime()).toBeLessThan(24 * 60 * 60 * 1000);
  });
});
