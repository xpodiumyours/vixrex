import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";

// 2026-09-25 kiralik vitrin icerik sozlesmesi: oznitelik + puan seed'lerinin
// kapsam, kaynak ve idempotentlik kurallarini kilitler.
// Kural kaynagi: GOREV-vitrin-kalite.md Adim 3 + KIRALIK-VITRIN-KALITE-PLANI.
// Ad: kullaniciya gorunen ad "kiralik vitrin"; veritabani teknik isareti `is_demo`.

const oznitelikYolu = join(
  import.meta.dirname,
  "..",
  "..",
  "supabase/migrations/20260925100000_kiralik_vitrin_urun_ozniteliklerini_tamamla.sql",
);
const puanYolu = join(
  import.meta.dirname,
  "..",
  "..",
  "supabase/migrations/20260925110000_kiralik_vitrin_puanlari.sql",
);

// Yorum satirlari rapor metni degil, sozlesme degil; test oncesi silinir.
const yorumsuz = (ham: string) => ham.replace(/--[^\n]*/g, "");

const oznitelikHam = readFileSync(oznitelikYolu, "utf8");
const oznitelik = yorumsuz(oznitelikHam);
const puan = yorumsuz(readFileSync(puanYolu, "utf8"));

// Kategori sablonunun tek kaynagi: shared/business_categories.json
const ortakKategoriler = JSON.parse(
  readFileSync(
    join(import.meta.dirname, "..", "..", "shared/business_categories.json"),
    "utf8",
  ),
) as { categories: Array<{ label: string; productTemplateKey?: string }> };

// Bolum 0'daki (kategori sablonu) esleme satirlarini ham metinden cikarir.
function sablonEslemesi(ham: string) {
  const kesim = ham.indexOf("Bolum 1");
  expect(kesim).toBeGreaterThan(0);
  const govde = yorumsuz(ham.slice(0, kesim));
  return [...govde.matchAll(/\(\s*'([^']+)'\s*,\s*'([^']+)'\s*\)/g)].map((m) => ({
    etiket: m[1],
    sablon: m[2],
  }));
}

describe("kiralik vitrin urun oznitelik migration sozlesmesi", () => {
  it("kapsam yalniz kiralik vitrinler — gercek musteri urunune dokunulmaz", () => {
    expect(oznitelik).toMatch(/s\.is_demo = true/);
    expect(oznitelik).not.toMatch(/is_demo\s*=\s*false/);
  });

  it("alan listesinin kaynagi kategori sablonu — ikinci liste degil", () => {
    expect(oznitelik).toContain("product_template_key");
  });

  it("marka yalniz bosken doldurulur — mevcut marka ezilmez", () => {
    expect(oznitelik).toMatch(/p\.brand IS NULL OR btrim\(p\.brand\) = ''/);
  });

  it("attributes yalniz bosa yazilir — dolu ozellik korunur", () => {
    // Her fiziksel sablon UPDATE'i "bos mu" kosuluyla calisir.
    const boslukKosulu = oznitelik.match(/NOT EXISTS \(\s*SELECT 1 FROM jsonb_array_elements/g);
    expect(boslukKosulu).not.toBeNull();
    expect(boslukKosulu!.length).toBeGreaterThanOrEqual(7);
  });

  it("hizmet urunlerinde itemKind service yapilir ve metadata.service doldurulur", () => {
    expect(oznitelik).toContain("'service'");
    expect(oznitelik).toContain("'{service}'");
    expect(oznitelik).toContain("'{itemKind}'");
  });

  it("guard: bos alan kalirsa migration duser", () => {
    expect(oznitelik).toContain("attributes bos");
    expect(oznitelik).toContain("service nesnesi bos");
    expect(oznitelik).toContain("templateKey yok");
  });

  it("gorsel kaynagi dokunmaz — dis baglanti ve silme yok", () => {
    expect(oznitelik).not.toMatch(/unsplash/i);
    expect(oznitelik).not.toMatch(/image_urls\s*=/i);
  });

  it("vitrin kaydina dokunmaz — yalniz urun ve kategori yazilir", () => {
    expect(oznitelik).not.toMatch(/UPDATE\s+public\.stores/i);
    expect(oznitelik).toMatch(/UPDATE\s+public\.product_categories/i);
  });

  it("kategori sablonu ortak listeden turetilir — ikinci liste yazilmaz", () => {
    const esleme = sablonEslemesi(oznitelikHam);
    expect(esleme.length).toBeGreaterThanOrEqual(6);
    const etiketler = new Set(esleme.map((satir) => satir.etiket));
    expect(etiketler.size).toBe(esleme.length);
    for (const satir of esleme) {
      const ortak = ortakKategoriler.categories.find(
        (kategori) => kategori.label === satir.etiket,
      );
      expect(ortak, `ortak listede '${satir.etiket}' yok`).toBeDefined();
      expect(ortak!.productTemplateKey).toBe(satir.sablon);
      expect(satir.sablon).not.toBe("generic");
    }
  });

  it("kategori sablonu yalniz bos veya generic kayda yazilir — dolu sablon ezilmez", () => {
    expect(oznitelik).toMatch(/pc\.product_template_key IS NULL/);
    expect(oznitelik).toMatch(/btrim\(pc\.product_template_key\) = ''/);
    expect(oznitelik).toMatch(/pc\.product_template_key = 'generic'/);
  });

  it("guard: generic kategori kalirsa migration duser", () => {
    expect(oznitelik).toContain("urun kategorisi hala generic");
  });

  it("tek transaction icinde kosar", () => {
    expect(oznitelik).toContain("BEGIN;");
    expect(oznitelik).toContain("COMMIT;");
    expect(oznitelik.indexOf("BEGIN;")).toBeLessThan(oznitelik.indexOf("COMMIT;"));
  });
});

describe("kiralik vitrin puan migration sozlesmesi", () => {
  const DEMO_SLUGLARI = [
    "demo-aymira-giyim",
    "demo-lezzet-duragi",
    "demo-nova-kuafor",
    "demo-teknofix",
    "kiralik-giyim-erkek",
    "kiralik-giyim-cocuk",
    "kiralik-giyim-tesettur",
    "kiralik-giyim-spor",
    "kiralik-butik-gunluk",
    "kiralik-butik-abiye",
    "kiralik-butik-aksesuar",
    "kiralik-butik-genc",
    "kiralik-gida-sarkuteri",
    "kiralik-gida-manav",
    "kiralik-gida-kuruyemis",
    "kiralik-gida-market",
    "kiralik-kafe-pastane",
    "kiralik-kafe-kahvalti",
    "kiralik-kafe-hizli",
    "kiralik-kuafor-berber",
    "kiralik-kuafor-guzellik",
    "kiralik-kuafor-nail",
    "kiralik-teknik-bilgisayar",
    "kiralik-teknik-beyaz-esya",
    "kiralik-teknik-tv",
  ];

  it("kapsam yalniz demo ve sahibi olmayan vitrinler", () => {
    expect(puan).toMatch(/s\.is_demo = true/);
    expect(puan).toMatch(/s\.user_id IS NULL/);
  });

  it("cesitlendirme listesi tum kiralik vitrinleri tek tek ve benzersiz kapsar", () => {
    const slugDizisi = [...puan.matchAll(/'([a-z0-9-]+)'/g)].map((m) => m[1]);
    for (const slug of DEMO_SLUGLARI) {
      expect(slugDizisi).toContain(slug);
    }
    // Ayni slug iki kez puan yazamaz.
    const puanSatiri = puan.split("\n").filter((l) => l.includes("::numeric"));
    const sluglar = puanSatiri.map((l) => l.match(/'([a-z0-9-]+)'/)?.[1]);
    expect(new Set(sluglar).size).toBe(sluglar.length);
  });

  it("puanlar deterministik — rastgele yok", () => {
    expect(puan).not.toMatch(/random\(\)/i);
  });

  it("puan bandi 30 vitrinde acilir — korunan 5 vitrin dahil", () => {
    expect(puan).toMatch(/show_storefront_rating = true/);
    for (const temel of ["kiralik-butik", "kiralik-kafe", "kiralik-kuafor", "kiralik-teknik", "kiralik-gida"]) {
      expect(puan).toContain(`'${temel}'`);
    }
  });

  it("guard: tekrar eden puan/yorum ikilisi veya eksik vitrin migration'i dusurur", () => {
    expect(puan).toContain("Kiralik vitrin sayisi 30 degil");
    expect(puan).toContain("ikilisini tasiyan");
    expect(puan).toContain("puan bandi hala kapali");
  });

  it("kiralik vitrin koruma tetikleyicisi islem boyunca kapatilir", () => {
    const kapat = puan.indexOf("DISABLE TRIGGER protect_landing_demo_stores");
    const ac = puan.indexOf("ENABLE TRIGGER protect_landing_demo_stores");
    const ilkYazma = puan.indexOf("UPDATE public.stores");
    expect(kapat).toBeGreaterThan(-1);
    expect(ac).toBeGreaterThan(kapat);
    // Kapatma ilk yazmadan once, acma guard'dan once olmali.
    expect(kapat).toBeLessThan(ilkYazma);
    expect(ac).toBeGreaterThan(puan.lastIndexOf("UPDATE public.stores"));
  });

  it("tek transaction icinde kosar", () => {
    expect(puan).toContain("BEGIN;");
    expect(puan).toContain("COMMIT;");
    expect(puan.indexOf("BEGIN;")).toBeLessThan(puan.indexOf("COMMIT;"));
  });
});
