import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const migration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260922010000_kiralik_vitrinleri_30a_tamamla.sql",
  ),
  "utf-8",
);

const yeniSlugs = [
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
] as const;

describe("30 kiralık vitrin sözleşmesi", () => {
  it("21 yeni kanonik şablonu tek transaction içinde ekler", () => {
    expect(yeniSlugs).toHaveLength(21);
    for (const slug of yeniSlugs) expect(migration).toContain(slug);
    expect(migration).toContain("BEGIN;");
    expect(migration).toContain("COMMIT;");
    expect(migration).toContain("KIRALIK_30_PREFLIGHT_FAILED");
    expect(migration).toContain("KIRALIK_30_POSTCHECK_FAILED");
  });

  it("6 kategori x 5 = 30 postcheck yapar", () => {
    expect(migration).toContain("canonical published demos=%");
    for (const kategori of [
      "Giyim",
      "Butik",
      "Gıda",
      "Kafe / Lokanta",
      "Kuaför",
      "Teknik Servis",
    ]) {
      expect(migration).toContain(`KIRALIK_30_POSTCHECK_FAILED: ${kategori}`);
    }
    expect(migration).toContain("v_total<>30");
  });

  it("her yeni vitrinde kalite tabanını zorunlu tutar", () => {
    expect(migration).toContain("v_products<6");
    expect(migration).toContain("v_categories<3");
    expect(migration).toContain("v_articles<3");
    expect(migration).toContain("v_faq<4");
    expect(migration).toContain("v_gallery<5");
    expect(migration).toContain("product_storage_version=2");
  });


  it("temiz DB zincirinde dört landing demosunu 30 havuzuna geri yayınlar", () => {
    for (const slug of [
      "demo-aymira-giyim",
      "demo-lezzet-duragi",
      "demo-nova-kuafor",
      "demo-teknofix",
    ]) {
      expect(migration).toContain(slug);
    }
    expect(migration).toContain("publication_consent_version=c.version");
    expect(migration).toContain("product_storage_version=2");
    expect(migration).toContain("status='açık'");
    expect(migration).toContain("is_demo=true");
    expect(migration).toContain("('demo-aymira-giyim','Aymira Giyim')");
  });

  it("demo korumasını yalnız transaction boyunca açıp geri kapatır", () => {
    const disable = migration.indexOf(
      "ALTER TABLE public.stores DISABLE TRIGGER protect_landing_demo_stores",
    );
    const enable = migration.indexOf(
      "ALTER TABLE public.stores ENABLE TRIGGER protect_landing_demo_stores",
    );
    expect(disable).toBeGreaterThan(0);
    expect(enable).toBeGreaterThan(disable);
    expect(migration.indexOf("COMMIT;")).toBeGreaterThan(enable);
  });

  it("kiralanan vitrinde kategori ürün şablonunu kaybetmez", () => {
    expect(migration).toContain(
      "id, store_id, name, slug, sort_order, is_active, product_template_key",
    );
    expect(migration).toContain("k.product_template_key");
    expect(migration).toContain("clone_demo_store_as_draft");
  });

  it("asistan ve 46 alan yazma motoruna dokunmaz", () => {
    expect(migration).not.toContain("assistant_conversations");
    expect(migration).not.toContain("assistant_messages");
    expect(migration).not.toContain("update_working_draft_field");
    expect(migration).not.toContain("VITRIN_FIELDS");
  });
});
