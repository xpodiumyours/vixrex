import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const schema = JSON.parse(
  readFileSync(resolve(__dirname, "../../shared/product_attribute_schema.json"), "utf8"),
) as { version?: number };
const migration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260914223000_product_metadata_schema_v2.sql",
  ),
  "utf8",
);

describe("Product CORE metadata şema sürümü", () => {
  it("ortak ürün şeması ve veritabanı yazım sınırı sürüm 2'de eşittir", () => {
    expect(schema.version).toBe(2);
    expect(migration).toContain("enforce_product_metadata_schema_version");
    expect(migration).toContain("'{schemaVersion}'");
    expect(migration).toContain("'2'::jsonb");
    expect(migration).toContain("before insert or update of metadata on public.products");
  });

  it("yalnız tanımlı rich product metadata'sını sürümler", () => {
    expect(migration).toContain("(new.metadata->>'itemKind') in ('physical', 'service')");
    expect(migration).toContain("new.metadata->>'templateKey'");
  });
});
