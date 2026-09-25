import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const kok = join(import.meta.dirname, "..", "..");

const slugYolu = join(
  kok,
  "supabase/migrations/20260925120000_kiralik_vitrin_sluglarini_yenile.sql",
);
const fotoYolu = join(
  kok,
  "supabase/migrations/20260925130000_kiralik_vitrin_urun_fotograflarini_dagit.sql",
);
const sayfaYolu = join(import.meta.dirname, "..", "src", "app", "v", "[slug]", "page.tsx");

const yorumsuz = (ham: string) => ham.replace(/--[^\n]*/g, "");

const slugHam = readFileSync(slugYolu, "utf8");
const slug = yorumsuz(slugHam);
const foto = yorumsuz(readFileSync(fotoYolu, "utf8"));
const sayfa = readFileSync(sayfaYolu, "utf8");

const ESKI_SLUGLAR = [
  "demo-aymira-giyim",
  "demo-lezzet-duragi",
  "demo-nova-kuafor",
  "demo-teknofix",
];

const YENI_SLUGLAR = [
  "kiralik-aymira-giyim",
  "kiralik-lezzet-duragi",
  "kiralik-nova-kuafor",
  "kiralik-teknofix",
];

const ciftler = ESKI_SLUGLAR.map((eski, i) => ({ eski, yeni: YENI_SLUGLAR[i] }));

describe("kiralik vitrin slug migration sozlesmesi", () => {
  it("dort vitrinin adresi demo onekinden cikarilir", () => {
    for (const { eski, yeni } of ciftler) {
      const kalip = new RegExp(`\\(\\s*'${eski}'\\s*,\\s*'${yeni}'\\s*\\)`);
      expect(slug, `${eski} -> ${yeni} eslemesi yok`).toMatch(kalip);
    }
  });

  it("kapsam yalniz sahibi olmayan kiralik vitrinler", () => {
    expect(slug).toMatch(/s\.is_demo = true/);
    expect(slug).toMatch(/s\.user_id IS NULL/);
    expect(slug).not.toMatch(/is_demo\s*=\s*false/);
  });

  it("koruma tetikleyicisi yalniz kendi yazimi boyunca kapatilir", () => {
    const kapat = slug.indexOf("DISABLE TRIGGER protect_landing_demo_stores");
    const yazim = slug.indexOf("UPDATE public.stores");
    const ac = slug.indexOf("ENABLE TRIGGER protect_landing_demo_stores");
    expect(kapat).toBeGreaterThan(-1);
    expect(yazim).toBeGreaterThan(kapat);
    expect(ac).toBeGreaterThan(yazim);
  });

  it("vitrin yazilarinin slug bagi da tasinir", () => {
    expect(slug).toContain("UPDATE public.store_articles");
    for (const { eski } of ciftler) {
      const kalip = new RegExp(`\\('${eski}'\\s*,\\s*'kiralik-[a-z-]+'\\)`);
      expect(slug).toMatch(kalip);
    }
    expect(slug).toContain("a.store_slug = g.eski");
  });

  it("guard: eski slug veya eksik vitrin kalirsa migration duser", () => {
    expect(slug).toContain("SLUG_DEGISIMI_DUSTU");
    expect(slug).toMatch(/yeni_vitrin <> 4/);
    expect(slug).toMatch(/bagli_kalan > 0/);
  });

  it("vitrin ve bagli kayitlar tek ifadede tasinir — yabanci anahtar kirilmaz", () => {
    expect(slug).toContain("WITH g(eski, yeni) AS");
    const sonEk = slug.indexOf("ALTER TABLE public.stores ENABLE TRIGGER");
    expect(slug.slice(0, sonEk)).toContain("UPDATE public.stores s");
    expect(slug.slice(0, sonEk)).toContain("UPDATE public.store_articles a");
  });

  it("tek transaction icinde kosar", () => {
    expect(slug).toContain("BEGIN;");
    expect(slug).toContain("COMMIT;");
    expect(slug.indexOf("BEGIN;")).toBeLessThan(slug.indexOf("COMMIT;"));
  });
});

describe("kiralik vitrin urun fotografi migration sozlesmesi", () => {
  it("kategori sablonlarinin hepsi icin havuz tanimlanir", () => {
    for (const sablon of [
      "fashion",
      "food",
      "cafe_restaurant",
      "service",
      "technical_service",
      "electronics",
      "generic",
    ]) {
      expect(foto, `${sablon} havuzu yok`).toContain(`('${sablon}', ARRAY[`);
    }
  });

  it("havuz yalniz kendi deposundan beslenir — dis baglanti yok", () => {
    const adresler = [...foto.matchAll(/'(https:\/\/[^']+)'/g)].map((m) => m[1]);
    expect(adresler.length).toBeGreaterThanOrEqual(82);
    for (const adres of adresler) {
      expect(adres).toContain(
        "https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/",
      );
    }
  });

  it("kapsam yalniz sahibi olmayan kiralik vitrinlerin aktif urunleri", () => {
    expect(foto).toMatch(/s\.is_demo = true/);
    expect(foto).toMatch(/s\.user_id IS NULL/);
    expect(foto).toMatch(/p\.is_active = true/);
    expect(foto).not.toMatch(/is_demo\s*=\s*false/);
  });

  it("her urun havuzdan farkli sirada uc fotograf alir", () => {
    expect(foto).toContain("hedef.havuz_boyu");
    expect(foto).toContain("hedef.havuz[(hedef.sira % hedef.havuz_boyu) + 1]");
    expect(foto).toContain("hedef.havuz[((hedef.sira + 1) % hedef.havuz_boyu) + 1]");
    expect(foto).toContain("hedef.havuz[((hedef.sira + 2) % hedef.havuz_boyu) + 1]");
    expect(foto).toContain("PARTITION BY s.id");
  });

  it("sira belirleyici — rastgelelik yok", () => {
    expect(foto).not.toMatch(/random\(\)/i);
    expect(foto).toContain("coalesce(p.sort_order, 9999), p.created_at, p.slug");
  });

  it("guard: ayni ilk fotograf, eksik fotograf veya 30 disi vitrin kalirsa migration duser", () => {
    expect(foto).toContain("FOTOGRAF_DAGITIMI_DUSTU");
    expect(foto).toContain("ayni ilk fotografi paylasiyor");
    expect(foto).toMatch(/jsonb_array_length\(p\.image_urls\) <> 3/);
    expect(foto).toMatch(/vitrin <> 30/);
  });

  it("vitrin kaydina dokunmaz — yalniz urun gorselleri yazilir", () => {
    expect(foto).not.toMatch(/UPDATE\s+public\.stores/i);
    expect(foto).toMatch(/UPDATE\s+public\.products/i);
    expect(foto).toMatch(/SET image_urls = to_jsonb/);
  });

  it("tek transaction icinde kosar", () => {
    expect(foto).toContain("BEGIN;");
    expect(foto).toContain("COMMIT;");
    expect(foto.indexOf("BEGIN;")).toBeLessThan(foto.indexOf("COMMIT;"));
  });
});

describe("vitrin sayfasi eski adres sozlesmesi", () => {
  it("eski demo adresleri yeni slug'a kalici yonlendirilir", () => {
    expect(sayfa).toContain("LEGACY_STORE_SLUGS");
    expect(sayfa).toContain("permanentRedirect");
    for (const { eski, yeni } of ciftler) {
      expect(sayfa, `${eski} eslemesi yok`).toContain(`"${eski}": "${yeni}"`);
    }
  });

  it("yonlendirme bulunamadi ekranindan once calisir", () => {
    const yonlendirme = sayfa.indexOf("permanentRedirect");
    const bulunamadi = sayfa.indexOf("if (!data) {");
    expect(yonlendirme).toBeGreaterThan(-1);
    expect(bulunamadi).toBeGreaterThan(yonlendirme);
  });
});
