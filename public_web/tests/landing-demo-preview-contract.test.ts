import { describe, expect, it } from "vitest";
import { existsSync, readFileSync } from "fs";
import { resolve } from "path";

// implementation_plan.md Commit 12.
//
// ESKİ SÖZLEŞME (2026-08-05'e kadar): karşılama ekranındaki demo vitrinler
// yayınlanmamış taslaktı ve gizli `preview_token` bağlantısıyla açılıyordu;
// Next.js tarafında onlara özel bir düzenleme paneli vardı.
//
// YENİ SÖZLEŞME: demolar yayında ve `is_demo` işaretli. Karşılama ekranı düz
// `/v/:slug` adresine bağlanır. Gizli bağlantı da, ayrı panel de kalktı.
//
// Bu dosya artık eski yolun GERİ GELMEDİĞİNİ bekçilik ediyor.

const pagePath = resolve(__dirname, "../src/app/v/[slug]/page.tsx");
const landingPath = resolve(__dirname, "../../lib/screens/landing_screen.dart");
const configPath = resolve(__dirname, "../../lib/config/public_site_config.dart");
const korumaMigration = resolve(
  __dirname,
  "../../supabase/migrations/20260803190512_20260803160000_protect_landing_demos.sql"
);
const yayinMigration = resolve(
  __dirname,
  "../../supabase/migrations/20260805210000_publish_landing_demo_stores.sql"
);

const DEMO_SLUGS = [
  "demo-aymira-giyim",
  "demo-lezzet-duragi",
  "demo-nova-kuafor",
  "demo-teknofix",
];

describe("landing demo vitrin sözleşmesi", () => {
  it("dört demo karşılama ekranından hâlâ erişilebilir", () => {
    const landingSource = readFileSync(landingPath, "utf-8");
    for (const slug of DEMO_SLUGS) {
      expect(landingSource, `${slug} karşılama ekranından düşmüş`).toContain(slug);
    }
  });

  it("karşılama ekranı düz yayın adresine bağlanır, gizli bağlantı üretmez", () => {
    const landingSource = readFileSync(landingPath, "utf-8");

    expect(landingSource).toContain("PublicSiteConfig.buildVitrinLink");
    expect(landingSource).not.toContain("buildVitrinPreviewLink");
    expect(landingSource).not.toContain("preview_token");
  });

  it("düzenleme anahtarları istemci kaynağında bulunmaz", () => {
    // Bunlar eskiden burada AÇIKTA duruyordu (landing-demo-aymira-giyim-2026
    // gibi) ve tarayıcıya inen koda gömülüyordu.
    const landingSource = readFileSync(landingPath, "utf-8");

    expect(landingSource).not.toContain("editToken");
    expect(landingSource).not.toMatch(/landing-demo-[a-z-]+-\d{4}/);
  });

  it("eski preview_token yolu Next.js'te kaldırılmıştır", () => {
    const pageSource = readFileSync(pagePath, "utf-8");

    expect(pageSource).not.toContain("preview_token");
    expect(pageSource).not.toContain("PreviewEditorPanel");
    expect(
      existsSync(resolve(__dirname, "../src/app/v/[slug]/PreviewEditorPanel.tsx")),
      "PreviewEditorPanel.tsx geri gelmiş"
    ).toBe(false);
  });

  it("Flutter tarafındaki eski bağlantı üreteci de kaldırılmıştır", () => {
    const configSource = readFileSync(configPath, "utf-8");
    expect(configSource).not.toContain("buildVitrinPreviewLink");
    expect(configSource).toContain("buildOwnerSessionEntryLink");
  });

  it("demolar veritabanında değiştirilemez kalır", () => {
    // Bu koruma yayına alınmakla ortadan kalkmaz: demo vitrin herkese
    // açıktır ama kimse düzenleyemez.
    expect(existsSync(korumaMigration)).toBe(true);
    const migration = readFileSync(korumaMigration, "utf-8");

    expect(migration).toContain("DEMO_STORE_IMMUTABLE");
    expect(migration).toContain("BEFORE UPDATE OR DELETE");
    for (const slug of DEMO_SLUGS) {
      expect(migration).toContain(slug);
    }
  });

  it("demolar yayına alınırken yasal onaylar kaydedilir", () => {
    expect(existsSync(yayinMigration)).toBe(true);
    const migration = readFileSync(yayinMigration, "utf-8");

    expect(migration).toContain("is_published = true");
    expect(migration).toContain("is_demo = true");
    // Onaysız yayın tetikleyici tarafından reddedilirdi; üç onay da yazılmalı.
    expect(migration).toContain("privacy_notice_acknowledged");
    expect(migration).toContain("terms_accepted");
    expect(migration).toContain("publication_consent_accepted");
    // Sürüm ve hash etkin belgeden okunur, elle yazılmaz.
    expect(migration).toContain("from public.legal_documents");
  });
});
