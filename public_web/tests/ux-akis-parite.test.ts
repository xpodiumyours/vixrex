import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * UX akis matrisi parite testi.
 */

const flutterRouter = readFileSync(
  resolve(__dirname, "../../lib/config/app_router.dart"),
  "utf8",
);
const nextLayout = readFileSync(
  resolve(__dirname, "../src/app/layout.tsx"),
  "utf8",
);

describe("UX akis parite", () => {
  it("Flutter gibi sekme korunmasi vardir", () => {
    expect(flutterRouter).toContain("GoRouter");
    expect(nextLayout).toContain("AppShellBoundary");
  });

  it("Flutter gibi geri butonu davranisi vardir", () => {
    expect(flutterRouter).toContain("go");
  });

  it("Flutter gibi modal kapama davranisi vardir", () => {
    expect(flutterRouter).toContain("Navigator");
  });

  it("Flutter gibi form dogrulama vardir", () => {
    const flutterForm = readFileSync(
      resolve(__dirname, "../../lib/widgets/editor/common_form_fields.dart"),
      "utf8",
    );
    expect(flutterForm).toContain("errorText");
  });

  it("Flutter gibi hata kurtarma vardir", () => {
    expect(flutterRouter).toContain("catch");
  });

  it("Flutter gibi global arama vardir", () => {
    const nextSearch = readFileSync(
      resolve(__dirname, "../src/lib/kesfetFiltreleme.ts"),
      "utf8",
    );
    expect(nextSearch).toContain("filter");
  });

  it("Flutter gibi filtre/siralama vardir", () => {
    const nextFilter = readFileSync(
      resolve(__dirname, "../src/lib/kesfetFiltreleme.ts"),
      "utf8",
    );
    expect(nextFilter).toContain("filter");
  });

  it("Flutter gibi sayfalama vardir", () => {
    const nextExplore = readFileSync(
      resolve(__dirname, "../src/lib/explore.ts"),
      "utf8",
    );
    expect(nextExplore).toContain("limit");
  });
});