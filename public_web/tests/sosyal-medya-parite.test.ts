import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Sosyal medya parite testi.
 */

const flutterStoreData = readFileSync(
  resolve(__dirname, "../../lib/models/store_data.dart"),
  "utf8",
);
const nextSchema = readFileSync(
  resolve(__dirname, "../src/lib/vitrinFieldSchema.ts"),
  "utf8",
);

describe("sosyal medya parite (Flutter referansiyla)", () => {
  it("Flutter gibi instagram alanini icerir", () => {
    expect(flutterStoreData).toContain("instagram");
    expect(nextSchema).toContain("instagram");
  });

  it("Flutter gibi website alanini icerir", () => {
    expect(flutterStoreData).toContain("website");
    expect(nextSchema).toContain("website");
  });

  it("Flutter gibi marketplace linklerini icerir", () => {
    expect(flutterStoreData).toContain("marketplace");
    expect(nextSchema).toContain("references_link");
  });
});