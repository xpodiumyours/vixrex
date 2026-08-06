import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * implementation_plan.md Commit 3: kısa süreli sahip oturumu sözleşmesi.
 * Migration'ın yalnızca hash'lenmiş kod sakladığını, oturum oluşturmanın
 * doğrulanmış sahip VEYA geçerli edit yetkisi gerektirdiğini, demo/kiralık
 * şablonun reddedildiğini ve kodun atomik tek kullanımlık tüketildiğini
 * kilitler. Public RLS politikalarına dokunulmaz.
 */

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const migrationSource = readFileSync(
  resolve(migrationsDir, "20260804001000_20260803180000_add_owner_sessions.sql"),
  "utf-8"
);

describe("sahip oturumu — yalnız hash'lenmiş kod saklanır", () => {
  const createTableBlock = migrationSource.slice(
    migrationSource.indexOf("create table public.owner_sessions"),
    migrationSource.indexOf("create index if not exists")
  );

  it("owner_sessions tablosu code_hash sütunu içerir ve düz kod sütunu içermez", () => {
    expect(migrationSource).toMatch(/create table public\.owner_sessions/);
    expect(createTableBlock).toMatch(/code_hash text not null/i);
    expect(createTableBlock).not.toMatch(/^\s*code text/i);
  });

  it("kod yalnızca sha256 ile hash'lenerek saklanır, açık kodla eşleşme sha256 üzerinden yapılır", () => {
    expect(migrationSource).toContain("encode(gen_random_bytes(16), 'hex')");
    expect(migrationSource).toContain("encode(sha256(v_code::bytea), 'hex')");
    expect(migrationSource).toContain("encode(sha256(p_code::bytea), 'hex')");
  });

  it("owner_sessions doğrudan erişime kapalıdır (RLS açık, politika yok)", () => {
    expect(migrationSource).toContain(
      "alter table public.owner_sessions enable row level security"
    );
    expect(migrationSource).not.toMatch(/create policy/i);
  });
});

describe("sahip oturumu — yalnız doğrulanmış sahip veya geçerli edit yetkisi", () => {
  it("create_owner_session auth.uid() = user_id VEYA edit_token eşleşmesi arar", () => {
    expect(migrationSource).toContain("user_id = v_user_id");
    expect(migrationSource).toContain("edit_token = v_token");
    expect(migrationSource).toContain("OWNER_AUTHORIZATION_REQUIRED");
  });

  it("demo/kiralık şablon için oturum oluşturmayı reddeder", () => {
    expect(migrationSource).toContain("if v_is_demo then");
    expect(migrationSource).toContain("DEMO_STORE_IMMUTABLE");
  });

  it("bulunamayan vitrin için oturum oluşturmaz", () => {
    expect(migrationSource).toContain("STORE_NOT_FOUND");
  });
});

describe("sahip oturumu — kod atomik tek kullanımlık tüketilir", () => {
  it("consume_owner_session yalnız tüketilmemiş ve süresi dolmamış kodu kabul eder", () => {
    expect(migrationSource).toContain("s.consumed_at is null");
    expect(migrationSource).toContain("s.expires_at > now()");
    expect(migrationSource).toContain("set consumed_at = now()");
  });

  it("konsum yalnız ilgili vitrin slug'ı ile eşleşen oturumda geçerlidir", () => {
    expect(migrationSource).toContain("st.id = s.store_id and st.slug = v_slug");
  });

  it("ikinci kullanım veya hatalı kod aynı hata ile reddedilir", () => {
    expect(migrationSource).toContain("INVALID_OR_EXPIRED_OWNER_CODE");
  });
});

describe("sahip oturumu — public RLS politikaları değiştirilmez", () => {
  it("migration mevcut public politikalarına dokunmaz", () => {
    expect(migrationSource).not.toMatch(/drop policy/i);
    expect(migrationSource).not.toMatch(/revoke select on table public\.stores/i);
  });
});
