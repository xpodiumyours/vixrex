import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { expect, it } from "vitest";
import { FATURA_JSON_ISTEGI } from "@/lib/faturaPresetSozlesmesi";

it("Vixrex nihai karttan sonra resmî sayfa taramaz veya görsel seçmez", () => {
  const source = readFileSync(fileURLToPath(new URL("../../src/lib/faturaArkaPlanIslemi.ts", import.meta.url)), "utf8");
  const gecis = source.indexOf('akis() === "mevcut"');
  const yeni = source.indexOf(": okuma;");
  expect(gecis).toBeGreaterThan(-1);
  expect(yeni).toBeGreaterThan(gecis);
  const mevcutDal = source.slice(gecis, yeni);
  expect(mevcutDal).toContain("gorselsizSatirlariTamamla");
  expect(mevcutDal).toContain("adayGorselleriniSec");
  const sonrasi = source.slice(yeni);
  expect(sonrasi).not.toContain("gorselsizSatirlariTamamla");
  expect(sonrasi).not.toContain("adayGorselleriniSec");
});

it("birinci preset araştırma ve görsel seçimi yapmaz", () => {
  expect(FATURA_JSON_ISTEGI).toContain("yalnızca belge alanlarını");
  expect(FATURA_JSON_ISTEGI).toContain("ikinci OpenRouter presetinin görevidir");
  expect(FATURA_JSON_ISTEGI).not.toContain("web_search");
  expect(FATURA_JSON_ISTEGI).not.toContain("web_fetch");
});
