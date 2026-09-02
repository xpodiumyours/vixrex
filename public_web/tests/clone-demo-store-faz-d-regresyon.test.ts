import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * clone_demo_store_as_draft — Faz D2 (Tek Asistan planı, 2026-09-02).
 *
 * BULUNAN REGRESYON (canlı fonksiyon tanımı pg_get_functiondef ile
 * okunarak doğrulandı, 2026-09-02): 20260901060000_extend_demo_trial_
 * token_14_days.sql, ürün/kategori kopyalamayı ve cloned_from_slug'ı
 * ÜÇÜNCÜ KEZ kaybetmişti (20260826000000'ın kendi başlığında anlattığı
 * aynı hata deseni: eski gövde üzerine CREATE OR REPLACE). Bu dosya
 * ("20260902111032_faz_d2_clone_demo_fix_and_identity_null.sql") düzeltiyor —
 * bu test bir DAHA kaybolmasını önlüyor.
 *
 * Faz D2 kural seti: gerçek işletme kimliği ve kampanya bandı artık
 * şablondan kopyalanmıyor — boş/null başlıyor.
 */
const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const kaynak = readFileSync(
  resolve(migrationsDir, "20260902111032_faz_d2_clone_demo_fix_and_identity_null.sql"),
  "utf-8"
);

describe("clone_demo_store_as_draft — ürün/kategori kopyalama regresyonu bir daha olmasın", () => {
  it("cloned_from_slug INSERT sütun listesinde ve değeri var", () => {
    expect(kaynak).toContain("cloned_from_slug");
    expect(kaynak).toContain("pg_catalog.btrim(p_source_slug)");
  });

  it("kategori + ürün kopyalama mantığı tam — eski→yeni id eşlemesiyle", () => {
    expect(kaynak).toContain("insert into public.product_categories");
    expect(kaynak).toContain("insert into public.products");
    expect(kaynak).toContain("_kategori_esleme");
    expect(kaynak).toContain("on commit drop");
    expect(kaynak).toMatch(/left join _kategori_esleme e on e\.eski_id = p\.category_id/);
  });

  it("14 günlük deneme süresi korunuyor", () => {
    expect(kaynak).toContain("now() + interval '14 days'");
  });
});

describe("clone_demo_store_as_draft — Faz D: gerçek kimlik şablondan kopyalanmaz", () => {
  const insertBlock = kaynak.slice(
    kaynak.indexOf("insert into public.stores"),
    kaynak.indexOf("from public.stores\n  where id = v_source_id")
  );

  it("name/whatsapp/address boş string ile başlar (NOT NULL kolonlar)", () => {
    // SELECT listesinde kolon adı DEĞİL literal '' geçmeli.
    expect(insertBlock).toMatch(/'',\s*business_type/);
    expect(insertBlock).toMatch(/'',\s*null,\s*null,\s*hero_badge/);
    expect(insertBlock).toMatch(/website,\s*''/);
  });

  it("phone/email/logo_url/working_hours/GPS/Google linki null", () => {
    for (const desen of [
      /'',\s*null,\s*null,\s*hero_badge/, // whatsapp, phone, email
      /vcard_link,\s*shelf_image_url,\s*null,\s*\n\s*null,\s*false,\s*is_store/, // logo_url, working_hours
    ]) {
      expect(insertBlock).toMatch(desen);
    }
    expect(insertBlock).toContain("google_business_link");
  });

  it("kampanya bandı (bant*) null — sahte kampanya iddiası olmaz", () => {
    expect(insertBlock).toMatch(/null, null, null, null, null,\s*\n\s*faq_items/);
  });
});
