import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";
import {
  alanOnemi,
  bolumdeKalanSayisi,
  hazirlikRaporu,
  rehberSirasi,
  sonrakiRehberAlan,
  sonrakiRehberAlanlar,
  tumAlanlarSayfaSirasi,
} from "../src/lib/vitrinReadiness";
import {
  SECTION_ORDER,
  VITRIN_FIELDS,
  type VitrinSection,
} from "../src/lib/vitrinFieldSchema";

// Vixrex Asistan rehberli tamamlama (ADR 0002) — sıradaki alan bulma
// mantığının kilidi.
//
// 2026-08-22'de sıra DEĞİŞTİ: eskiden önem sırasıydı (temel → kalite →
// isteğe bağlı), artık SAYFA sırası. Eski sıra ekranda zıplıyordu —
// esnaf üst bölümdeki işletme adını kaydediyor, sıradaki kalite alanı
// sayfanın en altındaki iletişim bölümünde olduğu için ekran oraya
// fırlıyordu (canlı test, Casper). Zorunluluk kaybolmadı: rehber önce
// yalnız zorunluları gezdirir (1. tur), sonra tüm sayfayı (2. tur).

/** Şemadaki her zorunlu alanı dolduran taslak. */
function zorunlularDolu(): Record<string, unknown> {
  const draft: Record<string, unknown> = {};
  for (const alan of VITRIN_FIELDS) {
    if (alan.zorunlu) draft[alan.kolon] = alan.tip === "secim" ? "Giyim" : "dolu";
  }
  return draft;
}

/** Şemadaki her alanı dolduran taslak. */
function hepsiDolu(): Record<string, unknown> {
  const draft: Record<string, unknown> = {};
  for (const alan of VITRIN_FIELDS) {
    draft[alan.kolon] = alan.tip === "secim" ? "Giyim" : "dolu";
  }
  return draft;
}

const bolumIndeksi = (bolum: VitrinSection) => SECTION_ORDER.indexOf(bolum);

describe("tumAlanlarSayfaSirasi", () => {
  it("şemadaki her alanı tam bir kez döner", () => {
    const sirali = tumAlanlarSayfaSirasi();
    expect(sirali.length).toBe(VITRIN_FIELDS.length);
    expect(new Set(sirali.map((a) => a.anahtar)).size).toBe(VITRIN_FIELDS.length);
  });

  it("bölümler vitrindeki sırayla gelir — geri sıçrama yok", () => {
    const indeksler = tumAlanlarSayfaSirasi().map((a) => bolumIndeksi(a.bolum));
    for (let i = 1; i < indeksler.length; i++) {
      expect(indeksler[i]).toBeGreaterThanOrEqual(indeksler[i - 1]);
    }
  });

  it("iletişim bölümü sonda — sayfanın altında olduğu için", () => {
    const sirali = tumAlanlarSayfaSirasi();
    expect(sirali[sirali.length - 1].bolum).toBe("contact");
  });
});

describe("rehberSirasi — iki tur", () => {
  it("1. tur: zorunlu eksik varken YALNIZ zorunluları gezer", () => {
    const sira = rehberSirasi({});
    expect(sira.length).toBeGreaterThan(0);
    expect(sira.every((a) => a.zorunlu)).toBe(true);
  });

  it("2. tur: zorunlular bitince tüm alanlara açılır", () => {
    expect(rehberSirasi(zorunlularDolu()).length).toBe(VITRIN_FIELDS.length);
  });
});

describe("sonrakiRehberAlan", () => {
  it("boş taslakta ilk ZORUNLU alanı döner (1. tur)", () => {
    const sonraki = sonrakiRehberAlan({}, null, new Set());
    expect(sonraki?.zorunlu).toBe(true);
    expect(sonraki?.anahtar).toBe(rehberSirasi({})[0].anahtar);
  });

  it("üst bölümdeki bir alandan sonra sayfanın dibine atlamaz", () => {
    // Asıl şikayet buydu: işletme adı kaydedilir kaydedilmez ekran
    // iletişim bölümüne (sayfanın en altı) fırlıyordu.
    const sonraki = sonrakiRehberAlan(zorunlularDolu(), "isletmeAdi", new Set());
    expect(sonraki).not.toBeNull();
    expect(sonraki?.bolum).toBe("hero");
  });

  it("dolu alanları atlar", () => {
    const sira = rehberSirasi({});
    const draft: Record<string, unknown> = { [sira[0].kolon]: "dolu" };
    expect(sonrakiRehberAlan(draft, null, new Set())?.anahtar).not.toBe(
      sira[0].anahtar,
    );
  });

  it("kaldığı yerden devam eder — baştan aramaz", () => {
    const sira = rehberSirasi({});
    expect(sonrakiRehberAlan({}, sira[0].anahtar, new Set())?.anahtar).toBe(
      sira[1].anahtar,
    );
  });

  it("sona gelince başa döner — geride kalan boş alan atlanmaz", () => {
    // Eskiden yalnız ileriye bakılıyordu: sayfanın altındaki bir alana
    // tıklayıp kaydedince öncesindeki boşlar sessizce atlanıyor, akış
    // "eklenecek bir şey yok" diye erkenden bitiyordu.
    const sirali = tumAlanlarSayfaSirasi();
    const sonAlan = sirali[sirali.length - 1];
    const sonraki = sonrakiRehberAlan(zorunlularDolu(), sonAlan.anahtar, new Set());
    expect(sonraki).not.toBeNull();
    expect(bolumIndeksi(sonraki!.bolum)).toBeLessThanOrEqual(
      bolumIndeksi(sonAlan.bolum),
    );
  });

  it("atlanmislar setindeki isteğe bağlı alanı bir daha önermez", () => {
    const draft = zorunlularDolu();
    const istegeBagli = tumAlanlarSayfaSirasi().find(
      (a) => alanOnemi(a) === "istege-bagli" && draft[a.kolon] === undefined,
    );
    expect(istegeBagli).toBeDefined();
    if (!istegeBagli) return;

    const hepsi = sonrakiRehberAlanlar(draft, null, new Set(), VITRIN_FIELDS.length);
    expect(hepsi.some((a) => a.anahtar === istegeBagli.anahtar)).toBe(true);

    const atlandiktan = sonrakiRehberAlanlar(
      draft,
      null,
      new Set([istegeBagli.anahtar]),
      VITRIN_FIELDS.length,
    );
    expect(atlandiktan.some((a) => a.anahtar === istegeBagli.anahtar)).toBe(false);
  });

  it("her şey doluysa null döner", () => {
    expect(sonrakiRehberAlan(hepsiDolu(), null, new Set())).toBeNull();
  });
});

describe("sonrakiRehberAlanlar", () => {
  it("boş taslakta ilk 3 alanın hepsi zorunludur (1. tur)", () => {
    const sonraki = sonrakiRehberAlanlar({}, null, new Set(), 3);
    expect(sonraki).toHaveLength(3);
    expect(sonraki.every((a) => a.zorunlu)).toBe(true);
  });

  it("sonrakiRehberAlan (tekil) ile aynı ilk sonucu verir", () => {
    const tekil = sonrakiRehberAlan({}, null, new Set());
    const cogul = sonrakiRehberAlanlar({}, null, new Set(), 1);
    expect(cogul).toHaveLength(1);
    expect(cogul[0]?.anahtar).toBe(tekil?.anahtar);
  });

  it("tur başa dönse bile aynı alanı iki kez önermez", () => {
    const hepsi = sonrakiRehberAlanlar({}, null, new Set(), VITRIN_FIELDS.length);
    expect(new Set(hepsi.map((a) => a.anahtar)).size).toBe(hepsi.length);
  });

  it("her şey doluysa boş dizi döner", () => {
    expect(sonrakiRehberAlanlar(hepsiDolu(), null, new Set(), 3)).toEqual([]);
  });
});

describe("bolumdeKalanSayisi", () => {
  it("boş taslakta bölümün tüm alanlarını sayar", () => {
    const heroAlanSayisi = VITRIN_FIELDS.filter((a) => a.bolum === "hero").length;
    expect(bolumdeKalanSayisi({}, "hero")).toBe(heroAlanSayisi);
  });

  it("dolan ve bilerek atlanan alanları saymaz", () => {
    const heroAlanlari = VITRIN_FIELDS.filter((a) => a.bolum === "hero");
    const draft: Record<string, unknown> = { [heroAlanlari[0].kolon]: "dolu" };
    const atlanmislar = new Set([heroAlanlari[1].anahtar]);
    expect(bolumdeKalanSayisi(draft, "hero", atlanmislar)).toBe(
      heroAlanlari.length - 2,
    );
  });
});

describe("hazirlikRaporu — yüzde tüm alanlar üstünden (ADR 0002, 3. alt-faz)", () => {
  it("boş taslakta toplam sayı şemadaki TÜM alan sayısıdır", () => {
    expect(hazirlikRaporu({}).toplamSayisi).toBe(VITRIN_FIELDS.length);
  });

  it("bilerek atlanan isteğe bağlı alan 'işlem görmüş' sayılır", () => {
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
    if (!istegeBagli) return;
    const rapor = hazirlikRaporu({}, new Set([istegeBagli.anahtar]));
    expect(rapor.eksikler.some((e) => e.anahtar === istegeBagli.anahtar)).toBe(
      false,
    );
  });

  it("her şey dolu + atlanmışsa yüzde 100'dür", () => {
    const draft: Record<string, unknown> = {};
    const atlanmislar = new Set<string>();
    for (const alan of VITRIN_FIELDS) {
      if (alanOnemi(alan) === "istege-bagli") atlanmislar.add(alan.anahtar);
      else draft[alan.kolon] = "dolu";
    }
    const rapor = hazirlikRaporu(draft, atlanmislar);
    expect(rapor.yuzde).toBe(100);
    expect(rapor.doluSayisi).toBe(VITRIN_FIELDS.length);
  });
});

// ── Bölüm geçiş anlatımı (useFieldSelection) ────────────────────────────
// Ortam "node" — hook'u çalıştıracak DOM yok; depodaki diğer sözleşme
// testleri gibi kaynak üzerinden ölçülür.
describe("bölüm değişince asistan haber verir", () => {
  const kaynak = readFileSync(
    resolve(__dirname, "../src/app/v/[slug]/hooks/useFieldSelection.ts"),
    "utf8",
  );

  it("bölüm karşılaştırması yapar ve mesaj gönderir", () => {
    expect(kaynak).toContain("kaydedilen.bolum !== sonraki.bolum");
    expect(kaynak).toContain("SECTION_LABELS[sonraki.bolum]");
  });

  it("kalan alan sayısını kendi saymaz, ortak yardımcıyı kullanır", () => {
    expect(kaynak).toContain("bolumdeKalanSayisi");
    // Bölüm gerçekten bitmediyse "tamam ✓" DENMEZ — dürüstlük kuralı.
    expect(kaynak).toContain("oncekiKalan === 0");
  });

  it("kaydedilen değerin taze hâlini alır (aynı turda bayat taslak sorunu)", () => {
    expect(kaynak).toContain("guncelTaslak ?? yerelTaslak");
  });
});
