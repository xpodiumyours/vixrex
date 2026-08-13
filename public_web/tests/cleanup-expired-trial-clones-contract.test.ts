import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * "Bu vitrini kirala" denemelerinin otomatik temizliği. Casper
 * (2026-08-14): "Kirala butonuna her tıklamada kalıcı kayıt oluşuyor,
 * hiç silinmiyor... 30 gün çok, 30 saat yeter."
 *
 * Asıl risk burada: temizlik yanlışlıkla GERÇEK (yayınlanmış) bir vitrini
 * silerse geri dönüşü olmaz. Bu yüzden testler en çok "hangi satırlara
 * DOKUNULMAZ" tarafına odaklanıyor.
 */

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const migrationSource = readFileSync(
  resolve(migrationsDir, "20260814230000_cleanup_expired_trial_clones.sql"),
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

  it("eşik 30 saat (30 gün DEĞİL)", () => {
    expect(cleanupFnBlock).toContain("interval '30 hours'");
    expect(cleanupFnBlock).not.toMatch(/interval '30 days'/);
  });

  it("anon/authenticated'e çalıştırma yetkisi verilmez — dışarıdan tetiklenemez", () => {
    expect(migrationSource).not.toMatch(
      /grant execute on function public\.cleanup_expired_trial_clones[\s\S]*?to anon/
    );
  });
});

describe("cloned_from_slug — kaynak demo işaretlemesi", () => {
  it("stores tablosuna eklenir", () => {
    expect(migrationSource).toContain(
      "add column if not exists cloned_from_slug"
    );
  });

  it("clone_demo_store_as_draft artık bu alanı dolduruyor", () => {
    const cloneFnBlock = migrationSource.slice(
      migrationSource.indexOf(
        "create or replace function public.clone_demo_store_as_draft"
      ),
      migrationSource.indexOf(
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
    expect(migrationSource).toContain("create extension if not exists pg_cron");
  });
});
