import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

const migration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260811180000_assistant_handoff_core.sql"
  ),
  "utf-8"
);

describe("Vixrex Asistan güvenli handoff CORE sözleşmesi", () => {
  it("ikinci veri omurgası açmadan owner_sessions'a bağlanır", () => {
    expect(migration).toContain(
      "alter table public.owner_sessions\n  add column if not exists assistant_handoff jsonb"
    );
    expect(migration).not.toMatch(
      /create\s+table(?:\s+if\s+not\s+exists)?\s+public\.[^\s;]*handoff/i
    );
    expect(migration).toContain(
      "alter table public.owner_sessions enable row level security"
    );
    expect(migration).toContain(
      "revoke all on table public.owner_sessions from anon, authenticated"
    );
  });

  it("handoff_v1'i boyut, adım ve mesaj izin listeleriyle normalize eder", () => {
    expect(migration).toContain("v_version <> 1");
    expect(migration).toContain(
      "pg_catalog.octet_length(p_data::text) > 16384"
    );
    expect(migration).toContain(
      "jsonb_array_length(v_messages_input) > 24"
    );
    expect(migration).toContain(
      "pg_catalog.char_length(v_text) > 500"
    );

    for (const step of [
      "name",
      "category",
      "whatsapp",
      "location",
      "legal",
      "publishing",
      "done",
    ]) {
      expect(migration, `${step} izin listesinde yok`).toContain(
        `'${step}'`
      );
    }

    expect(migration).toContain(
      "not (v_role = any (array['assistant', 'user']))"
    );
    expect(migration).toContain(
      "jsonb_build_object('role', v_role, 'text', v_text)"
    );
  });

  it("kalıcı yetki sırlarını handoff içinde reddeder", () => {
    expect(migration).toContain(
      '"(edit_token|session_token|ocode)"[[:space:]]*:'
    );
    expect(migration).toContain(
      "(edit_token|session_token|ocode)[[:space:]]*[:=]"
    );
    expect(migration).toContain(
      "raise exception 'ASSISTANT_HANDOFF_SECRET_FORBIDDEN'"
    );
  });

  it("eski ve yeni oluşturma RPC'lerini tek iç çekirdeğe bağlar", () => {
    expect(migration).toContain(
      "create or replace function public._create_owner_session_core("
    );
    expect(migration).toMatch(
      /create or replace function public\.create_owner_session\([\s\S]*?select public\._create_owner_session_core\([\s\S]*?null::jsonb/
    );
    expect(migration).toMatch(
      /create or replace function public\.create_owner_session_with_handoff\([\s\S]*?select public\._create_owner_session_core\([\s\S]*?p_assistant_handoff/
    );
    expect(migration).toContain(
      "revoke execute on function public._create_owner_session_core(text, text, jsonb)\n  from public, anon, authenticated"
    );
    expect(migration).toContain(
      "grant execute on function public.create_owner_session(text, text)\n  to anon, authenticated"
    );
  });

  it("handoff'u yalnız tüketilmiş, süresi geçerli session_token hattında döndürür", () => {
    expect(migration).toContain(
      "s.session_token_hash = v_token_hash"
    );
    expect(migration).toContain("s.consumed_at is not null");
    expect(migration).toContain("s.expires_at > now()");
    expect(migration).toContain(
      "'assistant_handoff', v_assistant_handoff"
    );
    expect(migration).not.toMatch(
      /grant\s+(?:select|all)[\s\S]*owner_sessions[\s\S]*to\s+(?:anon|authenticated)/i
    );
  });
});
