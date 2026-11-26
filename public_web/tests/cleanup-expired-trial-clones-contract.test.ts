import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * "Bu vitrini kirala" denemelerinin otomatik temizliği. Casper
 * (2026-08-14): "Kirala butonuna her tıklamada kalıcı kayıt oluşuyor,
 * hiç silinmiyor... 30 gün çok, 30 saat yeter." → (2026-08-17) güncel
 * eşik 14 güne çıkarıldı; bu test güncel davranışı kilitler.
 *
 * Asıl risk burada: temizlik yanlışlıkla GERÇEK (yayınlanmış) bir vitrini
 * silerse geri dönüşü olmaz. Bu yüzden testler en çok "hangi satırlara
 * DOKUNULMAZ" tarafına odaklanıyor.
 */

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
// Güncel temizlik implementasyonu (2026-08-17): cleanup_expired_trial_clones
// artık 14 gün eşiğine sahiptir — önce 30 saat, sonra (PR #2) 14 güne çıkarıldı.
const migrationSource = readFileSync(
  resolve(migrationsDir, "20260817010000_premium_deneme_suresi.sql"),
  "utf-8"
);
// pg_cron eklentisi ilk tanımlandığı eski temizlik migration'ıdır.
const cronSource = readFileSync(
  resolve(migrationsDir, "20260814230000_cleanup_expired_trial_clones.sql"),
  "utf-8"
);
const secureFlowSource = readFileSync(
  resolve(migrationsDir, "20260815180000_secure_rent_demo_flow.sql"),
  "utf-8"
);

const cleanupFnBlock = migrationSource.slice(
  migrationSource.indexOf(
    "create or replace function public.cleanup_expired_trial_clones"
  ),
  migrationSource.indexOf("comment on function public.cleanup_expired_trial_clones")
);

describe("cleanup_expired_trial_clones — yalnız işaretli deneme satırlarını siler", () => {
  it("cloned_from_slug dolu olmayan (organik) satırlara dokunmaz", () => {
    expect(cleanupFnBlock).toContain("cloned_from_slug is not null");
  });

  it("yayınlanmış (is_published=true) satırlara dokunmaz — dönüşüm her zaman güvende", () => {
    expect(cleanupFnBlock).toContain("is_published = false");
  });

  it("eşik 14 gün (30 saat DEĞİL)", () => {
    expect(cleanupFnBlock).toContain("interval '14 days'");
    expect(cleanupFnBlock).not.toMatch(/interval '30 hours'/);
  });

  it("anon/authenticated'e çalıştırma yetkisi hiçbir yerde verilmez", () => {
    expect(migrationSource).not.toMatch(
      /grant execute on function public\.cleanup_expired_trial_clones[\s\S]*?to anon/
    );
  });

  // GÜVENLİK (2026-08-15): bu dosyanın kendisi hiç `revoke` içermiyordu —
  // yorum "yetki verilmez" diyordu ama PostgreSQL yeni fonksiyonlara
  // varsayılan olarak PUBLIC execute yetkisi verir. "Grant satırı yok"
  // "kapalı" anlamına GELMEZ — açık revoke şart. Yukarıdaki test bunu
  // yakalamıyordu, aşağıdaki yakalıyor.
  it("GÜVENLİK: secure_rent_demo_flow migration'ı PUBLIC/anon/authenticated'ten AÇIKÇA revoke eder", () => {
    expect(secureFlowSource).toContain(
      "revoke execute on function public.cleanup_expired_trial_clones()\n  from public, anon, authenticated;"
    );
  });
});

describe("cloned_from_slug — kaynak demo işaretlemesi", () => {
  it("stores tablosuna eklenir", () => {
    expect(cronSource).toContain(
      "add column if not exists cloned_from_slug"
    );
  });

  it("clone_demo_store_as_draft artık bu alanı dolduruyor", () => {
    const cloneFnBlock = cronSource.slice(
      cronSource.indexOf(
        "create or replace function public.clone_demo_store_as_draft"
      ),
      cronSource.indexOf(
        "create or replace function public.cleanup_expired_trial_clones"
      )
    );
    expect(cloneFnBlock).toContain("cloned_from_slug");
    expect(cloneFnBlock).toContain("pg_catalog.btrim(p_source_slug)");
  });
});

describe("pg_cron zamanlaması", () => {
  it("saatte bir çalışacak şekilde kurulu", () => {
    expect(migrationSource).toContain("cron.schedule(");
    expect(migrationSource).toContain("'0 * * * *'");
  });

  it("pg_cron eklentisi etkinleştiriliyor", () => {
    expect(cronSource).toContain("create extension if not exists pg_cron");
  });
});
