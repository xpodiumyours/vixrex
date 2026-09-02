import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";
import { findTimeRange, normalizeWeekMap, weekMapFromPlainString } from "../src/lib/workingHours";

const fixture = JSON.parse(
  readFileSync(resolve(__dirname, "../../shared/working_hours_contract.json"), "utf8"),
) as { working_hours: unknown };

describe("çalışma saatleri ortak sözleşmesi", () => {
  it("1-7 örneğini start/end/active kaybı olmadan okur", () => {
    expect(normalizeWeekMap(fixture.working_hours)).toEqual(fixture.working_hours);
  });

  it("eski metin biçimi fallback davranışını korur", () => {
    const parsed = weekMapFromPlainString("09:00 - 20:00");
    expect(parsed?.["1"]).toEqual({ start: "09:00", end: "20:00", active: true });
    expect(parsed?.["7"].active).toBe(false);
  });
});

/**
 * Serbest metin çıkarımı için eklendi (2026-09-02) — weekMapFromPlainString
 * artık findTimeRange'i kullanıyor (aynı regex, TEK DOĞRU KAYNAK). Bu
 * blok hem yeni fonksiyonu hem de eski davranışın bozulmadığını kanıtlar.
 */
describe("findTimeRange — serbest metin çıkarımının TEK DOĞRU KAYNAĞI", () => {
  it("bir cümlenin ortasındaki saat aralığını bulur (anchor yok)", () => {
    expect(findTimeRange("Hafta içi 09:00 - 18:00 arası açığız, gelin bekleriz.")).toEqual({
      start: "09:00",
      end: "18:00",
      raw: "09:00 - 18:00",
    });
  });

  it("en/tire ayracını da kabul eder", () => {
    expect(findTimeRange("9:00–21:00")).toEqual({ start: "09:00", end: "21:00", raw: "09:00 - 21:00" });
  });

  it("hiç saat aralığı yoksa null döner", () => {
    expect(findTimeRange("Bugün müsait değilim.")).toBeNull();
  });

  it("weekMapFromPlainString ile aynı temel vakada eski davranış korunuyor (regresyon)", () => {
    const eski = weekMapFromPlainString("09:00 - 20:00");
    const yeni = findTimeRange("09:00 - 20:00");
    expect(eski?.["1"]).toEqual({ start: yeni?.start, end: yeni?.end, active: true });
  });
});
