import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";
import { normalizeWeekMap, weekMapFromPlainString } from "../src/lib/workingHours";

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
