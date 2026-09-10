import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

interface AlanKaydi {
  kolon?: unknown;
}

interface AlanSemasi {
  alanlar?: unknown;
}

const sharedSchemaPath = resolve(
  __dirname,
  "../../shared/vitrin_alanlari.json",
);
const migrationPath = resolve(
  __dirname,
  "../../supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql",
);

const sharedSchema = JSON.parse(
  readFileSync(sharedSchemaPath, "utf8"),
) as AlanSemasi;
const migration = readFileSync(migrationPath, "utf8");

function canonicalColumns(): string[] {
  expect(Array.isArray(sharedSchema.alanlar)).toBe(true);
  return (sharedSchema.alanlar as AlanKaydi[]).map((alan) => {
    expect(typeof alan.kolon).toBe("string");
    const kolon = String(alan.kolon).trim();
    expect(kolon.length).toBeGreaterThan(0);
    return kolon;
  });
}

function sqlAllowlistColumns(): string[] {
  const functionStart = migration.indexOf(
    "create or replace function public.vixrex_assistant_editable_draft_columns()",
  );
  const functionEnd = migration.indexOf(
    "comment on function public.vixrex_assistant_editable_draft_columns()",
    functionStart,
  );
  expect(functionStart).toBeGreaterThanOrEqual(0);
  expect(functionEnd).toBeGreaterThan(functionStart);

  const block = migration.slice(functionStart, functionEnd);
  const arrayMatch = block.match(/select\s+array\[([\s\S]*?)\]::text\[\];/i);
  expect(arrayMatch).not.toBeNull();

  return Array.from(arrayMatch?.[1].matchAll(/'([^']+)'/g) ?? []).map(
    (match) => match[1],
  );
}

describe("Flutter Assistant DB 46-alan yetki kontratı", () => {
  it("DB allowlist canonical 46 alan kolonuyla birebir aynıdır", () => {
    const canonical = canonicalColumns();
    const sqlColumns = sqlAllowlistColumns();

    expect(canonical).toHaveLength(46);
    expect(new Set(canonical).size).toBe(canonical.length);
    expect(sqlColumns).toEqual(canonical);
  });

  it("authenticated batch RPC pozitif Assistant allowlist kontrolünü zorunlu tutar", () => {
    const rpcStart = migration.indexOf(
      "create or replace function public.update_owned_working_draft_fields(",
    );
    expect(rpcStart).toBeGreaterThanOrEqual(0);
    const rpcBlock = migration.slice(rpcStart);

    expect(rpcBlock).toContain(
      "v_key = any (public.vixrex_assistant_editable_draft_columns())",
    );
    expect(rpcBlock).toContain("raise exception 'FIELD_NOT_EDITABLE'");
    expect(rpcBlock).toContain("public.owner_forbidden_draft_keys()");
  });

  it("allowlist helper istemcilere açık değildir; yazma RPC'si yalnız authenticated rolündedir", () => {
    expect(migration).toContain(
      "revoke all on function public.vixrex_assistant_editable_draft_columns()",
    );
    expect(migration).toContain("from public, anon, authenticated, service_role");
    expect(migration).toContain(
      "revoke all on function public.update_owned_working_draft_fields(jsonb)",
    );
    expect(migration).toContain("from public, anon, service_role");
    expect(migration).toContain(
      "grant execute on function public.update_owned_working_draft_fields(jsonb)",
    );
    expect(migration).toContain("to authenticated");
  });
});
