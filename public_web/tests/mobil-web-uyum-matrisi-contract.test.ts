import { existsSync, readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const DEPO_KOKU = resolve(__dirname, "../..");
const MATRIS_YOLU = resolve(
  DEPO_KOKU,
  "docs/research/uyum-sozlesmesi/mobil-web-uyum-matrisi.md",
);
const TEST_KLASORU = __dirname;
const ORTAK_KAYNAK = resolve(DEPO_KOKU, "shared");

const GECERLI_DURUMLAR = ["✓", "△", "✗", "İstisna"] as const;
type Durum = (typeof GECERLI_DURUMLAR)[number];

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
  return (GECERLI_DURUMLAR.find((d) => sade.startsWith(d)) ?? sade) as Durum;
}

function matrisMetni(): string {
  return readFileSync(MATRIS_YOLU, "utf-8");
}

function bolumTablosu(baslik: string, sutunSayisi: number): string[][] {
  const metin = matrisMetni();
  const bas = metin.indexOf(baslik);
  if (bas < 0) return [];
  const kalan = metin.slice(bas + baslik.length);
  const son = kalan.indexOf("\n## ");
  const bolum = son < 0 ? kalan : kalan.slice(0, son);

  const satirlar: string[][] = [];
  for (const ham of bolum.split("\n")) {
    const hucreler = boluklereAyir(ham.trim());
    if (hucreler.length !== sutunSayisi) continue;
    if (hucreler[0].startsWith("---") || hucreler[0] === "#") continue;
    if (hucreler[0] === "Durum" || hucreler[0] === "Ölçüm") continue;
    if (hucreler[0] === "Sınıf" || hucreler[0] === "Katman") continue;
    satirlar.push(hucreler);
  }
  return satirlar;
}

function matrisSatirlari(): { alan: string; kanit: string; durum: Durum }[] {
  return bolumTablosu("\n## Matris", 6).map((h) => ({
    alan: h[1],
    kanit: `${h[3]} ${h[4]} ${h[5]}`,
    durum: durumuAyikla(h[5]),
  }));
}

function sayimTablosu(): Record<string, number> {
  const sayim: Record<string, number> = {};
  for (const hucreler of bolumTablosu("\n## Sayım", 2)) {
    const adet = Number(hucreler[1].replaceAll("*", ""));
    if (!Number.isFinite(adet)) continue;
    const sade = hucreler[0].replaceAll("`", "");
    for (const durum of GECERLI_DURUMLAR) {
      if (sade.includes(durum)) sayim[durum] = adet;
    }
  }
  return sayim;
}

function testDosyalari(): string[] {
  return readdirSync(TEST_KLASORU).filter(
    (ad) => ad.endsWith(".test.ts") && !ad.includes("-matrisi-contract"),
  );
}

function dartOkuyanlariSinifla(): Record<string, number> {
  const sayim = { "1": 0, "2": 0, "3": 0 };
  for (const ad of testDosyalari()) {
    const icerik = readFileSync(resolve(TEST_KLASORU, ad), "utf-8");
    if (!icerik.includes(".dart")) continue;
    if (/landing_screen\.dart|widgets\/landing\//.test(icerik)) sayim["1"] += 1;
    else if (/lib\/(screens|widgets)\//.test(icerik)) sayim["3"] += 1;
    else sayim["2"] += 1;
  }
  return sayim;
}

function belgedekiSinifSayilari(): Record<string, number> {
  const sonuc: Record<string, number> = {};
  for (const hucreler of bolumTablosu("Sınıf | Adet | Karar", 3)) {
    const sinif = hucreler[0].match(/^(\d)/)?.[1];
    const adet = Number(hucreler[1].replaceAll("*", ""));
    if (sinif && Number.isFinite(adet)) sonuc[sinif] = adet;
  }
  return sonuc;
}

describe("Mobil ↔ Web uyum matrisi — kemik sözleşme", () => {
  it("matris belgesi depoda duruyor", () => {
    expect(existsSync(MATRIS_YOLU)).toBe(true);
  });

  it("kemik matris olduğu ve plan matrisinden ayrıldığı yazılı", () => {
    const metin = matrisMetni();
    expect(metin).toContain("kemik matris");
    expect(metin).toContain("docs/plan/");
  });

  it("her satırın geçerli durum işareti var", () => {
    const gecersiz = matrisSatirlari().filter(
      (s) => !GECERLI_DURUMLAR.includes(s.durum),
    );
    expect(gecersiz.map((s) => `${s.alan} → ${s.durum}`)).toEqual([]);
  });

  it("✓ işaretli her satır var olan bir kilitleyen test adı veriyor", () => {
    const ihlal: string[] = [];
    for (const satir of matrisSatirlari()) {
      if (satir.durum !== "✓") continue;
      const testAdi = satir.kanit.match(/[\w.-]+\.test\.ts/)?.[0];
      if (!testAdi) {
        ihlal.push(`${satir.alan}: ✓ yazılmış ama test adı yok`);
        continue;
      }
      if (!existsSync(resolve(TEST_KLASORU, testAdi))) {
        ihlal.push(`${satir.alan}: ${testAdi} diye bir test yok`);
      }
    }
    expect(
      ihlal,
      "Dürüstlük kuralı: kod + onu kilitleyen test görülmeden ✓ yazılmaz.",
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

  it("ÖNCE fotoğrafındaki ortak kaynak sayısı gerçekle uyuşuyor", () => {
    const gercek = readdirSync(ORTAK_KAYNAK).filter((a) =>
      a.endsWith(".json"),
    ).length;
    expect(matrisMetni()).toContain(`\`shared/*.json\` (${gercek} dosya)`);
  });

  it("sınıflandırma sayıları yeniden ölçüldüğünde tutuyor", () => {
    expect(
      belgedekiSinifSayilari(),
      "Yeni bir test Flutter dosyası okumaya başladıysa matris güncellenmeli.",
    ).toEqual(dartOkuyanlariSinifla());
  });
});
