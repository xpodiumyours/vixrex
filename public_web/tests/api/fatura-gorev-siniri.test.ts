import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { expect, it } from "vitest";
import { FATURA_JSON_ISTEGI } from "@/lib/faturaPresetSozlesmesi";

it("Vixrex nihai karttan sonra resmî sayfa taramaz veya görsel seçmez", () => {
  const source = readFileSync(fileURLToPath(new URL("../../src/lib/faturaArkaPlanIslemi.ts", import.meta.url)), "utf8");
  expect(source).toContain('akis() === "mevcut"');
  const tamamlama = (source.match(/gorselsizSatirlariTamamla\(\{/g) || []).length;
  const secim = (source.match(/adayGorselleriniSec\(\{/g) || []).length;
  expect(tamamlama).toBe(2);
  expect(secim).toBe(1);
});

it("birinci preset araştırma ve görsel seçimi yapmaz", () => {
  expect(FATURA_JSON_ISTEGI).toContain("yalnızca belge alanlarını");
  expect(FATURA_JSON_ISTEGI).toContain("ikinci OpenRouter presetinin görevidir");
  expect(FATURA_JSON_ISTEGI).not.toContain("web_search");
  expect(FATURA_JSON_ISTEGI).not.toContain("web_fetch");
});
