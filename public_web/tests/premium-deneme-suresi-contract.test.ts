import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * Deneme süresi + premium bitişi (PR #2) — "Kiralık Vitrin = Premium".
 *
 * Asıl risk burada: temizlik yanlışlıkla PARA ÖDEMİŞ esnafın vitrinini
 * silerse veri kaybı olur ve geri dönüşü yoktur. Testler bu yüzden en çok
 * "hangi satırlara DOKUNULMAZ" tarafına odaklanır:
 *   1) Temizlik yalnız HİÇ PREMIUM ALMAMIŞ denemeleri siler.
 *   2) Premium biten vitrin SİLİNMEZ, yayından düşer (is_published=false).
 *   3) Her iki fonksiyon da dışarıdan (anon/authenticated) çağrılamaz.
 */

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const migrationSource = readFileSync(
  resolve(migrationsDir, "20260817010000_premium_deneme_suresi.sql"),
  "utf-8"
);

const cleanupFnBlock = migrationSource.slice(
  migrationSource.indexOf(
    "create or replace function public.cleanup_expired_trial_clones"
  ),
  migrationSource.indexOf("comment on function public.cleanup_expired_trial_clones")
);

describe("cleanup_expired_trial_clones — 14 gün deneme, premium geçmişini asla silme", () => {
  it("eşik 14 gün (30 saat DEĞİL)", () => {
    expect(cleanupFnBlock).toContain("interval '14 days'");
    expect(cleanupFnBlock).not.toMatch(/interval '30 hours'/);
  });

  it("yalnız cloned_from_slug dolu (organik) satırlara dokunmaz", () => {
    expect(cleanupFnBlock).toContain("cloned_from_slug is not null");
  });

  it("yayınlanmış (is_published=true) satırlara dokunmaz", () => {
    expect(cleanupFnBlock).toContain("is_published = false");
  });

  it("GÜVENLİK: premium_expires_at dolu (ödeme geçmişi) satır ASLA silinmez", () => {
    expect(cleanupFnBlock).toContain("premium_expires_at is null");
  });

  it("GÜVENLİK: anon/authenticated'e çalıştırma yetkisi açıkça revoke edilir", () => {
    expect(migrationSource).toContain(
      "revoke execute on function public.cleanup_expired_trial_clones()\n  from public, anon, authenticated;"
    );
  });
});

describe("demote_expired_premium_stores — premium bitince taslağa döner", () => {
  const demoteFnBlock = migrationSource.slice(
    migrationSource.indexOf(
      "create or replace function public.demote_expired_premium_stores"
    ),
    migrationSource.indexOf("comment on function public.demote_expired_premium_stores")
  );

  it("yalnız yayındaki kiralık vitrinleri etkiler", () => {
    expect(demoteFnBlock).toContain("cloned_from_slug is not null");
    expect(demoteFnBlock).toContain("is_published = true");
  });

  it("premium süresi dolalı 3 GÜN olmuş olanları taslağa döndürür (is_published=false)", () => {
    expect(demoteFnBlock).toContain("premium_expires_at is not null");
    expect(demoteFnBlock).toContain("premium_expires_at < pg_catalog.now() - interval '3 days'");
    expect(demoteFnBlock).toContain("is_published = false");
  });

  it("GÜVENLİK: SİLMEZ — yalnız UPDATE (veri korunur)", () => {
    // Para ödemiş esnafın vitrini yayından düşer ama satır ve içeriği
    // durur. Bu fonksiyonda DELETE olmamalı.
    expect(demoteFnBlock).toContain("update public.stores");
    expect(demoteFnBlock).not.toMatch(/delete from public\.stores/i);
  });

  it("GÜVENLİK: anon/authenticated'e yetki verilmez — açıkça revoke", () => {
    expect(migrationSource).toContain(
      "revoke execute on function public.demote_expired_premium_stores()\n  from public, anon, authenticated;"
    );
  });
});

describe("pg_cron zamanlaması", () => {
  it("iki iş de saatte bir kurulu", () => {
    expect(migrationSource).toContain("'cleanup-expired-trial-clones'");
    expect(migrationSource).toContain("'demote-expired-premium-stores'");
    expect(migrationSource).toContain("'0 * * * *'");
  });
});
