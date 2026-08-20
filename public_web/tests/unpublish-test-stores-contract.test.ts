import { existsSync, readFileSync, readdirSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const migrationName = readdirSync(migrationsDir).find((name) =>
  name.endsWith("_unpublish_test_stores.sql"),
);
const migrationPath = migrationName
  ? resolve(migrationsDir, migrationName)
  : resolve(migrationsDir, "MISSING_unpublish_test_stores.sql");

const expectedTargetSlugs = [
  "aymira-giyim",
  "casper-test-vitrini",
  "cccc",
  "debugtest-1786543537-2",
  "demo-teknofix-8a4e0020",
  "demo-teknofix-ba834c19",
  "deneme",
  "dogrulama-3c7176",
  "xxxxx",
];

const expectedProtectedDemoSlugs = [
  "demo-aymira-giyim",
  "demo-lezzet-duragi",
  "demo-nova-kuafor",
  "demo-teknofix",
  "kiralik-butik",
  "kiralik-gida",
  "kiralik-kafe",
  "kiralik-kuafor",
  "kiralik-teknik",
];

function extractArray(source: string, variable: string): string[] {
  const block = source.match(
    new RegExp(`${variable}\\s+text\\[\\]\\s*:=\\s*array\\[([\\s\\S]*?)\\];`, "i"),
  );
  if (!block) return [];
  return [...block[1].matchAll(/'([^']+)'/g)].map((match) => match[1]).sort();
}

function extractRollbackSlugs(source: string): string[] {
  const rollback = source.match(
    /-- where slug in \(([\s\S]*?)-- \) and is_published = false/i,
  );
  if (!rollback) return [];
  return [...rollback[1].matchAll(/'([^']+)'/g)]
    .map((match) => match[1])
    .sort();
}

describe("#276 test vitrinlerini yayından indirme migration sözleşmesi", () => {
  it("yalnız kararlaştırılan dokuz hedefi ve dokuz korunan demoyu kullanır", () => {
    expect(existsSync(migrationPath)).toBe(true);
    const source = readFileSync(migrationPath, "utf-8");

    expect(extractArray(source, "v_target_slugs")).toEqual(expectedTargetSlugs);
    expect(extractArray(source, "v_protected_demo_slugs")).toEqual(
      expectedProtectedDemoSlugs,
    );
  });

  it("geniş eşleşme veya silme yapmadan tüm güvenlik kapılarını uygular", () => {
    expect(existsSync(migrationPath)).toBe(true);
    const source = readFileSync(migrationPath, "utf-8");
    const executable = source.replace(/--.*$/gm, "");

    expect(executable).not.toMatch(/\b(delete|like|ilike)\b/i);
    expect(executable).toContain("lock table public.stores in share row exclusive mode");
    expect(executable).toContain("if v_existing_target_count = 0 then");
    expect(executable).toContain(
      "elsif v_existing_target_count <> pg_catalog.array_length(v_target_slugs, 1) then",
    );
    expect(executable).toContain(
      "v_target_count <> pg_catalog.array_length(v_target_slugs, 1)",
    );
    expect(executable).toContain("v_target_demo_count <> 0");
    expect(executable).toContain(
      "v_protected_demo_count <> pg_catalog.array_length(v_protected_demo_slugs, 1)",
    );
    expect(executable).toContain("get diagnostics v_updated_count = row_count");
    expect(executable).toContain(
      "v_updated_count <> pg_catalog.array_length(v_target_slugs, 1)",
    );
    expect(executable).toContain("set is_published = false");
    expect(executable).toContain("where slug = any (v_target_slugs)");
    expect(executable).toContain("and is_published = true");
    expect(executable).toContain("and is_demo = false");
  });

  it("otomatik temizliğe girecek klonu korur ve kesin geri dönüşü belgeler", () => {
    expect(existsSync(migrationPath)).toBe(true);
    const source = readFileSync(migrationPath, "utf-8");

    expect(source).toContain("when slug = 'demo-teknofix-8a4e0020' then null");
    expect(source).toContain("ROLLBACK (yalnız acil geri dönüş için)");
    expect(source).toContain("cloned_from_slug = 'demo-teknofix'");
    expect(source).toContain("set is_published = true");
    expect(extractRollbackSlugs(source)).toEqual(expectedTargetSlugs);
  });
});
