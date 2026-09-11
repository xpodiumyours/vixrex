import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

const bar = oku("../src/app/v/[slug]/components/OwnerEditorBar.tsx");
const panel = oku("../src/app/v/[slug]/OwnerAssistantPanel.tsx");
const vitrin = oku("../src/app/v/[slug]/VitrinProfileView.tsx");
const globals = oku("../src/app/globals.css");

describe("sahiplik modu editör kabuğu", () => {
  it("kabuk ölçüleri tek yerde tanımlı", () => {
    expect(globals).toContain("--owner-bar-h: 64px;");
    expect(globals).toContain("--owner-rail-w: 460px;");
  });

  it("editör çubuğu yalnız masaüstünde çizilir", () => {
    expect(bar).toContain("h-[var(--owner-bar-h)]");
    expect(bar).toContain("hidden");
    expect(bar).toContain("lg:flex");
  });

  it("çubuk panelin kendi durumundan besleniyor, ikinci durum sistemi yok", () => {
    expect(panel).toContain("<OwnerEditorBar");
    expect(panel).toContain("kaydediliyor={actions.kaydediliyor}");
    expect(panel).toContain("onYayinla={actions.yayinla}");
  });

  it("yasal onay yoksa çubuk yayınlamaz, paneli açar", () => {
    expect(bar).toContain("yasalOnayli ? onYayinla : onYasalOnayGerek");
  });

  it("masaüstünde bilgi iki yerde tekrarlanmaz", () => {
    expect(bar).not.toContain("%{yuzde}");
    expect(oku("../src/app/v/[slug]/components/ChatTopBar.tsx")).toContain(
      "focus-visible:ring-sky-400/70 lg:hidden"
    );
  });

  it("panel masaüstünde yüzen kutu değil, yerleşik sütun", () => {
    expect(panel).toContain("lg:top-[var(--owner-bar-h)]");
    expect(panel).toContain("lg:w-[var(--owner-rail-w)]");
    expect(panel).toContain("lg:rounded-none");
  });

  it("yüzen maskot düğmesi masaüstünde gizlenir", () => {
    expect(panel).toContain("transition lg:hidden");
  });

  it("vitrin tuvali çubuk ve sütun payını alır", () => {
    expect(vitrin).toContain("lg:pt-[var(--owner-bar-h)] lg:pr-[var(--owner-rail-w)]");
    expect(vitrin).toContain('ownerMode ? "lg:right-[var(--owner-rail-w)] lg:top-[var(--owner-bar-h)]" : ""');
  });
});
