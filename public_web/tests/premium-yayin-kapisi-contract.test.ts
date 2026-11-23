import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";
import { YAYIN_KAPISI_UYARISI } from "@/lib/fiyatlandirma";

/**
 * Premium yayın kapısı (PR #3) — "Kiralık Vitrin = Premium".
 *
 * Asıl risk: kiralık (cloned_from_slug dolu) bir vitrin premium'suz
 * yayınlanabilirse iş modeli çöker — bu kapı VERİTABANINDA olmalı,
 * UI'da değil (UI atlansa bile istemci premium'suz yayınlayamaz).
 *
 * Ayrıca organik vitrinler (cloned_from_slug null) HİÇ etkilenmemeli:
 * sıfırdan kendi vitrinini kuran esnaf ücretsiz yayınlamaya devam eder.
 */

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const migrationSource = readFileSync(
  resolve(migrationsDir, "20260817020000_premium_yayin_kapisi.sql"),
  "utf-8"
);

const fnBlock = migrationSource.slice(
  migrationSource.indexOf(
    "create or replace function public.publish_working_draft"
  ),
  migrationSource.indexOf("comment on function public.publish_working_draft")
);

describe("publish_working_draft — premium kapısı veritabanında", () => {
  it("GÜVENLİK: kiralık vitrin + aktif premium yoksa PREMIUM_REQUIRED fırlatır", () => {
    expect(fnBlock).toContain("v_cloned_from_slug is not null");
    expect(fnBlock).toContain("v_premium_expires_at <= now()");
    expect(fnBlock).toContain("raise exception 'PREMIUM_REQUIRED'");
  });

  it("organik vitrinler etkilenmez — kontrol yalnız cloned_from_slug dolu satırlara", () => {
    expect(fnBlock).toContain("if v_cloned_from_slug is not null");
    // Koşul cloned_from_slug'a bağlı — null organik vitrinlerde atlanır.
    expect(fnBlock).not.toMatch(/raise exception 'PREMIUM_REQUIRED';[\s\S]{0,200}if v_cloned_from_slug is null/);
  });

  it("oturum/taslak/çakışma/yasal kontrol mantığı KORUNUR (birebir)", () => {
    expect(fnBlock).toContain("raise exception 'INVALID_SESSION_TOKEN'");
    expect(fnBlock).toContain("raise exception 'DEMO_STORE_IMMUTABLE'");
    expect(fnBlock).toContain("raise exception 'WORKING_DRAFT_NOT_FOUND'");
    expect(fnBlock).toContain("raise exception 'DRAFT_STALE'");
    expect(fnBlock).toContain("owner_forbidden_draft_keys()");
  });

  it("select artık cloned_from_slug ve premium_expires_at'i çeker", () => {
    expect(fnBlock).toContain("st.cloned_from_slug");
    expect(fnBlock).toContain("st.premium_expires_at");
  });

  it("premium kontrolü oturum doğrulamasından SONRA gelir (yetkisiz erişim önce reddedilir)", () => {
    const oturumKonumu = fnBlock.indexOf("raise exception 'INVALID_SESSION_TOKEN'");
    const premiumKonumu = fnBlock.indexOf("raise exception 'PREMIUM_REQUIRED'");
    expect(oturumKonumu).toBeGreaterThan(-1);
    expect(premiumKonumu).toBeGreaterThan(oturumKonumu);
  });
});

describe("api/owner-publish — kullanıcıya anlamlı hata", () => {
  const routeSource = readFileSync(
    resolve(__dirname, "../src/app/api/owner-publish/route.ts"),
    "utf-8"
  );

  it("PREMIUM_REQUIRED için Türkçe mesaj ve 402 durum kodu tanımlı", () => {
    expect(routeSource).toContain("PREMIUM_REQUIRED:");
    expect(YAYIN_KAPISI_UYARISI).toContain("299 TL");
    expect(routeSource).toContain("YAYIN_KAPISI_UYARISI");
    expect(routeSource).toContain("PREMIUM_REQUIRED: 402");
  });
});
