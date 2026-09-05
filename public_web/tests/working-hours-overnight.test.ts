import { describe, expect, it } from "vitest";
import { resolveOpenState, type WeekMap } from "../src/lib/workingHours";

const overnightMonday: WeekMap = {
  "1": { start: "22:00", end: "02:00", active: true },
  "2": { start: "00:00", end: "00:00", active: false },
};

describe("resolveOpenState — overnight çalışma saatleri", () => {
  it("başlangıç gününde 22:00 sonrası açık sayar", () => {
    // 2026-09-07 20:00 UTC = Pazartesi 23:00 Europe/Istanbul.
    const state = resolveOpenState(
      overnightMonday,
      "Açık",
      new Date("2026-09-07T20:00:00.000Z"),
    );

    expect(state.isOpen).toBe(true);
    expect(state.label).toBe("Açık");
    expect(state.detail).toBe("02:00 kadar");
    expect(state.source).toBe("hours");
  });

  it("ertesi gün 02:00 öncesi önceki günün overnight aralığını sürdürür", () => {
    // 2026-09-07 22:00 UTC = Salı 01:00 Europe/Istanbul.
    const state = resolveOpenState(
      overnightMonday,
      "Açık",
      new Date("2026-09-07T22:00:00.000Z"),
    );

    expect(state.isOpen).toBe(true);
    expect(state.detail).toBe("02:00 kadar");
  });

  it("ertesi gün kapanıştan sonra kapalı sayar", () => {
    // 2026-09-08 00:00 UTC = Salı 03:00 Europe/Istanbul.
    const state = resolveOpenState(
      overnightMonday,
      "Açık",
      new Date("2026-09-08T00:00:00.000Z"),
    );

    expect(state.isOpen).toBe(false);
    expect(state.label).toBe("Kapalı");
  });

  it("manuel Kapalı durumu saatlerden önce kazanmayı sürdürür", () => {
    const state = resolveOpenState(
      overnightMonday,
      "Kapalı",
      new Date("2026-09-07T20:00:00.000Z"),
    );

    expect(state).toEqual({ isOpen: false, label: "Kapalı", source: "manual" });
  });

  it("normal gündüz aralığını bozmaz", () => {
    const map: WeekMap = {
      "1": { start: "09:00", end: "18:00", active: true },
    };

    // Pazartesi 12:00 Europe/Istanbul.
    const state = resolveOpenState(
      map,
      "Açık",
      new Date("2026-09-07T09:00:00.000Z"),
    );

    expect(state.isOpen).toBe(true);
    expect(state.detail).toBe("18:00 kadar");
  });
});
