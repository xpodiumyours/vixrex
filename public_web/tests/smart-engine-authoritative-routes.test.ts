import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const ROOT = resolve(__dirname, "..");
const read = (path: string) => readFileSync(resolve(ROOT, path), "utf8");

const actionRoute = read("src/app/api/owner-smart-engine-action/route.ts");
const undoRoute = read("src/app/api/owner-smart-engine-undo/route.ts");

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
});
