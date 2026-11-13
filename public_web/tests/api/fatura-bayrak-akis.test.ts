import { afterEach, describe, expect, it } from "vitest";
import { akis } from "@/lib/faturaKartPreset";

const eskiDeger = process.env.PRESET_AKIS;
afterEach(() => {
  if (eskiDeger === undefined) delete process.env.PRESET_AKIS;
  else process.env.PRESET_AKIS = eskiDeger;
});

describe("PRESET_AKIS kararı (runtime bayrak)", () => {
  it("açıkça mevcut seçilirse mevcut döner", () => {
    process.env.PRESET_AKIS = "mevcut";
    expect(akis()).toBe("mevcut");
  });
  it("açıkça yeni seçilirse yeni döner", () => {
    process.env.PRESET_AKIS = "yeni";
    expect(akis()).toBe("yeni");
  });
  it("tanımsızsa veya geçersizse mevcut döner", () => {
    delete process.env.PRESET_AKIS;
    expect(akis()).toBe("mevcut");
    process.env.PRESET_AKIS = "gecersiz";
    expect(akis()).toBe("mevcut");
  });
});
