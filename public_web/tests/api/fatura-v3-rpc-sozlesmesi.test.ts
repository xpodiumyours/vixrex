import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

const sql = readFileSync(fileURLToPath(new URL(
  "../../../supabase/migrations/20261105080000_fatura_v3_preset_akisi.sql",
  import.meta.url,
)), "utf8");

describe("V3 kart RPC sözleşmesi", () => {
  it("yeni preset slugını kabul eder ve akışı okuma kaydında tutar", () => {
    expect(sql).toContain("@preset/vixrex-urun-karti-v2");
    expect(sql).toContain("p_read_result->>'presetAkis'");
    expect(sql).toContain("v_akis = 'yeni'");
  });

  it("akış alanı olmayan işleri modelden geriye uyumlu ayırt eder", () => {
    expect(sql).toContain("nullif(p_read_result->>'presetAkis','')");
    expect(sql).toContain("case when p_body->>'model' = '@preset/vixrex-urun-karti-v2' then 'yeni' else 'mevcut' end");
    expect(sql).toContain("v_akis = 'mevcut'");
    expect(sql).toContain("@preset/urun-kart-olusturucu");
  });
});
