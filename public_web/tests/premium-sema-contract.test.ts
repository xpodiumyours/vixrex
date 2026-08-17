import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * Premium şeması (PR #1) — "Kiralık Vitrin = Premium" modeli.
 *
 * Asıl riskler burada:
 *   1) premium_expires_at istemci/çalışma taslağı tarafından
 *      yazılabilirse esnaf kendi süresini uzatabilir — geri dönüşü
 *      gelir kaybıdır.
 *   2) premium_orders doğrudan anon/authenticated'e açılırsa saldırgan
 *      kendi siparişini "paid" işaretleyebilir.
 *   3) stores.premium_expires_at anon'a SELECT açılırsa müşteri vitrini
 *      işletmenin ödeme durumunu görebilir (istenmiyor).
 *
 * Bu yüzden testler en çok "kim YAZAMAZ / kim GÖREMEZ" tarafına odaklanır.
 */

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const migrationSource = readFileSync(
  resolve(migrationsDir, "20260817000000_premium_sema.sql"),
  "utf-8"
);
const forbiddenKeysSource = readFileSync(
  resolve(migrationsDir, "20260805100000_add_working_draft_field_update.sql"),
  "utf-8"
);

describe("stores.premium_expires_at — süre kolonu", () => {
  it("stores tablosuna timestamptz olarak eklenir", () => {
    expect(migrationSource).toContain(
      "add column if not exists premium_expires_at timestamptz"
    );
  });

  it("anon/authenticated'e SELECT grant'ı VERİLMEZ — müşteri vitrini premium durumunu göremez", () => {
    expect(migrationSource).not.toMatch(
      /grant select(\([^)]*premium_expires_at[^)]*\))? on table public\.stores to (anon|authenticated)/i
    );
    expect(migrationSource).not.toMatch(
      /grant select\([^)]*premium_expires_at/i
    );
  });

  it("GÜVENLİK: koruma tetikleyicisi var — istemci kendi süresini uzatamaz", () => {
    // 2026-08-17 inceleme bulgusu: tablo düzeyinde anon/authenticated'e
    // UPDATE izni var ve 'Owners can update their stores' RLS politikası
    // kolon ayırt etmiyor — authenticated kullanıcı kendi vitrininde
    // premium_expires_at'i doğrudan yazabiliyordu (canlı testte UPDATE 1).
    // Kolon-bazlı revoke PostgreSQL'de tablo grant'ını EZMEDİĞİ için
    // koruma tetikleyiciyle sağlanır (service_role dışına kapalı).
    expect(migrationSource).toContain(
      "create or replace function public.protect_premium_expires_at()"
    );
    expect(migrationSource).toContain(
      "create trigger protect_premium_expires_at"
    );
    expect(migrationSource).toContain("PREMIUM_EXPIRES_AT_RESTRICTED");
    // Rol kontrolü current_user'dan DEĞİL 'role' GUC'undan okunur —
    // security definer içinde current_user her zaman postgres döner.
    expect(migrationSource).toContain("current_setting('role', true)");
    expect(migrationSource).toContain("not in ('service_role', 'postgres', 'none')");
  });

  it("GÜVENLİK: istemci süreye yazamaz — owner_forbidden_draft_keys zaten kapsıyor", () => {
    // Esnaf çalışma taslağı üzerinden premium alanlarına yazamaz
    // (20260805100000). Bu koruma bu migration'da KOPYALANMAZ, var olana
    // güvenilir — iki ayrı doğruluk kaynağı yaratmak istemiyoruz.
    const forbiddenFnBlock = forbiddenKeysSource.slice(
      forbiddenKeysSource.indexOf(
        "create or replace function public.owner_forbidden_draft_keys"
      ),
      forbiddenKeysSource.indexOf("comment on function public.owner_forbidden_draft_keys")
    );
    expect(forbiddenFnBlock).toContain("'premium_expires_at'");
    expect(forbiddenFnBlock).toContain("'is_premium'");
    expect(forbiddenFnBlock).toContain("'premium_plan'");
  });
});

describe("premium_orders — ödeme sipariş kaydı", () => {
  it("tablo oluşturulur ve merchant_oid benzersizdir (tek kullanımlık)", () => {
    expect(migrationSource).toContain("create table if not exists public.premium_orders");
    expect(migrationSource).toContain("merchant_oid text not null unique");
  });

  it("RLS açıktır", () => {
    expect(migrationSource).toContain(
      "alter table public.premium_orders enable row level security"
    );
  });

  it("GÜVENLİK: anon/authenticated/public'e AÇIKÇA revoke edilir", () => {
    expect(migrationSource).toContain(
      "revoke all on table public.premium_orders from public, anon, authenticated;"
    );
  });

  it("service_role'e tam yetki verilir — ödeme yalnız sunucu katmanından", () => {
    expect(migrationSource).toContain(
      "grant all on table public.premium_orders to service_role;"
    );
  });

  it("status yalnız pending/paid/failed olabilir", () => {
    expect(migrationSource).toContain(
      "check (status in ('pending', 'paid', 'failed'))"
    );
  });

  it("GÜVENLİK: premium_orders'a anon/authenticated GRANT'ı hiçbir yerde yok", () => {
    expect(migrationSource).not.toMatch(
      /grant (all|select|insert|update|delete)[\s\S]*on table public\.premium_orders[\s\S]*to (anon|authenticated)/
    );
  });
});
