import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  VIXREX_SMART_ENGINE_BLOG_FLAG,
  VIXREX_SMART_ENGINE_FLAG,
  VIXREX_SMART_ENGINE_STOREFRONT_FLAG,
  smartEngineBlogEnabledFromRows,
  smartEngineStorefrontEnabledFromRows,
} from "../src/lib/smartEngineFlags";

function rows(entries: Record<string, boolean>) {
  return Object.entries(entries).map(([flag_key, is_enabled]) => ({ flag_key, is_enabled }));
}

describe("Blog assistant capability contract", () => {
  it("Blog is fail-closed unless global + blog flags are both ON", () => {
    expect(smartEngineBlogEnabledFromRows(null)).toBe(false);
    expect(smartEngineBlogEnabledFromRows(rows({ [VIXREX_SMART_ENGINE_FLAG]: true }))).toBe(false);
    expect(
      smartEngineBlogEnabledFromRows(
        rows({
          [VIXREX_SMART_ENGINE_FLAG]: true,
          [VIXREX_SMART_ENGINE_BLOG_FLAG]: false,
        }),
      ),
    ).toBe(false);
    expect(
      smartEngineBlogEnabledFromRows(
        rows({
          [VIXREX_SMART_ENGINE_FLAG]: true,
          [VIXREX_SMART_ENGINE_BLOG_FLAG]: true,
        }),
      ),
    ).toBe(true);
  });

  it("Blog flag does not replace storefront capability", () => {
    const enabled = rows({
      [VIXREX_SMART_ENGINE_FLAG]: true,
      [VIXREX_SMART_ENGINE_STOREFRONT_FLAG]: true,
      [VIXREX_SMART_ENGINE_BLOG_FLAG]: false,
    });
    expect(smartEngineStorefrontEnabledFromRows(enabled)).toBe(true);
    expect(smartEngineBlogEnabledFromRows(enabled)).toBe(false);
  });

  it("assistant import is server-gated and draft-only", () => {
    const source = readFileSync(
      resolve(process.cwd(), "src/app/api/owner-blog-assistant/import/route.ts"),
      "utf8",
    );
    expect(source).toContain("smartEngineBlogServerEnabled");
    expect(source).toContain("import_vixrex_blog_article_to_store");
    expect(source).toContain('durum: "draft"');
    expect(source).not.toContain("publish_working_draft");
  });

  it("assistant library search is server-gated and published-only", () => {
    const source = readFileSync(
      resolve(process.cwd(), "src/app/api/owner-blog-assistant/search/route.ts"),
      "utf8",
    );
    expect(source).toContain("smartEngineBlogServerEnabled");
    expect(source).toContain('.eq("status", "published")');
  });

  it("Blog runtime flag migration starts OFF", () => {
    const migration = readFileSync(
      resolve(process.cwd(), "../supabase/migrations/20260906134000_add_smart_engine_blog_flag.sql"),
      "utf8",
    );
    expect(migration).toContain("'vixrex_smart_engine_blog_enabled'");
    expect(migration).toMatch(/'vixrex_smart_engine_blog_enabled',\s*false/);
  });
});
