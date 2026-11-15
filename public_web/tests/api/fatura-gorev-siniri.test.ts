import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { expect, it } from "vitest";
import { FATURA_JSON_ISTEGI } from "@/lib/faturaPresetSozlesmesi";

it("Vixrex nihai karttan sonra resmî sayfa taramaz veya görsel seçmez", () => {
  const source = readFileSync(fileURLToPath(new URL("../../src/lib/faturaArkaPlanIslemi.ts", import.meta.url)), "utf8");
  const mevcut = source.indexOf('islemAkisi === "mevcut"');
  const yeni = source.indexOf(": okuma;", mevcut);
  expect(mevcut).toBeGreaterThan(-1);
  expect(yeni).toBeGreaterThan(mevcut);
  const eskiDal = source.slice(mevcut, yeni);
  expect((eskiDal.match(/gorselsizSatirlariTamamla\(\{/g) || [])).toHaveLength(1);
  expect((eskiDal.match(/adayGorselleriniSec\(\{/g) || [])).toHaveLength(1);
  const yeniDal = source.slice(yeni, source.indexOf("const satirlar =", yeni));
  expect(yeniDal).not.toContain("gorselsizSatirlariTamamla");
  expect(yeniDal).not.toContain("adayGorselleriniSec");
});

it("birinci preset araştırma ve görsel seçimi yapmaz", () => {
  expect(FATURA_JSON_ISTEGI).toContain("yalnızca belge alanlarını");
  expect(FATURA_JSON_ISTEGI).toContain("ikinci OpenRouter presetinin görevidir");
  expect(FATURA_JSON_ISTEGI).not.toContain("web_search");
  expect(FATURA_JSON_ISTEGI).not.toContain("web_fetch");
});
