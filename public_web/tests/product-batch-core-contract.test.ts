import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const migration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260914103000_batch_product_price_consistency.sql",
  ),
  "utf8",
);

describe("batch Product CORE sözleşmesi", () => {
  it("mevcut tek batch RPC yolunu korur ve Product CORE v3 üzerinden yazar", () => {
    expect(migration).toContain("create or replace function public.batch_create_products(");
    expect(migration).toContain("public.create_store_product_v3(");
    expect(migration).not.toContain("insert into public.products");
  });

  it("zengin çekirdek alanlarını taşır", () => {
    expect(migration).toContain("v_brand");
    expect(migration).toContain("v_barcode");
    expect(migration).toContain("v_sku");
    expect(migration).toContain("v_stock_quantity");
    expect(migration).toContain("v_stock_status");
    expect(migration).toContain("v_category_name");
    expect(migration).toContain("'schemaVersion', 2");
    expect(migration).toContain("'identifiers'");
  });

  it("tek hatalı satırda tüm partiyi iptal etmez", () => {
    expect(migration).toContain("for v_product in");
    expect(migration).toContain("exception when others then");
    expect(migration).toContain("v_error_count := v_error_count + 1");
    expect(migration).toContain("v_success_count := v_success_count + 1");
    expect(migration).toContain("'error_details', v_errors");
  });

  it("minimum 3 görseli veritabanı yazma şartı yapmaz, yalnız 11 üst sınırını korur", () => {
    expect(migration).toContain("jsonb_array_length(v_image_urls) > 11");
    expect(migration).not.toMatch(/jsonb_array_length\(v_image_urls\)\s*<\s*3/);
    expect(migration).not.toContain("enforce_product_image_count");
  });

  it("service kategorisinde marka, barkod ve stok verisini sessizce silmez", () => {
    expect(migration).not.toContain(
      "case when v_item_kind = 'service' then null else v_brand end",
    );
    expect(migration).not.toContain(
      "case when v_item_kind = 'service' then null else v_barcode end",
    );
    expect(migration).not.toContain(
      "case when v_item_kind = 'service' then null else v_stock_quantity end",
    );
    expect(migration).toContain("p_brand => v_brand");
    expect(migration).toContain("p_barcode => v_barcode");
    expect(migration).toContain("p_stock_quantity => v_stock_quantity");
  });

  it("Türkçe fiyat biçimini ortak veritabanı kuralıyla çözer", () => {
    expect(migration).toContain("public._parse_product_price_amount");
    expect(migration).toContain("v_clean ~ '^[0-9]{1,3}(\\.[0-9]{3})+$'");
    expect(migration).toContain("pg_catalog.replace(v_clean, '.', '')");
    expect(migration).toContain("pg_catalog.replace(v_clean, ',', '.')");
  });

  it("SECURITY DEFINER fonksiyonunu PUBLIC'e açık bırakmaz", () => {
    expect(migration).toContain(
      "revoke all on function public.batch_create_products(uuid, text, jsonb) from public",
    );
    expect(migration).toContain("to anon, authenticated, service_role");
  });
});
