import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const source = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260918090000_kiralik_urunleri_guncel_sozlesmeye_tasi.sql",
  ),
  "utf-8",
);

const expectedSlugs = [
  "demo-aymira-giyim",
  "demo-lezzet-duragi",
  "demo-nova-kuafor",
  "demo-teknofix",
  "kiralik-butik",
  "kiralik-gida",
  "kiralik-kafe",
  "kiralik-kuafor",
  "kiralik-teknik",
].sort();

describe("kiralık vitrin ürün sözleşmesi", () => {
  it("yalnız dokuz kanonik demo kaynağını hedefler", () => {
    const slugs = [...source.matchAll(/\('(demo-[^']+|kiralik-[^']+)'(?:,|\))/g)]
      .map((match) => match[1])
      .filter((slug, index, all) => all.indexOf(slug) === index)
      .sort();

    expect(slugs).toEqual(expectedSlugs);
    expect(source).toContain("where s.is_demo = true");
  });

  it("kategori, fiziksel ürün ve hizmet metadata sözleşmesini v2'ye taşır", () => {
    expect(source).toContain("set product_template_key = case");
    expect(source).toContain("then 'electronics'");
    expect(source).toContain("'schemaVersion', 2");
    expect(source).toContain("'itemKind', 'physical'");
    expect(source).toContain("'itemKind', 'service'");
    expect(source).toContain("'templateKey', alanlar.product_template_key");
    expect(source).toContain("'serviceType', p.name");
    expect(source).toContain("'priceMode', kaynak.fiyat_bicimi");
    expect(source).toContain("'serviceLocation', 'business'");
  });

  it("yeni kiralamada kategori ürün şablonunu kaynak vitrinden aynen kopyalar", () => {
    const categoryInsert = source.slice(
      source.indexOf("insert into public.product_categories"),
      source.indexOf("insert into public.products"),
    );

    expect(categoryInsert).toContain("product_template_key");
    expect(categoryInsert).toContain("k.product_template_key");
    expect(source).toContain("where slug = pg_catalog.btrim(p_source_slug)");
    expect(source).toContain("and is_demo = true");
  });
});
