import { describe, expect, it } from "vitest";
import { existsSync, readFileSync } from "fs";
import { resolve } from "path";

const pagePath = resolve(__dirname, "../src/app/v/[slug]/page.tsx");
const panelPath = resolve(__dirname, "../src/app/v/[slug]/PreviewEditorPanel.tsx");
const landingPath = resolve(__dirname, "../../lib/screens/landing_screen.dart");
const migrationPath = resolve(
  __dirname,
  "../../supabase/migrations/20260803190512_20260803160000_protect_landing_demos.sql"
);

describe("landing demo taslak önizleme sözleşmesi", () => {
  it("Next.js vitrini ve düzenleme paneli korunur", () => {
    const pageSource = readFileSync(pagePath, "utf-8");

    expect(pageSource).toContain('import PreviewEditorPanel from "./PreviewEditorPanel"');
    expect(pageSource).toContain("<PreviewEditorPanel");
  });

  it("Flutter landing dört demoyu Next.js önizlemesine açar", () => {
    const landingSource = readFileSync(landingPath, "utf-8");

    for (const slug of [
      "demo-aymira-giyim",
      "demo-lezzet-duragi",
      "demo-nova-kuafor",
      "demo-teknofix",
    ]) {
      expect(landingSource).toContain(slug);
    }
    expect(landingSource).toContain("PublicSiteConfig.buildVitrinPreviewLink");
  });

  it("herkese açık landing demolarını veritabanında değiştirilemez yapar", () => {
    expect(existsSync(migrationPath)).toBe(true);
    const migration = readFileSync(migrationPath, "utf-8");

    expect(migration).toContain("SET is_demo = true");
    expect(migration).toContain("DEMO_STORE_IMMUTABLE");
    expect(migration).toContain("BEFORE UPDATE OR DELETE");
    expect(migration).toContain("demo-aymira-giyim");
    expect(migration).toContain("demo-lezzet-duragi");
    expect(migration).toContain("demo-nova-kuafor");
    expect(migration).toContain("demo-teknofix");
  });

  it("panel demo kilidi hatasını anlaşılır gösterir", () => {
    const panelSource = readFileSync(panelPath, "utf-8");

    expect(panelSource).toContain("DEMO_STORE_IMMUTABLE");
    expect(panelSource).toContain("Bu demo vitrini salt okunur.");
  });
});
