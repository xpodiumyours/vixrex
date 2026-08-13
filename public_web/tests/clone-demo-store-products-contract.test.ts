import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * "Bu vitrini kirala" — gerçek ürün kataloğunu kopyalama. Casper
 * (2026-08-14): "kirala ile açılan vitrinlerde kategori ve ürünler
 * gelmiyor." Kök sebep: ürünler stores.products (JSONB, boş/kullanılmayan)
 * DEĞİL, ayrı `products` + `product_categories` tablolarında — önceki
 * clone_demo_store_as_draft bunlara hiç dokunmuyordu.
 */

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const migrationSource = readFileSync(
  resolve(migrationsDir, "20260815000000_clone_demo_store_products.sql"),
  "utf-8"
);

describe("clone_demo_store_as_draft — ilişkisel ürün/kategori kopyalama", () => {
  it("product_categories'ten yeni store_id ile kopyalar", () => {
    expect(migrationSource).toContain("insert into public.product_categories");
    expect(migrationSource).toContain("where store_id = v_source_id");
  });

  it("products'tan yeni store_id ile kopyalar", () => {
    expect(migrationSource).toContain("insert into public.products");
  });

  it("eski→yeni kategori id eşlemesi kullanılır (rastgele/sabit değil)", () => {
    expect(migrationSource).toContain("_kategori_esleme");
    expect(migrationSource).toContain(
      "left join _kategori_esleme e on e.eski_id = p.category_id"
    );
  });

  it("kategorisiz ürünler için category_id null kalır (left join, inner değil)", () => {
    expect(migrationSource).toMatch(/left join _kategori_esleme/);
    expect(migrationSource).not.toMatch(
      /inner join _kategori_esleme[\s\S]{0,40}category_id/
    );
  });

  it("geçici eşleme tablosu commit'te otomatik silinir (kalıcı iz bırakmaz)", () => {
    expect(migrationSource).toContain("create temporary table _kategori_esleme");
    expect(migrationSource).toContain("on commit drop");
  });

  it("yeni id'ler üretiliyor — kaynağın id'leri birebir kopyalanmıyor", () => {
    expect(migrationSource).toContain("gen_random_uuid()");
  });
});
