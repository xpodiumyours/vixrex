import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

// 2026-08-21: stores'daki tablo-seviyesi GRANT sızıntısını araştırırken
// aynı desenin (anon/authenticated'e TRUNCATE/MAINTAIN/REFERENCES/TRIGGER
// açık) neredeyse TÜM public şemasında olduğu bulundu. Bu test, şema
// genelindeki düzeltmenin migration dosyasında kalıcı olarak durduğunu
// kilitler.

const migrationPath = resolve(
  __dirname,
  "../../supabase/migrations/20260821200659_emergency_revoke_ddl_adjacent_privileges_all_public_tables.sql",
);
const source = readFileSync(migrationPath, "utf8");

describe("public şemasındaki tüm tablolarda TRUNCATE/DDL-bitişik yetki sızıntısı kapalı kalır", () => {
  it("her tabloya döngüyle revoke uygulanıyor, tek tek elle unutmaya açık liste değil", () => {
    expect(source).toContain("for r in");
    expect(source).toMatch(/from pg_class c\s+where c\.relnamespace = 'public'::regnamespace/);
  });

  it("dört riskli yetkinin hepsi tek REVOKE'ta kapatılıyor", () => {
    expect(source).toContain(
      "revoke truncate, maintain, references, trigger on table public.%I from anon, authenticated;",
    );
  });

  it("SELECT/INSERT/UPDATE/DELETE'e dokunmuyor — yalnız DDL-bitişik yetkiler kaldırılıyor", () => {
    expect(source).not.toMatch(/revoke\s+select\b/i);
    expect(source).not.toMatch(/revoke\s+insert\b/i);
    expect(source).not.toMatch(/revoke\s+update\b/i);
    expect(source).not.toMatch(/revoke\s+delete\b/i);
  });
});
