import { describe, expect, it } from "vitest";
import {
  alanOnemi,
  sonrakiRehberAlan,
  tumAlanlarSirali,
} from "../src/lib/vitrinReadiness";
import { VITRIN_FIELDS } from "../src/lib/vitrinFieldSchema";

// Vixrex Asistan rehberli tamamlama (ADR 0002) — sıradaki alan bulma
// mantığının kilidi: temel → kalite → isteğe bağlı sırasıyla gezer,
// dolu/atlanmış alanları geçer, kaldığı yerden devam eder.

describe("tumAlanlarSirali", () => {
  it("şemadaki her alanı tam bir kez döner", () => {
    const sirali = tumAlanlarSirali();
    expect(sirali.length).toBe(VITRIN_FIELDS.length);
    expect(new Set(sirali.map((a) => a.anahtar)).size).toBe(VITRIN_FIELDS.length);
  });

  it("temel alanlar kalite alanlarından, kalite alanlar isteğe bağlı alanlardan önce gelir", () => {
    const sirali = tumAlanlarSirali();
    const onemSirasi = sirali.map((a) => alanOnemi(a));
    const ilkKaliteIndeksi = onemSirasi.indexOf("kalite");
    const ilkIstegeBagliIndeksi = onemSirasi.indexOf("istege-bagli");
    const sonTemelIndeksi = onemSirasi.lastIndexOf("temel");

    expect(sonTemelIndeksi).toBeLessThan(ilkKaliteIndeksi);
    expect(onemSirasi.lastIndexOf("kalite")).toBeLessThan(ilkIstegeBagliIndeksi);
  });
});

describe("sonrakiRehberAlan", () => {
  it("boş taslakta, hiçbir alan seçili değilken ilk temel alanı döner", () => {
    const ilkTemel = tumAlanlarSirali().find((a) => alanOnemi(a) === "temel");
    const sonraki = sonrakiRehberAlan({}, null, new Set());
    expect(sonraki?.anahtar).toBe(ilkTemel?.anahtar);
  });

  it("dolu alanları atlar", () => {
    const sirali = tumAlanlarSirali();
    const ilkIki = sirali.slice(0, 2);
    const draft: Record<string, unknown> = {
      [ilkIki[0].kolon]: "dolu",
    };
    const sonraki = sonrakiRehberAlan(draft, null, new Set());
    expect(sonraki?.anahtar).toBe(ilkIki[1].anahtar);
  });

  it("kaldığı yerden devam eder — baştan aramaz", () => {
    const sirali = tumAlanlarSirali();
    const ortadakiAnahtar = sirali[10].anahtar;
    const sonraki = sonrakiRehberAlan({}, ortadakiAnahtar, new Set());
    expect(sonraki?.anahtar).toBe(sirali[11].anahtar);
  });

  it("atlanmislar setindeki isteğe bağlı alanı bir daha önermez", () => {
    const istegeBagli = tumAlanlarSirali().find(
      (a) => alanOnemi(a) === "istege-bagli"
    );
    expect(istegeBagli).toBeDefined();
    if (!istegeBagli) return;

    const sirali = tumAlanlarSirali();
    const indeks = sirali.findIndex((a) => a.anahtar === istegeBagli.anahtar);
    const oncekiAnahtar = sirali[indeks - 1]?.anahtar ?? null;

    const atlanmadanSonraki = sonrakiRehberAlan({}, oncekiAnahtar, new Set());
    expect(atlanmadanSonraki?.anahtar).toBe(istegeBagli.anahtar);

    const atlandiktanSonraki = sonrakiRehberAlan(
      {},
      oncekiAnahtar,
      new Set([istegeBagli.anahtar])
    );
    expect(atlandiktanSonraki?.anahtar).not.toBe(istegeBagli.anahtar);
  });

  it("her şey dolu/atlanmışsa null döner", () => {
    const sirali = tumAlanlarSirali();
    const sonAnahtar = sirali[sirali.length - 1].anahtar;
    const sonraki = sonrakiRehberAlan({}, sonAnahtar, new Set());
    expect(sonraki).toBeNull();
  });
});
