import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const route = readFileSync(
  resolve(__dirname, "../src/app/api/owner-draft-batch/route.ts"),
  "utf8",
);
const migration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260909211500_add_atomic_working_draft_batch.sql",
  ),
  "utf8",
);

describe("Vixrex Assistant atomik çok-alan kayıt kapısı", () => {
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

  it("bir alan geçersizse batch RPC çağrısından önce 422 döner", () => {
    const validation = route.indexOf("validateField(anahtar, ham.deger)");
    const rpc = route.indexOf('rpc("update_working_draft_fields"');
    expect(validation).toBeGreaterThan(-1);
    expect(rpc).toBeGreaterThan(validation);
    expect(route).toContain("Bir alan bile geçersizse RPC HİÇ çağrılmaz");
  });

  it("tek kullanıcı işlemini tek batch RPC ve tek broadcast ile tamamlar", () => {
    expect(route.match(/update_working_draft_fields/g)?.length).toBe(1);
    expect(route.match(/broadcastTaslakGuncellendi\(slug, clientId\)/g)?.length).toBe(1);
    expect(route).not.toContain('fetch("/api/owner-draft"');
  });

  it("aynı anahtarı iki kez ve aşırı büyük batch'i reddeder", () => {
    expect(route).toContain("MAX_BATCH_FIELDS = 20");
    expect(route).toContain("gorulenAnahtarlar.has(anahtar)");
  });
});

describe("update_working_draft_fields SQL sözleşmesi", () => {
  it("mevcut owner-session ve forbidden-key güvenlik omurgasını tekrar kullanır", () => {
    expect(migration).toContain("public.owner_sessions");
    expect(migration).toContain("public.owner_forbidden_draft_keys()");
    expect(migration).toContain("INVALID_SESSION_TOKEN");
    expect(migration).toContain("DEMO_STORE_IMMUTABLE");
    expect(migration).toContain("FIELD_NOT_EDITABLE");
    expect(migration).toContain("UNKNOWN_FIELD");
  });

  it("bütün alanları yazmadan önce doğrular ve taslak satırını FOR UPDATE kilitler", () => {
    const validateLoop = migration.indexOf("Bütün anahtarları yazmadan önce doğrula");
    const rowLock = migration.indexOf("for update;");
    const write = migration.indexOf("update public.store_working_drafts");
    expect(validateLoop).toBeGreaterThan(-1);
    expect(rowLock).toBeGreaterThan(validateLoop);
    expect(write).toBeGreaterThan(rowLock);
  });

  it("taslak tabloya tek UPDATE yapar ve sürümü yalnız bir artırır", () => {
    expect(migration.match(/update public\.store_working_drafts/g)?.length).toBe(1);
    expect(migration).toContain("draft_version = draft_version + 1");
  });

  it("JSON null'u mevcut tek-alan RPC gibi anahtarı kaldırarak uygular", () => {
    expect(migration).toContain("v_new_data := v_new_data - v_key");
  });

  it("doğrudan public execute kapalı, yalnız anon/authenticated RPC çağrısı açık", () => {
    expect(migration).toContain(
      "revoke all on function public.update_working_draft_fields(text, jsonb) from public",
    );
    expect(migration).toContain(
      "grant execute on function public.update_working_draft_fields(text, jsonb) to anon, authenticated",
    );
  });
});
