import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const migration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260811053804_product_core_slug_authority.sql",
  ),
  "utf8",
);
const flutterAdapter = readFileSync(
  resolve(__dirname, "../../lib/repositories/supabase_product_repository.dart"),
  "utf8",
);
const flutterCreateBlock = flutterAdapter.slice(
  flutterAdapter.indexOf("Future<CreatedProduct> createProduct"),
  flutterAdapter.indexOf("Future<void> updateProduct"),
);
const legacyUpdateBlock = migration.slice(
  migration.indexOf("create or replace function public.update_store_product"),
  migration.indexOf("alter function public.update_store_product"),
);

describe("Product CORE slug sözleşmesi", () => {
  it("Türkçe ürün adını CORE içinde canonical slug'a dönüştürür", () => {
    expect(migration).toContain(
      "create or replace function public._normalize_product_slug",
    );
    expect(migration).toContain("ÇĞİIÖŞÜÂÎÛçğıöşüâîû");
    expect(migration).toContain("CGIIOSUAIUcgiosuaiu");
    expect(migration).toContain("'[^a-z0-9]+'");
  });

  it("çakışmaları mağaza içinde sıralı ve eşzamanlı güvenli çözer", () => {
    expect(migration).toContain("pg_catalog.pg_advisory_xact_lock");
    expect(migration).toMatch(
      /pg_catalog\.hashtextextended\(\s*new\.store_id::text,\s*0\s*\)/,
    );
    expect(migration).toContain("products_store_id_slug_key");
    expect(migration).toMatch(/v_base_slug\s*\|\|\s*'-'\s*\|\|\s*v_suffix/);
  });

  it("insertte slug üretir, güncellemede mevcut URL'yi korur", () => {
    expect(migration).toContain(
      "create or replace function public.set_product_canonical_slug",
    );
    expect(migration).toContain("before insert or update on public.products");
    expect(migration).toContain("new.slug := old.slug");
  });

  it("v1 istemcinin slugını geçiş boyunca normalize ederek korur", () => {
    expect(migration).toContain("Legacy v1 compatibility");
    expect(migration).toMatch(
      /new\.slug := public\._normalize_product_slug\(new\.slug\)/,
    );
  });

  it("legacy update RPC artık değişmez slug için çakışma üretmez", () => {
    expect(legacyUpdateBlock).toContain(
      "create or replace function public.update_store_product",
    );
    expect(legacyUpdateBlock).not.toContain("SLUG_ALREADY_EXISTS");
    expect(legacyUpdateBlock).not.toMatch(/\n\s*slug\s*=/i);
  });

  it("yeni ürün RPC'si istemci slugı almadan id ve slug döndürür", () => {
    expect(migration).toContain(
      "create or replace function public.create_store_product_v2",
    );
    expect(migration).not.toMatch(
      /create or replace function public\.create_store_product_v2\([\s\S]*?p_slug/i,
    );
    expect(migration).toContain("'slug', v_new_slug");
    expect(flutterCreateBlock).toContain("'create_store_product_v2'");
    expect(flutterCreateBlock).not.toContain("'p_slug'");
    expect(flutterCreateBlock).toContain("CreatedProduct(id: id, slug: slug)");
  });

  it("iç fonksiyonları kapatır ve veri silen işlem içermez", () => {
    expect(migration).toContain("set search_path = ''");
    expect(migration).toContain(
      "revoke execute on function public._normalize_product_slug(text) from public",
    );
    expect(migration).toContain(
      "revoke execute on function public.set_product_canonical_slug() from public",
    );
    expect(migration).not.toMatch(/drop\s+table|truncate\s+table|delete\s+from/i);
  });
});
