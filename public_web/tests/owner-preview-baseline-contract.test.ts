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

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
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
  it("PreviewEditorPanel yalnızca isPreviewMode true iken render edilir", () => {
    const renderBlock = pageSource.slice(pageSource.indexOf("return (\n    <>"));
    expect(renderBlock).toContain("{isPreviewMode && (\n        <PreviewEditorPanel");
  });

  it("isPreviewMode yalnızca boş olmayan preview_token'dan türer", () => {
    expect(pageSource).toContain(
      "const previewToken = searchParams.preview_token?.trim();"
    );
    expect(pageSource).toContain(
      "const isPreviewMode = Boolean(previewToken);"
    );
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
