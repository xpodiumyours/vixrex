import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const DEPO_KOKU = resolve(__dirname, "../..");
const MATRIS_YOLU = resolve(
  DEPO_KOKU,
  "docs/plan/vitrin-kalite-plan-matrisi.md",
);

const GECERLI_DURUMLAR = ["✓", "△", "✗", "İstisna"] as const;
type Durum = (typeof GECERLI_DURUMLAR)[number];

type MatrisSatiri = {
  ogeAdi: string;
  kanit: string;
  durum: Durum;
};

const KACISLI_BOLUK = String.fromCharCode(92) + "|";
const NOBETCI = String.fromCharCode(1);

function boluklereAyir(satir: string): string[] {
  if (!satir.startsWith("|")) return [];
  return satir
    .split(KACISLI_BOLUK)
    .join(NOBETCI)
    .split("|")
    .slice(1, -1)
    .map((h) => h.split(NOBETCI).join("|").trim());
}

function durumuAyikla(hucre: string): Durum {
  const sade = hucre.replaceAll("`", "").trim();
  const bulunan = GECERLI_DURUMLAR.find((d) => sade.startsWith(d));
  return (bulunan ?? sade) as Durum;
}

function matrisMetni(): string {
  return readFileSync(MATRIS_YOLU, "utf-8");
}

function matrisSatirlari(): MatrisSatiri[] {
  const satirlar: MatrisSatiri[] = [];
  let matristeyiz = false;

  for (const ham of matrisMetni().split("\n")) {
    const satir = ham.trim();
    if (satir.startsWith("## Matris")) {
      matristeyiz = true;
      continue;
    }
    if (matristeyiz && satir.startsWith("## ")) break;
    if (!matristeyiz || !satir.startsWith("|")) continue;

    const hucreler = boluklereAyir(satir);
    if (hucreler.length !== 6) continue;
    if (hucreler[0] === "#" || hucreler[0].startsWith("---")) continue;

    satirlar.push({
      ogeAdi: hucreler[1],
      kanit: hucreler[3],
      durum: durumuAyikla(hucreler[5]),
    });
  }

  return satirlar;
}

function sayimTablosu(): Record<string, number> {
  const sayim: Record<string, number> = {};
  const metin = matrisMetni();
  const bolum = metin.slice(metin.indexOf("## Sayım"));
  for (const ham of bolum.split("\n")) {
    const hucreler = boluklereAyir(ham.trim());
    if (hucreler.length !== 2) continue;
    const adet = Number(hucreler[1].replaceAll("*", ""));
    if (!Number.isFinite(adet)) continue;
    const sade = hucreler[0].replaceAll("`", "");
    for (const durum of GECERLI_DURUMLAR) {
      if (sade.includes(durum)) sayim[durum] = adet;
    }
  }
  return sayim;
}

describe("18. Vitrin ve ürün kartı kalite matrisi — sözleşme", () => {
  it("matris belgesi depoda duruyor", () => {
    expect(existsSync(MATRIS_YOLU)).toBe(true);
  });

  it("matris boş değil", () => {
    expect(matrisSatirlari().length).toBeGreaterThanOrEqual(10);
  });

  it("her satırın geçerli bir durum işareti var", () => {
    const gecersiz = matrisSatirlari().filter(
      (s) => !GECERLI_DURUMLAR.includes(s.durum),
    );
    expect(
      gecersiz.map((s) => `${s.ogeAdi} → "${s.durum}"`),
      "Durum yalnız ✓ / △ / ✗ / İstisna olabilir.",
    ).toEqual([]);
  });

  it("her satırın kanıtı yazılmış", () => {
    const kanitsiz = matrisSatirlari().filter(
      (s) => s.durum !== "İstisna" && s.kanit.length < 8,
    );
    expect(
      kanitsiz.map((s) => s.ogeAdi),
      "Kanıtsız hücre yasak: dosya+satır ya da ölçüm sorgusu yazılmalı.",
    ).toEqual([]);
  });

  it("✓ işaretli her satır var olan bir kilitleyen test adı veriyor", () => {
    const ihlal: string[] = [];
    for (const satir of matrisSatirlari()) {
      if (satir.durum !== "✓") continue;
      const testAdi = satir.kanit.match(/[\w./-]+\.test\.ts/)?.[0];
      if (!testAdi) {
        ihlal.push(`${satir.ogeAdi}: ✓ yazılmış ama test adı yok`);
        continue;
      }
      const yol = resolve(DEPO_KOKU, "public_web/tests", testAdi.split("/").pop()!);
      if (!existsSync(yol)) {
        ihlal.push(`${satir.ogeAdi}: ${testAdi} diye bir test yok`);
      }
    }
    expect(
      ihlal,
      "Dürüstlük kuralı: kod + onu kilitleyen test birlikte görülmeden ✓ yazılmaz.",
    ).toEqual([]);
  });

  it("sayım tablosu gerçek satırlarla uyuşuyor", () => {
    const satirlar = matrisSatirlari();
    const gercek: Record<string, number> = {};
    for (const durum of GECERLI_DURUMLAR) {
      gercek[durum] = satirlar.filter((s) => s.durum === durum).length;
    }
    expect(sayimTablosu()).toEqual(gercek);
  });
});
