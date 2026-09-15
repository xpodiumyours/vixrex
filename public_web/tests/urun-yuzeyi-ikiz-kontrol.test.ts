import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

const src = (rel: string) =>
  readFileSync(resolve(__dirname, "..", "src", rel), "utf-8");

const vitrinSayfasi = src("app/v/[slug]/page.tsx");
const sahipSayfasi = src("app/app/page.tsx");
const sahipKabugu = src("app/v/[slug]/OwnerWorkspaceShell.tsx");

const kacKez = (metin: string, parca: string) =>
  metin.split(parca).length - 1;

describe("ürün yüzeyi ikiz kontrolü", () => {
  it("vitrin sayfası ProductCatalog'u yalnız bir kez basar", () => {
    expect(kacKez(vitrinSayfasi, "<ProductCatalog")).toBe(1);
  });

  it("OwnerWorkspaceShell kullanmadığı bir katalog prop'u istemez", () => {
    expect(sahipKabugu).not.toMatch(/catalog\s*:\s*React\.ReactNode/);
    expect(kacKez(vitrinSayfasi, "catalog={")).toBe(1);
  });

  it("sahip sayfasinda erken donusten sonra erisilemez dal kalmaz", () => {
    expect(sahipSayfasi).toContain("if (stores.length > 0) {");
    expect(kacKez(sahipSayfasi, "stores[0]")).toBe(1);
  });

  it("esnaf ürün yönetimi tek yüzeyden açılır", () => {
    expect(kacKez(sahipSayfasi, "<OwnerProductManager")).toBe(0);
  });
});
