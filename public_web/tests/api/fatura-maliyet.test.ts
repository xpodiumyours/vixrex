import { describe, expect, it, vi } from "vitest";
import { dolarHesapla } from "@/lib/faturaGoru";
import { ARAMA_UCETI_USD, aramaCagrisiSigarMi, belgeMaliyetOzeti, gunlukTavanDolduMu, istanbulGunuBaslangici, kullanimKaydet } from "@/lib/faturaMaliyet";

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

  it("maliyet her faturanın gerçek SHA-256 kimliğine bağlanır", async () => {
    const insert = vi.fn(async () => ({ error: null }));
    const id = "e".repeat(64);
    await kullanimKaydet({ from: () => ({ insert }) } as never, "store-1", {
      girdiToken: 100, ciktiToken: 30, akilToken: 0, maliyet: 0.033, gercekMaliyet: 0.013,
    }, 0.02, id);
    expect(insert).toHaveBeenCalledWith(expect.objectContaining({
      document_fingerprint: id, provider_cost_usd: 0.013,
    }));
  });

  it("belgelerin maliyetini karıştırmadan tahmini ve gerçek tutarı ayrı verir", async () => {
    const query = {
      select: vi.fn(), eq: vi.fn(),
    };
    query.select.mockReturnValue(query);
    query.eq.mockReturnValue(query);
    const records = [
      { cost_usd: 0.023, provider_cost_usd: 0.003, budget_reserve_usd: 0.02, cost_basis: "reported" },
      { cost_usd: 0.025, provider_cost_usd: null, budget_reserve_usd: 0.02, cost_basis: "estimated" },
    ];
    query.eq.mockReturnValueOnce(query).mockResolvedValueOnce({ data: records, error: null });
    const id = "a".repeat(64);
    const sonuc = await belgeMaliyetOzeti({ from: () => query } as never, "store-1", id);
    expect(query.eq).toHaveBeenCalledWith("document_fingerprint", id);
    expect(sonuc.kayitSayisi).toBe(2);
    expect(sonuc.gercekUsd).toBeCloseTo(0.003);
    expect(sonuc.tahminiUsd).toBeCloseTo(0.005);
    expect(sonuc.ayrilanButceUsd).toBeCloseTo(0.04);
    expect(sonuc.tahminiKayitSayisi).toBe(1);
  });

  it("gün İstanbul gece yarısından başlar", () => {
    const simdi = new Date("2026-10-06T12:00:00.000Z");
    const baslangic = new Date(istanbulGunuBaslangici(simdi));
    expect(baslangic.getTime()).toBeLessThanOrEqual(simdi.getTime());
    expect(simdi.getTime() - baslangic.getTime()).toBeLessThan(24 * 60 * 60 * 1000);
  });
});
