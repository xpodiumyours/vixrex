import { describe, expect, it } from "vitest";
import {
  alanOnemi,
  hazirlikRaporu,
  sonrakiRehberAlan,
  sonrakiRehberAlanlar,
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

// Faz G3 (Tek Asistan planı) — "Sırada" listesi için çoğul biçim.
describe("sonrakiRehberAlanlar", () => {
  it("boş taslakta ilk 3 temel alanı sırayla döner", () => {
    const ilkUc = tumAlanlarSirali().slice(0, 3).map((a) => a.anahtar);
    const sonraki = sonrakiRehberAlanlar({}, null, new Set(), 3);
    expect(sonraki.map((a) => a.anahtar)).toEqual(ilkUc);
  });

  it("sonrakiRehberAlan (tekil) ile aynı ilk sonucu verir", () => {
    const tekil = sonrakiRehberAlan({}, null, new Set());
    const cogul = sonrakiRehberAlanlar({}, null, new Set(), 1);
    expect(cogul).toHaveLength(1);
    expect(cogul[0]?.anahtar).toBe(tekil?.anahtar);
  });

  it("adet parametresi kadar döner, fazlasını döndürmez", () => {
    const beş = sonrakiRehberAlanlar({}, null, new Set(), 5);
    expect(beş).toHaveLength(5);
  });

  it("dolu alanları atlar, atlanmış isteğe bağlıları önermez", () => {
    const sirali = tumAlanlarSirali();
    const ilkIki = sirali.slice(0, 2).map((a) => a.anahtar);
    const draft: Record<string, unknown> = {
      [sirali[0].kolon]: "dolu",
    };
    const sonraki = sonrakiRehberAlanlar(draft, null, new Set(), 2);
    expect(sonraki.map((a) => a.anahtar)).not.toContain(ilkIki[0]);
  });

  it("her şey dolu/atlanmışsa boş dizi döner", () => {
    const sirali = tumAlanlarSirali();
    const sonAnahtar = sirali[sirali.length - 1].anahtar;
    const sonraki = sonrakiRehberAlanlar({}, sonAnahtar, new Set(), 3);
    expect(sonraki).toEqual([]);
  });
});

describe("hazirlikRaporu — yüzde artık 44 alan üstünden (ADR 0002, 3. alt-faz)", () => {
  it("boş taslakta toplam sayı şemadaki TÜM alan sayısıdır, yalnız temel+kalite değil", () => {
    const rapor = hazirlikRaporu({});
    expect(rapor.toplamSayisi).toBe(VITRIN_FIELDS.length);
  });

  it("bilerek atlanan isteğe bağlı alan 'işlem görmüş' sayılır — doluSayisi ve yüzde artar", () => {
    const istegeBagli = VITRIN_FIELDS.find((a) => alanOnemi(a) === "istege-bagli");
    expect(istegeBagli).toBeDefined();
    if (!istegeBagli) return;

    const atlanmadan = hazirlikRaporu({}, new Set());
    const atlandiktan = hazirlikRaporu({}, new Set([istegeBagli.anahtar]));

    expect(atlandiktan.doluSayisi).toBe(atlanmadan.doluSayisi + 1);
    expect(atlandiktan.yuzde).toBeGreaterThan(atlanmadan.yuzde);
  });

  it("atlanmış isteğe bağlı alan 'eksikler' listesine hiç girmez", () => {
    const istegeBagli = VITRIN_FIELDS.find((a) => alanOnemi(a) === "istege-bagli");
    expect(istegeBagli).toBeDefined();
    if (!istegeBagli) return;

    const rapor = hazirlikRaporu({}, new Set([istegeBagli.anahtar]));
    expect(rapor.eksikler.some((e) => e.anahtar === istegeBagli.anahtar)).toBe(false);
  });

  it("her şey dolu + atlanmışsa yüzde 100'dür", () => {
    const draft: Record<string, unknown> = {};
    const atlanmislar = new Set<string>();
    for (const alan of VITRIN_FIELDS) {
      if (alanOnemi(alan) === "istege-bagli") {
        atlanmislar.add(alan.anahtar);
      } else {
        draft[alan.kolon] = "dolu";
      }
    }
    const rapor = hazirlikRaporu(draft, atlanmislar);
    expect(rapor.yuzde).toBe(100);
    expect(rapor.doluSayisi).toBe(VITRIN_FIELDS.length);
  });
});
