import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

import { validateField } from "../src/lib/vitrinFieldValidation";

type Senaryo = {
  id: string;
  anahtar: string;
  girdi: string;
  ok: boolean;
  deger?: unknown;
  hata?: string;
};

const senaryolar = JSON.parse(
  readFileSync(
    resolve(__dirname, "../../shared/vixrex_dogrulama_senaryolari.json"),
    "utf8",
  ),
) as Senaryo[];

describe("Vixrex 46 alan doğrulama parity kabul kümesi — Next", () => {
  it("ortak senaryoların tamamında beklenen kabul/red ve normalize sonucu verir", () => {
    const hatalar: string[] = [];

    for (const senaryo of senaryolar) {
      const sonuc = validateField(senaryo.anahtar, senaryo.girdi);
      if (sonuc.ok !== senaryo.ok) {
        hatalar.push(`${senaryo.id}: ok=${sonuc.ok}, beklenen=${senaryo.ok}`);
        continue;
      }
      if (sonuc.ok) {
        if (!("deger" in senaryo) || !Object.is(sonuc.deger, senaryo.deger)) {
          hatalar.push(
            `${senaryo.id}: deger=${JSON.stringify(sonuc.deger)}, beklenen=${JSON.stringify(senaryo.deger)}`,
          );
        }
      } else if (sonuc.hata !== senaryo.hata) {
        hatalar.push(`${senaryo.id}: hata=${sonuc.hata}, beklenen=${senaryo.hata}`);
      }
    }

    expect(hatalar, hatalar.join("\n")).toEqual([]);
  });
});
