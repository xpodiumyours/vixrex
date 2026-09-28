import { describe, expect, it } from "vitest";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";

import {
  AYLIK_PREMIUM_BEDEL,
  AYLIK_PREMIUM_KURUS,
  ODEME_SEPET_TUTARI,
  PREMIUM_DEGIL_ROZET,
  PREMIUM_ILE_YAYINLA,
  YAYIN_KAPISI_UYARISI,
} from "@/lib/fiyatlandirma";

const kokDizin = resolve(__dirname, "../..");

function dosyalariTopla(dizin: string, uzantilar: string[]): string[] {
  const sonuc: string[] = [];
  for (const ad of readdirSync(dizin)) {
    if (ad === "node_modules" || ad === ".next" || ad === "coverage") continue;
    const yol = join(dizin, ad);
    if (statSync(yol).isDirectory()) {
      sonuc.push(...dosyalariTopla(yol, uzantilar));
      continue;
    }
    if (uzantilar.some((u) => ad.endsWith(u))) sonuc.push(yol);
  }
  return sonuc;
}

function yorumlariAt(kaynak: string): string {
  return kaynak
    .replace(/\/\*[\s\S]*?\*\//g, " ")
    .replace(/^[ \t]*\/\/.*$/gm, " ")
    .replace(/^[ \t]*\/\/\/.*$/gm, " ");
}

function tekBosluk(metin: string): string {
  return metin.replace(/\s+/g, " ");
}

describe("fiyat tek kaynak sözleşmesi", () => {
  const uretilenDart = tekBosluk(
    readFileSync(join(kokDizin, "lib/config/fiyatlandirma.g.dart"), "utf8"),
  );

  it("Flutter ve Next.js aynı metni üretir", () => {
    expect(uretilenDart).toContain(
      `const int aylikPremiumKurus = ${AYLIK_PREMIUM_KURUS};`,
    );
    expect(uretilenDart).toContain(
      `const String aylikPremiumBedel = '${AYLIK_PREMIUM_BEDEL}';`,
    );
    expect(uretilenDart).toContain(
      `const String premiumDegilRozet = '${PREMIUM_DEGIL_ROZET}';`,
    );
    expect(uretilenDart).toContain(
      `const String premiumIleYayinla = '${PREMIUM_ILE_YAYINLA}';`,
    );
    expect(uretilenDart).toContain(
      `const String yayinKapisiUyarisi = '${YAYIN_KAPISI_UYARISI}';`,
    );
  });

  it("ödeme tutarı ile gösterilen bedel aynı sayıdan gelir", () => {
    expect(ODEME_SEPET_TUTARI).toBe((AYLIK_PREMIUM_KURUS / 100).toFixed(2));
    expect(AYLIK_PREMIUM_BEDEL).toContain(
      String(Math.floor(AYLIK_PREMIUM_KURUS / 100)),
    );
  });

  it("çalışan kodda elle yazılmış aylık bedel kalmadı", () => {
    const bedelDeseni = new RegExp(
      `(^|[^0-9.,])${Math.floor(AYLIK_PREMIUM_KURUS / 100)}\\s*(TL|TRY)`,
    );

    const taranan = [
      ...dosyalariTopla(join(kokDizin, "public_web/src"), [".ts", ".tsx"]),
      ...dosyalariTopla(join(kokDizin, "lib"), [".dart"]),
    ].filter((yol) => !yol.endsWith(".g.dart"));

    const ihlaller = taranan.filter((yol) =>
      bedelDeseni.test(yorumlariAt(readFileSync(yol, "utf8"))),
    );

    expect(ihlaller.map((y) => y.slice(kokDizin.length + 1))).toEqual([]);
  });
});
