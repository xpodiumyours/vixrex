import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { expect, it } from "vitest";
import { FATURA_JSON_ISTEGI } from "@/lib/faturaPresetSozlesmesi";

it("Vixrex hiçbir akışta resmî sayfa taramaz, görsel seçmez veya gizli ikinci istek açmaz", () => {
  const source = readFileSync(fileURLToPath(new URL("../../src/lib/faturaArkaPlanIslemi.ts", import.meta.url)), "utf8");
  expect(source).not.toContain("gorselsizSatirlariTamamla");
  expect(source).not.toContain("adayGorselleriniSec");
  expect(source).not.toContain("karantinayiBirKeTamamla");
  expect(source).not.toContain("openrouter.ai/api/v1/chat/completions");
  expect(source).not.toContain("kartPresetIstekGovdesiSatirlar");
});

it("birinci preset araştırma ve görsel seçimi yapmaz", () => {
  expect(FATURA_JSON_ISTEGI).toContain("yalnızca belge alanlarını");
  expect(FATURA_JSON_ISTEGI).toContain("ikinci OpenRouter presetinin görevidir");
  expect(FATURA_JSON_ISTEGI).not.toContain("web_search");
  expect(FATURA_JSON_ISTEGI).not.toContain("web_fetch");
});
