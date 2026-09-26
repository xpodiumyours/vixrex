import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";

// 2026-09-25 foto standardi sözleşmesi: demo ürünler en az 3 fotoğrafla doğar.
// Bu dosya iki eski sorunun geri dönmesini kilidin altına alır:
// (1) seed'in tek fotoğraf ataması, (2) Unsplash dış bağımlılığı.
const migrationYolu = join(
  import.meta.dirname,
  "..",
  "..",
  "supabase/migrations/20260925090000_demo_urun_foto_standardini_uc_cikar.sql",
);

describe("demo urun foto standardi sözleşmesi", () => {
  const ham = readFileSync(migrationYolu, "utf8");
  const sql = ham.replace(/--[^\n]*/g, "");

  it("görsel kaynağı yalnız kendi depomuz — dış bağlantı yasak (iç bekçi serbest)", () => {
    expect(sql).not.toMatch(/https?:\/\/[^'"\s]*unsplash/i);
    expect(sql).toContain("category-templates");
    expect(sql).toContain("ILIKE '%unsplash%'");
  });

  it("kapsam yalnız demo mağazalar — gerçek müşteri ürünü korunur", () => {
    expect(sql).toMatch(/s\.is_demo = true/);
    expect(sql).not.toMatch(/is_demo\s*=\s*false/);
  });

  it("mevcut fotoğrafları silen davranış yok — yalnız eksik tamamlanır", () => {
    expect(sql).toMatch(/image_urls = p\.image_urls \|\|/);
    expect(sql).not.toMatch(/image_urls\s*=\s*to_jsonb\(ARRAY\[/);
  });

  it("guard: 3 fotoğrafın altında ürün kalırsa migration düşer", () => {
    expect(sql).toContain("3 fotografin altinda");
  });
});
