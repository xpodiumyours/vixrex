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
const undoRoute = readFileSync(
  resolve(__dirname, "../src/app/api/owner-draft-undo/route.ts"),
  "utf8"
);
const restoreHook = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/hooks/useFieldRestore.ts"),
  "utf8"
);

describe("Vixrex Assistant gerçek son-işlem undo sözleşmesi", () => {
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

  it("tek ve çok alan yazımı önceki değeri aynı transaction içinde undo kaydına bağlar", () => {
    expect(undoMigration).toContain(
      "create or replace function public.update_working_draft_field("
    );
    expect(undoMigration).toContain(
      "create or replace function public.update_working_draft_fields("
    );
    expect(undoMigration.match(/insert into public\.owner_draft_undo_operations/g)?.length).toBe(2);
    expect(undoMigration).toContain("for update;");
  });

  it("undo yalnız hâlâ en son draft sürümüyse çalışır ve tek kullanımlıdır", () => {
    expect(undoMigration).toContain(
      "create or replace function public.undo_latest_working_draft_change("
    );
    expect(undoMigration).toContain(
      "if v_draft_version <> v_expected_draft_version then"
    );
    expect(undoMigration).toContain("raise exception 'UNDO_STALE'");
    expect(undoMigration).toContain("and consumed_at is null");
    expect(undoMigration).toContain("set consumed_at = now()");
  });

  it("undo API eski değer kabul etmez; owner cookie + alan anahtarlarıyla RPC çağırır", () => {
    expect(undoRoute).toContain("verifyOwnerSession(");
    expect(undoRoute).toContain("OWNER_SESSION_COOKIE");
    expect(undoRoute).toContain("FIELD_BY_KEY.get(anahtar)");
    expect(undoRoute).toContain('"undo_latest_working_draft_change"');
    expect(undoRoute).toContain("p_keys: kolonlar");
    expect(undoRoute).not.toContain("previous_values:");
    expect(undoRoute).not.toContain("eskiDeger");
  });

  it("Assistant kartındaki çoklu Geri al yeni undo kapısını kullanır; manuel canlıya dön ayrı kalır", () => {
    const cokluBaslangic = restoreHook.indexOf("const coklaCanliyaDondur");
    const returnBaslangic = restoreHook.indexOf("return { geriAliniyor", cokluBaslangic);
    const cokluBlok = restoreHook.slice(cokluBaslangic, returnBaslangic);

    expect(cokluBlok).toContain('fetch("/api/owner-draft-undo"');
    expect(cokluBlok).not.toContain('fetch("/api/owner-draft-restore"');

    const tekliBaslangic = restoreHook.indexOf("const canliyaDondur");
    const cokluyaKadar = restoreHook.slice(tekliBaslangic, cokluBaslangic);
    expect(cokluyaKadar).toContain('fetch("/api/owner-draft-restore"');
  });
});
