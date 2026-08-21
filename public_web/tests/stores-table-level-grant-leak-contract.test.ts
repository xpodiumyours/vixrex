import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

// 2026-08-21: `anon` rolünün public.stores üzerinde TABLO SEVİYESİNDE
// SELECT/INSERT/UPDATE/DELETE/TRUNCATE yetkisi olduğu canlıda bulundu —
// edit_token/user_id dahil her sütun sade anon anahtarla okunabiliyordu,
// TRUNCATE ile de tüm tablo boşaltılabilirdi. Bu test o düzeltmenin
// migration dosyasında kalıcı olarak durduğunu kilitler.

const migrationPath = resolve(
  __dirname,
  "../../supabase/migrations/20260821195828_fix_stores_table_level_grant_leak.sql",
);
const source = readFileSync(migrationPath, "utf8");

describe("stores tablo-seviyesi GRANT sızıntısı kapalı kalır", () => {
  it("anon'un tablo seviyesindeki yazma/TRUNCATE yetkileri açıkça kaldırılıyor", () => {
    expect(source).toMatch(
      /revoke insert, update, delete, truncate, trigger, maintain, references\s+on table public\.stores from anon/,
    );
    expect(source).toMatch(/revoke select\s+on table public\.stores from anon/);
  });

  it("hassas sütunlar hem anon hem authenticated'ten açıkça kapatılıyor", () => {
    for (const kolon of [
      "edit_token",
      "user_id",
      "cloned_from_slug",
      "premium_expires_at",
      "premium_reminder_sent_for",
      "version",
    ]) {
      expect(source).toContain(
        `revoke select ("${kolon}") on table public.stores from anon, authenticated;`,
      );
    }
  });

  it("authenticated'in fazla tablo-seviyesi yetkileri kaldırılıyor, UPDATE/DELETE/INSERT dokunulmadan kalır", () => {
    expect(source).toMatch(
      /revoke truncate, maintain, references, trigger\s+on table public\.stores from authenticated/,
    );
    expect(source).not.toMatch(/revoke\s+update[\s\S]{0,40}from authenticated/i);
    expect(source).not.toMatch(/revoke\s+delete[\s\S]{0,40}from authenticated/i);
  });

  it("önceden eksik 13 Keşfet alanı authenticated'e açılıyor", () => {
    for (const kolon of [
      "blog_section_kicker",
      "hero_location_text",
      "neighborhood_name",
      "section_visibility",
    ]) {
      expect(source).toContain(`"${kolon}"`);
    }
    expect(source).toMatch(/grant select \([\s\S]*?\) on table public\.stores to authenticated/);
  });
});
