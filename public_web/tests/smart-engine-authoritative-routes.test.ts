import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const ROOT = resolve(__dirname, "..");
const read = (path: string) => readFileSync(resolve(ROOT, path), "utf8");

const actionRoute = read("src/app/api/owner-smart-engine-action/route.ts");
const undoRoute = read("src/app/api/owner-smart-engine-undo/route.ts");
const locationRoute = read("src/app/api/owner-location-bundle/route.ts");
const manualDraftRoute = read("src/app/api/owner-draft/route.ts");
const locationMigration = read(
  "../supabase/migrations/20260905154433_smart_engine_location_bundle.sql",
);
const locationAclMigration = read(
  "../supabase/migrations/20260905155137_harden_location_bundle_acl.sql",
);

describe("Akıllı Motor authoritative owner routes", () => {
  it("action route HttpOnly owner session + authoritative RPC kullanır", () => {
    expect(actionRoute).toContain("OWNER_SESSION_COOKIE");
    expect(actionRoute).toContain("verifyOwnerSession");
    expect(actionRoute).toContain("smartEngineStorefrontServerEnabled");
    expect(actionRoute).toContain('admin.rpc("vixrex_apply_storefront_action"');
    expect(actionRoute).toContain("p_expected_draft_version: expectedDraftVersion");
    expect(actionRoute).toContain("p_action_id: actionId");
    expect(actionRoute).toContain("p_command_id: commandId");
  });

  it("action route eski assistant persistence RPC'sine geri düşmez", () => {
    expect(actionRoute).not.toContain('rpc("update_working_draft_field"');
    expect(actionRoute).not.toContain("p_key:");
    expect(actionRoute).toContain("DRAFT_VERSION_CONFLICT");
    expect(actionRoute).toContain("IDEMPOTENCY_KEY_REUSE");
    expect(actionRoute).toContain("UNKNOWN_MUTATION_OUTCOME");
  });

  it("server canonical validation + rate limit katmanlarını korur", () => {
    expect(actionRoute).toContain("validateField(anahtar, govde.deger)");
    expect(actionRoute).toContain("consume_assistant_request");
    expect(actionRoute).toContain("RATE_LIMITED");
    expect(actionRoute).toContain("RATE_LIMIT_SERVICE_ERROR");
  });

  it("undo route commandId receipt tabanlı authoritative RPC kullanır", () => {
    expect(undoRoute).toContain("OWNER_SESSION_COOKIE");
    expect(undoRoute).toContain("verifyOwnerSession");
    expect(undoRoute).toContain("smartEngineStorefrontServerEnabled");
    expect(undoRoute).toContain('admin.rpc("vixrex_undo_storefront_command"');
    expect(undoRoute).toContain("p_command_id: commandId");
    expect(undoRoute).toContain("UNDO_CONFLICT");
    expect(undoRoute).toContain("UNDO_COMMAND_NOT_FOUND");
  });

  it("undo route field listesi veya legacy restore RPC kabul etmez", () => {
    expect(undoRoute).not.toContain("restore_working_draft_field");
    expect(undoRoute).not.toContain("anahtarlar");
    expect(undoRoute).not.toContain("fieldKeys");
  });

  it("GPS location bundle HttpOnly owner session + tek authoritative RPC kullanır", () => {
    expect(locationRoute).toContain("OWNER_SESSION_COOKIE");
    expect(locationRoute).toContain("verifyOwnerSession");
    expect(locationRoute).toContain("smartEngineStorefrontServerEnabled");
    expect(locationRoute).toContain('admin.rpc("vixrex_apply_location_bundle"');
    expect(locationRoute).toContain("p_expected_draft_version: expectedDraftVersion");
    expect(locationRoute).toContain("p_command_id: commandId");
    expect(locationRoute).toContain("turkeyDistricts[province.code]");
    expect(locationRoute).toContain('validateField("enlem", latitude)');
    expect(locationRoute).toContain('validateField("boylam", longitude)');
    expect(locationRoute).toContain('validateField("adres", address)');
  });

  it("GPS route legacy field-by-field mutation'a geri düşmez", () => {
    expect(locationRoute).not.toContain('fetch("/api/owner-draft"');
    expect(locationRoute).not.toContain("Promise.all");
    expect(locationRoute).not.toContain('rpc("update_working_draft_field"');
    expect(locationRoute).toContain("DRAFT_VERSION_CONFLICT");
    expect(locationRoute).toContain("IDEMPOTENCY_KEY_REUSE");
    expect(locationRoute).toContain("INVALID_LOCATION_RELATION");
  });

  it("location migration bundle'ı tek draft update + tek version artışıyla yazar", () => {
    expect(locationMigration).toContain("create or replace function public.vixrex_apply_location_bundle");
    expect(locationMigration).toContain("for update");
    expect(locationMigration).toContain("draft_version = draft_version + 1");
    expect(locationMigration).toContain("'smart_engine_location_bundle'");
    expect(locationMigration).toContain("IDEMPOTENCY_KEY_REUSE");
    expect(locationMigration).toContain("DRAFT_VERSION_CONFLICT");
    expect(locationMigration).toContain("INVALID_LOCATION_RELATION");
  });

  it("location bundle RPC yalnız service_role üzerinden çağrılabilir", () => {
    expect(locationAclMigration).toContain("revoke execute on function public.vixrex_apply_location_bundle");
    expect(locationAclMigration).toContain("from public, anon, authenticated");
    expect(locationAclMigration).toContain("grant execute on function public.vixrex_apply_location_bundle");
    expect(locationAclMigration).toContain("to service_role");
  });

  it("manual owner-draft route legacy smart-engine mutation'ı fail-closed reddeder", () => {
    expect(manualDraftRoute).toContain('govde.source === "smart_engine"');
    expect(manualDraftRoute).toContain("SMART_ENGINE_AUTHORITATIVE_ROUTE_REQUIRED");
    expect(manualDraftRoute).toContain("status: 409");
    expect(manualDraftRoute).toContain('rpc("update_working_draft_field"');
  });
});
