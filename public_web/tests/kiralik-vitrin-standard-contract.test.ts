import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

const migration = readFileSync(
  resolve(__dirname, "../../supabase/migrations/20260921184712_kiralik_vitrin_standardini_tamamla.sql"),
  "utf-8",
);

const targets = [
  "kiralik-teknik",
  "demo-lezzet-duragi",
  "demo-nova-kuafor",
  "demo-aymira-giyim",
] as const;

describe("kiralık vitrin ortak standardı", () => {
  it("dört eksik vitrini kapsar", () => {
    for (const slug of targets) expect(migration).toContain(slug);
  });

  it("tek transaction ve fail-closed kontroller kullanır", () => {
    expect(migration).toContain("BEGIN;");
    expect(migration).toContain("KIRALIK_STANDARD_PREFLIGHT_FAILED");
    expect(migration).toContain("POSTCHECK");
    expect(migration).toContain("COMMIT;");
  });

  it("içerik standardını yayın veya demo bayrağına bağlamaz", () => {
    expect(migration).not.toContain("AND is_published = true");
    expect(migration).not.toContain("AND is_demo = true");
    expect(migration).toContain("WHERE s.user_id IS NULL");
    expect(migration).toContain("('kiralik-teknik','Hızlı Teknik')");
    expect(migration).toContain("('demo-lezzet-duragi','Lezzet Durağı')");
    expect(migration).toContain("('demo-nova-kuafor','Nova Kuaför')");
    expect(migration).toContain("('demo-aymira-giyim','Aymira Giyim')");
  });

  it("üç boş demo için gerçek kategori ve ürün tablolarını doldurur", () => {
    expect(migration).toContain("INSERT INTO public.product_categories");
    expect(migration).toContain("INSERT INTO public.products");
    expect(migration).toContain("('demo-lezzet-duragi',6,3,0)");
    expect(migration).toContain("('demo-nova-kuafor',6,3,5)");
    expect(migration).toContain("('demo-aymira-giyim',6,3,0)");
  });

  it("dört vitrinde Hakkımızda, en az 4 SSS ve 3 blog zorunludur", () => {
    expect(migration).toContain("v_articles < 3");
    expect(migration).toContain("v_faq < 4");
    expect(migration).toContain("about missing");
  });

  it("Nova galerisi en az 5 görsel olarak doğrulanır", () => {
    expect(migration).toContain("('demo-nova-kuafor',6,3,5)");
    expect(migration).toContain('"gallery-3"');
  });

  it("Asistan ve kiralama motoruna dokunmaz", () => {
    expect(migration).not.toContain("clone_demo_store_as_draft");
    expect(migration).not.toContain("assistant_conversations");
    expect(migration).not.toContain("update_working_draft_field");
  });
});
