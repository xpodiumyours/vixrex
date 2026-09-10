import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const fazF = readFileSync(
  resolve(migrationsDir, "20260902112954_faz_f_vitrin_engagement_events.sql"),
  "utf8"
);
const hardening = readFileSync(
  resolve(migrationsDir, "20260910200000_lock_vitrin_engagement_events_rls.sql"),
  "utf8"
);

describe("vitrin_engagement_events — Data API güvenlik kontratı", () => {
  it("tablo RLS ile kapatılır", () => {
    expect(hardening).toContain(
      "alter table public.vitrin_engagement_events enable row level security"
    );
  });

  it("PUBLIC, anon ve authenticated doğrudan tablo yetkisi taşımaz", () => {
    expect(hardening).toMatch(
      /revoke all on table public\.vitrin_engagement_events\s+from public, anon, authenticated;/
    );
  });

  it("istemci yazımı yalnız mevcut record_vitrin_engagement RPC yüzeyinden sürer", () => {
    expect(fazF).toContain(
      "grant execute on function public.record_vitrin_engagement(text, text, text, text) to anon, authenticated"
    );
    expect(fazF).toContain("and is_published = true");
    expect(fazF).toContain("pg_catalog.length(v_session_key) < 16");
  });

  it("sahip performans okuması owner session doğrulamasını korur", () => {
    expect(fazF).toContain(
      "grant execute on function public.get_haftalik_performans(text) to anon, authenticated"
    );
    expect(fazF).toContain("from public.owner_sessions s");
    expect(fazF).toContain("s.consumed_at is not null");
    expect(fazF).toContain("s.expires_at > now()");
  });
});
