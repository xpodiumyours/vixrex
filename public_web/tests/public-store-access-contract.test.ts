import { describe, expect, it } from "vitest";
import { existsSync, readFileSync } from "fs";
import { resolve } from "path";

const pagePath = resolve(__dirname, "../src/app/v/[slug]/page.tsx");
const errorPath = resolve(__dirname, "../src/app/v/[slug]/error.tsx");
const pageSource = readFileSync(pagePath, "utf-8");

describe("public vitrin veri erişim sözleşmesi", () => {
  it("stores sorgusu edit_token isteyen wildcard select kullanmaz", () => {
    expect(pageSource).toContain("PUBLIC_STORE_SELECT");
    expect(pageSource).not.toContain('.from("stores")\n      .select("*")');
    expect(pageSource).not.toContain("edit_token");
  });

  it("olmayan vitrini sorgu hatasından ayırır", () => {
    expect(pageSource).toContain(".maybeSingle()");
    expect(pageSource).toContain("if (storeError)");
    expect(pageSource).toContain("throw storeError");
    expect(pageSource).toContain("if (!storeData) return null");
  });

  it("veritabanı hatası için yeniden deneme yüzeyi vardır", () => {
    expect(existsSync(errorPath)).toBe(true);
    const errorSource = readFileSync(errorPath, "utf-8");
    expect(errorSource).toContain('"use client"');
    expect(errorSource).toContain("reset");
    expect(errorSource).toContain("Tekrar dene");
  });
});
