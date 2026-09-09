import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const undoMigration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260909223500_add_version_guarded_draft_undo.sql"
  ),
  "utf8"
);
const commandMigration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260909233000_add_assistant_storefront_command_core.sql"
  ),
  "utf8"
);
const singleWriteBoundary = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260909224500_keep_single_draft_write_without_assistant_undo.sql"
  ),
  "utf8"
);
const undoRoute = readFileSync(
  resolve(__dirname, "../src/app/api/owner-draft-undo/route.ts"),
  "utf8"
);
const restoreHook = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/hooks/useFieldRestore.ts"),
  "utf8"
);
const ownerActions = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/hooks/useOwnerActions.ts"),
  "utf8"
);

describe("Vixrex Assistant command-bazlı gerçek undo sözleşmesi", () => {
  it("önceki taslak değerlerini sunucuda tutar ve tabloyu istemci rollerine kapatır", () => {
    expect(undoMigration).toContain("create table if not exists public.owner_draft_undo_operations");
    expect(undoMigration).toContain("previous_values jsonb not null");
    expect(undoMigration).toContain("expected_draft_version bigint not null");
    expect(undoMigration).toContain(
      "alter table public.owner_draft_undo_operations enable row level security"
    );
    expect(undoMigration).toContain(
      "revoke all on table public.owner_draft_undo_operations from public, anon, authenticated"
    );
  });

  it("command migration undo kaydını command_id ile birebir bağlar", () => {
    expect(commandMigration).toContain(
      "add column if not exists command_id uuid null"
    );
    expect(commandMigration).toContain(
      "owner_draft_undo_operations_command_unique"
    );
    expect(commandMigration).toContain("p_command_id");
    expect(commandMigration).toContain("command_id = p_command_id");
  });

  it("son migration manuel tek-alan yazımını Assistant undo kaydından ayırır", () => {
    expect(singleWriteBoundary).toContain(
      "create or replace function public.update_working_draft_field("
    );
    expect(singleWriteBoundary).not.toContain("insert into public.owner_draft_undo_operations");
    expect(singleWriteBoundary).toContain("draft_version = draft_version + 1");
  });

  it("Assistant serbest mesajı tek alan olsa bile command batch yolundan geçer", () => {
    const baslangic = ownerActions.indexOf("if (!seciliAlan) {");
    const bitis = ownerActions.indexOf("const alan = seciliAlan;", baslangic);
    const blok = ownerActions.slice(baslangic, bitis);
    expect(blok).toContain('fetch("/api/owner-draft-batch"');
    expect(blok).toContain("const commandId = crypto.randomUUID()");
    expect(blok).toContain('payload: `geri_al:${commandId}`');
    expect(blok).not.toContain('fetch("/api/owner-draft"');
  });

  it("exact command undo yalnız aynı sürümde çalışır; eski kart yeni aynı-alan command'ını ezemez", () => {
    expect(commandMigration).toContain(
      "create or replace function public.vixrex_undo_storefront_command_core("
    );
    expect(commandMigration).toContain("command_id = p_command_id");
    expect(commandMigration).toContain(
      "if v_draft_version <> v_undo.expected_draft_version then"
    );
    expect(commandMigration).toContain("raise exception 'UNDO_STALE'");
    expect(commandMigration).toContain("set consumed_at = now()");
  });

  it("aynı undo tekrar tıklanırsa receipt replay edilir, ikinci veri yazımı yapılmaz", () => {
    const undoStart = commandMigration.indexOf(
      "create or replace function public.vixrex_undo_storefront_command_core("
    );
    const undoBlock = commandMigration.slice(undoStart);
    const replayCheck = undoBlock.indexOf(
      "action = 'vixrex_assistant_storefront_command_undo'"
    );
    const write = undoBlock.indexOf("update public.store_working_drafts");
    expect(replayCheck).toBeGreaterThan(-1);
    expect(write).toBeGreaterThan(replayCheck);
    expect(undoBlock).toContain("'replayed', true");
  });

  it("undo API eski değer/alan listesi kabul etmez; yalnız owner cookie + commandId kullanır", () => {
    expect(undoRoute).toContain("verifyOwnerSession(");
    expect(undoRoute).toContain("OWNER_SESSION_COOKIE");
    expect(undoRoute).toContain('"undo_working_draft_command"');
    expect(undoRoute).toContain("p_command_id: commandId");
    expect(undoRoute).not.toContain("p_keys:");
    expect(undoRoute).not.toContain("anahtarlar?: unknown");
    expect(undoRoute).not.toContain("previous_values:");
    expect(undoRoute).not.toContain("eskiDeger");
  });

  it("Assistant Geri al yeni command undo kapısını kullanır; manuel canlıya dön ayrı kalır", () => {
    const cokluBaslangic = restoreHook.indexOf("const coklaCanliyaDondur");
    const returnBaslangic = restoreHook.indexOf("return { geriAliniyor", cokluBaslangic);
    const cokluBlok = restoreHook.slice(cokluBaslangic, returnBaslangic);

    expect(cokluBlok).toContain('fetch("/api/owner-draft-undo"');
    expect(cokluBlok).toContain("commandId,");
    expect(cokluBlok).not.toContain('fetch("/api/owner-draft-restore"');

    const tekliBaslangic = restoreHook.indexOf("const canliyaDondur");
    const cokluyaKadar = restoreHook.slice(tekliBaslangic, cokluBaslangic);
    expect(cokluyaKadar).toContain('fetch("/api/owner-draft-restore"');
  });
});
