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

type OrtakAlan = {
  anahtar: string;
  dogrulama: string | null;
  min: number | null;
  max: number | null;
};

const senaryolar = JSON.parse(
  readFileSync(
    resolve(__dirname, "../../shared/vixrex_dogrulama_senaryolari.json"),
    "utf8",
  ),
) as Senaryo[];

const ortakSema = JSON.parse(
  readFileSync(resolve(__dirname, "../../shared/vitrin_alanlari.json"), "utf8"),
) as { alanlar: OrtakAlan[] };

const nextValidator = readFileSync(
  resolve(__dirname, "../src/lib/vitrinFieldValidation.ts"),
  "utf8",
);
const flutterValidator = readFileSync(
  resolve(__dirname, "../../lib/services/vixrex_nlu/vixrex_field_validator.dart"),
  "utf8",
);
const dartSchema = readFileSync(
  resolve(__dirname, "../../lib/config/vitrin_alanlari.g.dart"),
  "utf8",
);

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

  it("adres ve koordinat kurallarını iki istemcide elle çoğaltmaz", () => {
    const adres = ortakSema.alanlar.find((a) => a.anahtar === "adres");
    const enlem = ortakSema.alanlar.find((a) => a.anahtar === "enlem");
    const boylam = ortakSema.alanlar.find((a) => a.anahtar === "boylam");

    expect(adres?.dogrulama).toBe("adres");
    expect(enlem).toMatchObject({ min: -90, max: 90 });
    expect(boylam).toMatchObject({ min: -180, max: 180 });

    expect(nextValidator).toContain('alan.dogrulama === "adres"');
    expect(nextValidator).not.toContain('alan.anahtar === "adres"');

    expect(flutterValidator).toContain("sema?.dogrulama == 'adres'");
    expect(flutterValidator).toContain("final min = sema?.min;");
    expect(flutterValidator).toContain("final max = sema?.max;");
    expect(flutterValidator).not.toContain("_minFor(");
    expect(flutterValidator).not.toContain("_maxFor(");

    expect(dartSchema).toMatch(
      /anahtar: 'adres',[\s\S]*?maxUzunluk: 200,[\s\S]*?dogrulama: 'adres',/,
    );
  });
});
