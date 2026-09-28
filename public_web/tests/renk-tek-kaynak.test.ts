import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import renkSozlesmesi from "../../shared/renkler.json";

const kokDizin = resolve(__dirname, "../..");

const globalsCss = readFileSync(
  resolve(kokDizin, "public_web/src/app/globals.css"),
  "utf8",
);
const uretilenDart = readFileSync(
  resolve(kokDizin, "lib/theme/renkler.g.dart"),
  "utf8",
);
const appColors = readFileSync(
  resolve(kokDizin, "lib/theme/app_colors.dart"),
  "utf8",
);

describe("ortak renk tek kaynak sözleşmesi", () => {
  it("her ortak renk globals.css'te aynı değerle duruyor", () => {
    const sapanlar = renkSozlesmesi.renkler.filter(
      (renk) => !globalsCss.includes(`${renk.cssDegisken}: ${renk.hex};`),
    );
    expect(sapanlar.map((r) => r.cssDegisken)).toEqual([]);
  });

  it("her ortak renk Flutter tarafına aynı değerle üretildi", () => {
    const sapanlar = renkSozlesmesi.renkler.filter(
      (renk) =>
        !uretilenDart.includes(
          `static const Color ${renk.dartAdi} = Color(0xFF${renk.hex.slice(1)});`,
        ),
    );
    expect(sapanlar.map((r) => r.dartAdi)).toEqual([]);
  });

  it("app_colors.dart ortak renkleri elle değil üretilen kaynaktan alıyor", () => {
    expect(appColors).toContain("import 'package:vixrex/theme/renkler.g.dart';");

    const bagliOlmayanlar = renkSozlesmesi.renkler.filter(
      (renk) => !appColors.includes(`OrtakRenkler.${renk.dartAdi}`),
    );
    expect(bagliOlmayanlar.map((r) => r.anahtar)).toEqual([]);
  });
});
