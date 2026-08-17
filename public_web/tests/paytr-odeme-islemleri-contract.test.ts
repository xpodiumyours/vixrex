import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const migration = readFileSync(
  resolve(__dirname, "../../supabase/migrations/20260817030000_paytr_odeme_islemleri.sql"),
  "utf-8"
);

const createFn = migration.slice(
  migration.indexOf("create or replace function public.create_premium_order"),
  migration.indexOf("comment on function public.create_premium_order")
);
const recordFn = migration.slice(
  migration.indexOf("create or replace function public.record_premium_payment"),
  migration.indexOf("comment on function public.record_premium_payment")
);

/**
 * PayTR ödeme akışı RPC'lerinin güvenlik sözleşmesi (spec PR #4).
 *
 * Temel ilkeler (VIXREX_RULES §9):
 * - Ödeme yalnız doğrulanmış callback üzerinden işlenir; istemci kendi
 *   kendine premium yazamaz → her iki fonksiyon da security definer +
 *   public/anon/authenticated'e açıkça kapalı, yalnız service_role.
 * - Fail-closed: callback'ten gelen tutar siparişte saklananla
 *   karşılaştırılır; uyuşmazsa işlem YAPILMAZ (AMOUNT_MISMATCH).
 * - İdempotent: aynı merchant_oid ikinci kez gelirse süre UZAMAZ.
 * - merchant_oid unique (20260817000000) + on conflict do nothing.
 */
describe("create_premium_order — bekleyen sipariş oluşturma", () => {
  it("security definer ve search_path güvenli", () => {
    expect(createFn).toContain("security definer");
    expect(createFn).toContain("set search_path = pg_catalog, public, extensions");
  });

  it("yalnız service_role çağırabilir", () => {
    expect(migration).toContain(
      "revoke execute on function public.create_premium_order(uuid, text, integer, text)\n  from public, anon, authenticated;"
    );
    expect(migration).toContain(
      "grant execute on function public.create_premium_order(uuid, text, integer, text)\n  to service_role;"
    );
  });

  it("merchant_oid benzersizdir — aynı sipariş iki kez açılamaz", () => {
    expect(createFn).toContain("on conflict (merchant_oid) do nothing");
  });

  it("mağaza başına oran sınırı uygular (sipariş patlaması)", () => {
    expect(createFn).toContain("consume_assistant_request");
    expect(createFn).toContain("'paytr:order:' || p_store_id::text");
  });
});

describe("record_premium_payment — ödemeyi premium'a işleme", () => {
  it("security definer + yalnız service_role", () => {
    expect(recordFn).toContain("security definer");
    expect(migration).toContain(
      "revoke execute on function public.record_premium_payment(text, integer, text)\n  from public, anon, authenticated;"
    );
    expect(migration).toContain(
      "grant execute on function public.record_premium_payment(text, integer, text)\n  to service_role;"
    );
  });

  it("fail-closed: tutar uyuşmazlığı işlenmez (AMOUNT_MISMATCH)", () => {
    expect(recordFn).toContain("AMOUNT_MISMATCH");
    expect(recordFn).toContain("p_amount_kurus <> v_order.amount_kurus");
  });

  it("bilinmeyen sipariş reddedilir (UNKNOWN_ORDER)", () => {
    expect(recordFn).toContain("UNKNOWN_ORDER");
  });

  it("idempotent: aynı merchant_oid tekrar gelirse süre uzamaz", () => {
    expect(recordFn).toContain("already_paid");
    expect(recordFn).toContain("v_order.status = 'paid'");
    // 'paid' dalında stores UPDATE'i olmamalı — süre uzamaz.
    const paidDali = recordFn.slice(
      recordFn.indexOf("if v_order.status = 'paid'"),
      recordFn.indexOf("if p_amount_kurus is null")
    );
    expect(paidDali).not.toContain("update public.stores");
  });

  it("30 gün ekler ve erken yenilemede kalan günü korur", () => {
    expect(recordFn).toContain("interval '30 days'");
    expect(recordFn).toContain("greatest(coalesce(premium_expires_at, now()), now())");
  });
});
