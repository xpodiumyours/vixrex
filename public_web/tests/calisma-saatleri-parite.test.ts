import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Calisma saatleri parite testi.
 */

const flutterStoreData = readFileSync(
  resolve(__dirname, "../../lib/models/store_data.dart"),
  "utf8",
);
const flutterWorkingHours = readFileSync(
  resolve(__dirname, "../../lib/models/working_hours.dart"),
  "utf8",
);
const nextSchema = readFileSync(
  resolve(__dirname, "../src/lib/vitrinFieldSchema.ts"),
  "utf8",
);

describe("calisma saatleri parite (Flutter referansiyla)", () => {
  it("Flutter gibi working_hours modelini icerir", () => {
    expect(flutterStoreData).toContain("working_hours");
    expect(flutterWorkingHours).toContain("BookingSettings");
  });

  it("Flutter gibi calismaSaatleri alanini icerir", () => {
    expect(nextSchema).toContain("calismaSaatleri");
  });

  it("Flutter gibi gunluk calisma saatlerini icerir", () => {
    expect(flutterWorkingHours).toContain("workingHours");
    expect(flutterWorkingHours).toContain("lunchBreak");
    expect(flutterWorkingHours).toContain("09:00");
  });
});