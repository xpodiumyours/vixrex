import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const migration = readFileSync(
  resolve(__dirname, "../../supabase/migrations/20260817040000_store_premium_durumu.sql"),
  "utf-8"
);

const fn = migration.slice(
  migration.indexOf("create or replace function public.get_store_premium_status"),
  migration.indexOf("comment on function public.get_store_premium_status")
);

/**
 * get_store_premium_status — Flutter'ın kendi vitrininin premium durumunu
 * okuma RPC'si (spec PR #6).
 *
 * Güvenlik sözleşmesi:
 * - Premium bilgisi istemciye ham SELECT ile açılmaz (PR #1 kararı);
 *   bu RPC tek yetkili okuma yoludur ve edit_token kanıtı ister
 *   (create_owner_session ile aynı desen).
 * - Yetkisiz istekte bilgi ASLA dönmez: OWNER_AUTHORIZATION_REQUIRED
 *   (fail-closed) — vitrinin var olup olmadığını bile sızdırmaz.
 * - Yalnız OKUR: premium yazma yolu yok (purchasePremium kaldırıldı).
 * - anon/authenticated'e açık ama BİLEREK (edit_token possession proof),
 *   public'e kapalı.
 */
describe("get_store_premium_status — vitrin bazlı premium okuma", () => {
  it("security definer + sabit search_path", () => {
    expect(fn).toContain("security definer");
    expect(fn).toContain("set search_path = pg_catalog, public, extensions");
  });

  it("edit_token kanıtı ister (create_owner_session deseni)", () => {
    expect(fn).toContain("edit_token = v_token");
    expect(fn).toContain("OWNER_AUTHORIZATION_REQUIRED");
  });

  it("fail-closed: yetki yoksa bilgi dönmeden hata fırlatır", () => {
    // Yetki kontrolü return'den ÖNCE olmalı.
    const authIndex = fn.indexOf("OWNER_AUTHORIZATION_REQUIRED");
    const returnIndex = fn.indexOf("return jsonb_build_object");
    expect(authIndex).toBeGreaterThan(-1);
    expect(returnIndex).toBeGreaterThan(authIndex);
  });

  it("is_premium yalnız süre dolmamışsa true (expires > now)", () => {
    expect(fn).toContain("v_premium_expires_at is not null and v_premium_expires_at > now()");
  });

  it("anon/authenticated'e açık (edit_token kanıtlı), public'e kapalı", () => {
    expect(migration).toContain(
      "revoke execute on function public.get_store_premium_status(text, text)\n  from public;"
    );
    expect(migration).toContain(
      "grant execute on function public.get_store_premium_status(text, text)\n  to anon, authenticated;"
    );
  });

  it("yalnız okur — premium yazma yolu içermez", () => {
    expect(fn).not.toContain("insert into");
    expect(fn).not.toContain("update public.stores");
    expect(fn).not.toContain("update public.premium_orders");
  });
});
