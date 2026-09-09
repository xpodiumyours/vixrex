import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const route = readFileSync(
  resolve(__dirname, "../src/app/api/owner-draft-batch/route.ts"),
  "utf8",
);
const legacyBatchMigration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260909211500_add_atomic_working_draft_batch.sql",
  ),
  "utf8",
);
const commandMigration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260909233000_add_assistant_storefront_command_core.sql",
  ),
  "utf8",
);

describe("Vixrex Assistant atomik command kayıt kapısı", () => {
  it("owner yetkisini yalnız HttpOnly cookie üzerinden doğrular", () => {
    expect(route).toContain("OWNER_SESSION_COOKIE");
    expect(route).toContain("verifyOwnerSession");
    expect(route).not.toMatch(/govde\.(sessionToken|session_token|storeId|store_id)/);
  });

  it("istemciden kolon kabul etmez; anahtarları validateField ile sunucuda çözer", () => {
    expect(route).toContain("validateField(anahtar, ham.deger)");
    expect(route).toContain("kolon: sonuc.alan.kolon");
    expect(route).not.toMatch(/ham\.(kolon|column)/);
  });

  it("bir alan geçersizse command RPC çağrısından önce 422 döner", () => {
    const validation = route.indexOf("validateField(anahtar, ham.deger)");
    const rpc = route.indexOf('rpc("apply_working_draft_command"');
    expect(validation).toBeGreaterThan(-1);
    expect(rpc).toBeGreaterThan(validation);
    expect(route).toContain("Bir alan bile geçersizse RPC HİÇ çağrılmaz");
  });

  it("tek kullanıcı işlemini tek command RPC ve tek broadcast ile tamamlar", () => {
    expect(route.match(/apply_working_draft_command/g)?.length).toBe(1);
    expect(route.match(/broadcastTaslakGuncellendi\(slug, clientId\)/g)?.length).toBe(1);
    expect(route).not.toContain('fetch("/api/owner-draft"');
  });

  it("commandId doğrular, yoksa geriye uyum için sunucuda üretir", () => {
    expect(route).toContain("UUID_RE");
    expect(route).toContain("suppliedCommandId || randomUUID()");
    expect(route).toContain("p_command_id: commandId");
    expect(route).toContain("commandId: sonuc?.command_id ?? commandId");
  });

  it("aynı anahtarı iki kez ve aşırı büyük batch'i reddeder", () => {
    expect(route).toContain("MAX_BATCH_FIELDS = 20");
    expect(route).toContain("gorulenAnahtarlar.has(anahtar)");
  });
});

describe("legacy update_working_draft_fields atomiklik sözleşmesi", () => {
  it("mevcut owner-session ve forbidden-key güvenlik omurgasını tekrar kullanır", () => {
    expect(legacyBatchMigration).toContain("public.owner_sessions");
    expect(legacyBatchMigration).toContain("public.owner_forbidden_draft_keys()");
    expect(legacyBatchMigration).toContain("INVALID_SESSION_TOKEN");
    expect(legacyBatchMigration).toContain("DEMO_STORE_IMMUTABLE");
    expect(legacyBatchMigration).toContain("FIELD_NOT_EDITABLE");
    expect(legacyBatchMigration).toContain("UNKNOWN_FIELD");
  });

  it("taslak tabloya tek UPDATE yapar ve sürümü yalnız bir artırır", () => {
    expect(legacyBatchMigration.match(/update public\.store_working_drafts/g)?.length).toBe(1);
    expect(legacyBatchMigration).toContain("draft_version = draft_version + 1");
  });

  it("JSON null'u mevcut tek-alan RPC gibi anahtarı kaldırarak uygular", () => {
    expect(legacyBatchMigration).toContain("v_new_data := v_new_data - v_key");
  });
});

describe("storefront command SQL sözleşmesi", () => {
  it("iki istemciyi aynı kapalı core fonksiyonuna bağlar", () => {
    expect(commandMigration).toContain("public.vixrex_apply_storefront_command_core(");
    expect(commandMigration).toContain("public.apply_working_draft_command(");
    expect(commandMigration).toContain("public.apply_owned_working_draft_command(");
    expect(commandMigration).toContain(
      "revoke all on function public.vixrex_apply_storefront_command_core("
    );
  });

  it("command receipt + idempotency + undo kaydını aynı transaction omurgasında tutar", () => {
    expect(commandMigration).toContain("vixrex_assistant_storefront_command");
    expect(commandMigration).toContain("IDEMPOTENCY_KEY_REUSE");
    expect(commandMigration).toContain("insert into public.owner_draft_undo_operations");
    expect(commandMigration).toContain("insert into public.audit_logs");
    expect(commandMigration).toContain("'command_id', p_command_id::text");
  });
});
