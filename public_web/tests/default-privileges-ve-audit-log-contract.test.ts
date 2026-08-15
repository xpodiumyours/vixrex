import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * Kök sebep düzeltmesi (2026-08-15): temel şema `ALTER DEFAULT PRIVILEGES
 * ... GRANT ALL ON FUNCTIONS TO anon` içeriyordu — her yeni fonksiyon
 * açıkça revoke edilmedikçe otomatik olarak anon'a açık doğuyordu. Bu,
 * cleanup_expired_trial_clones'un hiç `revoke` almadan yine de açık
 * olmasının gerçek sebebiydi. Bu testler düzeltmenin gerçekten
 * uygulandığını doğrular.
 */

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const source = readFileSync(
  resolve(migrationsDir, "20260815210000_default_privileges_ve_audit_log.sql"),
  "utf-8"
);

describe("Kök sebep — yeni fonksiyonlar artık kapalı doğar", () => {
  it("ALTER DEFAULT PRIVILEGES ile anon/authenticated'ten FUNCTIONS revoke edilir", () => {
    expect(source).toContain(
      "alter default privileges for role postgres in schema public\n  revoke all on functions from anon, authenticated;"
    );
  });

  it("TABLES/SEQUENCES'e dokunulmaz — yalnız FUNCTIONS (RLS zaten tabloları koruyor)", () => {
    expect(source).not.toMatch(/revoke all on (tables|sequences)/i);
  });
});

describe("log_audit_event — kullanılmayan sahtecilik açığı kapatılır", () => {
  it("SECURITY DEFINER + sabit search_path", () => {
    expect(source).toContain("security definer");
    expect(source).toContain("set search_path = pg_catalog, public");
  });

  it("anon/authenticated/PUBLIC'ten açıkça revoke edilir", () => {
    expect(source).toContain(
      "revoke execute on function public.log_audit_event(uuid, text, text, text, text, jsonb, jsonb, jsonb)\n  from public, anon, authenticated;"
    );
  });

  it("p_user_id hâlâ client parametresi — ama artık kimse çağıramaz (dürüstlük notu var)", () => {
    expect(source).toContain("p_user_id client");
  });
});

describe("get_audit_logs — yalnız anon'dan kapatılır, authenticated'in meşru kullanımı korunur", () => {
  it("her iki overload da anon'dan revoke edilir", () => {
    expect(source).toContain(
      "revoke execute on function public.get_audit_logs(integer, text, text)\n  from anon;"
    );
    expect(source).toContain(
      "revoke execute on function public.get_audit_logs(integer, uuid, text, text)\n  from anon;"
    );
  });

  it("authenticated'ten revoke edilmez — kullanıcı kendi kaydını okuyabilmeli", () => {
    expect(source).not.toMatch(
      /revoke execute on function public\.get_audit_logs[\s\S]*?from[\s\S]*?authenticated/
    );
  });
});
