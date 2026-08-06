import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * implementation_plan.md Commit 1: bugünkü davranışı sözleşme testleriyle
 * kilitler. Production davranışı değişmez — yalnızca mevcut korumaları
 * görünür/kırılırsa-fark-edilir hale getirir.
 */

const pagePath = resolve(__dirname, "../src/app/v/[slug]/page.tsx");
const pageSource = readFileSync(pagePath, "utf-8");

const migrationsDir = resolve(__dirname, "../../supabase/migrations_arsiv");
const fixPreviewRpcSource = readFileSync(
  resolve(
    migrationsDir,
    "20260803190314_20260803150000_fix_draft_preview_rpc_and_demo_links.sql"
  ),
  "utf-8"
);
const demoProtectionSource = readFileSync(
  resolve(migrationsDir, "20260803190512_20260803160000_protect_landing_demos.sql"),
  "utf-8"
);

describe("sahip önizleme temeli — müşteri isteğinde sahip araçları görünmez", () => {
  it("OwnerWorkspaceShell yalnızca isOwnerMode true iken render edilir", () => {
    const renderBlock = pageSource.slice(pageSource.indexOf("return (\n    <>"));
    expect(renderBlock).toContain("{isOwnerMode ? (");
    expect(renderBlock).toContain("<OwnerWorkspaceShell");
  });

  // Commit 12'de değişti: eskiden sahip oturumu YOKKEN de açılan ikinci bir
  // düzenleme yolu vardı (preview_token + PreviewEditorPanel). O yol
  // kaldırıldı; artık sahip aracı yalnız doğrulanmış oturumla çıkar.
  // Aşağıdaki iki test o yolun geri gelmediğini bekçilik eder.
  it("sahip oturumu dışında ikinci bir düzenleme yolu yoktur", () => {
    const renderBlock = pageSource.slice(pageSource.indexOf("return (\n    <>"));

    // isOwnerMode dışında dallanma yok: ya sahip kabuğu, ya hiçbir şey.
    expect(renderBlock).toContain("{isOwnerMode ? (");
    expect(renderBlock).toContain(") : null}");
    expect(renderBlock).not.toContain("<PreviewEditorPanel");
    expect(renderBlock).not.toContain("isPreviewMode ? (");
  });

  it("preview_token sorgu parametresi artık hiç okunmaz", () => {
    expect(pageSource).not.toContain("preview_token");
    expect(pageSource).not.toContain("previewToken");
  });

  it("isOwnerMode owner cookie doğrulamasıyla belirlenir ve fail-closed uygulanır", () => {
    // Çerezin adı, içindeki tokenden AYRI olmalı. Aynı ada sahip olduğunda
    // (2026-08-05) RPC'ye imzalı paketin tamamı gitti ve sahip modu hiç
    // açılmadı. Bkz. owner-workspace-shell-behavior.test.ts.
    expect(pageSource).toContain(
      "const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value"
    );
    expect(pageSource).toContain("verifyOwnerSession(ownerSessionCookie, params.slug)");
    expect(pageSource).toContain("let isOwnerMode = Boolean(ownerSession)");
    // Fail-closed: draft yoksa isOwnerMode false
    expect(pageSource).toContain("if (!draft) {");
    expect(pageSource).toContain("isOwnerMode = false");
  });
});

describe("sahip önizleme temeli — taslak önizleme doğru token olmadan açılmaz", () => {
  it("get_store_preview eksik/kısa edit_token'ı reddeder", () => {
    expect(fixPreviewRpcSource).toContain(
      "IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN"
    );
    expect(fixPreviewRpcSource).toContain("RAISE EXCEPTION 'INVALID_EDIT_TOKEN'");
  });

  it("get_store_preview eşleşmeyen token için satır döndürmez", () => {
    expect(fixPreviewRpcSource).toContain("s.edit_token = pg_catalog.btrim(p_edit_token)");
    expect(fixPreviewRpcSource).toContain("RAISE EXCEPTION 'EDIT_TOKEN_MISMATCH'");
  });
});

describe("sahip önizleme temeli — demo/kiralık şablon değiştirilemez", () => {
  it("prevent_demo_store_mutation is_demo=true satırında UPDATE/DELETE'i engeller", () => {
    expect(demoProtectionSource).toContain(
      "CREATE OR REPLACE FUNCTION public.prevent_demo_store_mutation()"
    );
    expect(demoProtectionSource).toContain("IF OLD.is_demo THEN");
    expect(demoProtectionSource).toContain("RAISE EXCEPTION 'DEMO_STORE_IMMUTABLE'");
  });

  it("tetikleyici stores tablosuna BEFORE UPDATE OR DELETE olarak bağlanır", () => {
    expect(demoProtectionSource).toContain(
      "CREATE TRIGGER protect_landing_demo_stores"
    );
    expect(demoProtectionSource).toContain(
      "BEFORE UPDATE OR DELETE ON public.stores"
    );
  });
});
