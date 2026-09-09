import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const migration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql",
  ),
  "utf8",
);

describe("Vixrex Assistant DB value güvenlik kapısı", () => {
  it("tek internal validator tanımlar ve istemci rollerine açmaz", () => {
    expect(migration).toContain(
      "function public.vixrex_validate_assistant_draft_changes",
    );
    expect(migration).toContain(
      "revoke all on function public.vixrex_validate_assistant_draft_changes(jsonb)",
    );
    expect(migration).toContain("from public, anon, authenticated, service_role");
  });

  it("Next ve Flutter command wrapper'ları aynı DB validatorü çağırır", () => {
    expect(migration).toContain("function public.apply_working_draft_command");
    expect(migration).toContain("function public.apply_owned_working_draft_command");
    const calls = migration.match(
      /perform public\.vixrex_validate_assistant_draft_changes\(p_changes\);/g,
    );
    expect(calls).toHaveLength(2);
  });

  it("yalnız canonical 46 kolon allowlist'ini kabul eder", () => {
    expect(migration).toContain(
      "public.vixrex_assistant_editable_draft_columns()",
    );
    expect(migration).toContain("raise exception 'FIELD_NOT_EDITABLE'");
  });

  it("required, bool ve koordinat sınırlarını fail-closed doğrular", () => {
    for (const required of [
      "'name'",
      "'kategori'",
      "'whatsapp'",
      "'address'",
      "'province_name'",
      "'district_name'",
    ]) {
      expect(migration).toContain(required);
    }
    expect(migration).toContain("'show_storefront_rating'");
    expect(migration).toContain("'show_directions_link'");
    expect(migration).toContain("v_num < -90 or v_num > 90");
    expect(migration).toContain("v_num < -180 or v_num > 180");
  });

  it("telefon, kategori, adres ve URL/görsel semantiğini DB'de doğrular", () => {
    expect(migration).toContain("^905[0-9]{9}$");
    expect(migration).toContain("'Teknik Servis'");
    expect(migration).toContain("v_key = 'address'");
    expect(migration).toContain("v_len < 10");
    expect(migration).toContain("v_key = 'gallery_action_href'");
    expect(migration).toContain("v_text !~ '^#.+$'");
    for (const imageColumn of [
      "'logo_url'",
      "'shelf_image_url'",
      "'featured_banner_image_url'",
      "'about_image_url'",
    ]) {
      expect(migration).toContain(imageColumn);
    }
  });
});
