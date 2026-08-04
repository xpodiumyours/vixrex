import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

// implementation_plan.md Commit 6 (koruma sınırı 3): sahip çalışma taslağı
// müşteri yanıtına, SEO verisine, sitemap'e veya paylaşım bağlantısına sızmaz.

const CUSTOMER_PATHS = [
  resolve(__dirname, "../src/app/v/[slug]/page.tsx"),
  resolve(__dirname, "../src/app/v/[slug]/urun/[productSlug]/page.tsx"),
  resolve(__dirname, "../src/app/v/[slug]/yazilar/page.tsx"),
  resolve(__dirname, "../src/app/v/[slug]/yazilar/[articleSlug]/page.tsx"),
  resolve(__dirname, "../src/app/sitemap.xml/route.ts"),
  resolve(__dirname, "../src/app/robots.txt/route.ts"),
];

const MIGRATION_PATH = resolve(
  __dirname,
  "../../supabase/migrations/20260804160000_20260804150000_add_store_working_drafts.sql"
);
const migrationSource = readFileSync(MIGRATION_PATH, "utf-8");

const functionStart = migrationSource.indexOf(
  "create or replace function public.get_or_create_working_draft"
);
const functionSource = migrationSource.slice(
  functionStart,
  migrationSource.indexOf("$$;", functionStart) + 3
);

describe("çalışma taslağı yalıtımı — müşteri yolu taslağa dokunmaz", () => {
  it("müşteri vitrin, ürün, yazı, sitemap ve robots yolları çalışma taslağını hiç kullanmaz", () => {
    for (const filePath of CUSTOMER_PATHS) {
      const source = readFileSync(filePath, "utf-8");
      expect(source, filePath).not.toContain("store_working_drafts");
      expect(source, filePath).not.toContain("get_or_create_working_draft");
    }
  });
});

describe("çalışma taslağı yalıtımı — tablo istemciden okunamaz", () => {
  it("store_working_drafts üzerinde row level security açıktır", () => {
    expect(migrationSource).toMatch(
      /create table public\.store_working_drafts[\s\S]*?enable row level security/
    );
  });

  it("store_working_drafts üzerinde anon veya authenticated'e SELECT veren politika yoktur", () => {
    const policyStatements = migrationSource
      .split(/\bcreate policy\b/i)
      .slice(1);

    for (const statement of policyStatements) {
      expect(statement, statement).not.toMatch(/store_working_drafts/i);
    }
  });
});

describe("çalışma taslağı yalıtımı — erişim yalnız güvenli fonksiyondan", () => {
  it("get_or_create_working_draft security definer ile tanımlıdır", () => {
    expect(functionSource).toContain("security definer");
  });

  it("fonksiyonun search_path'i sabitlenmiştir", () => {
    expect(functionSource).toContain("set search_path = pg_catalog");
  });

  it("edit_token parametresi alır ve boş token tek başına yetki vermez", () => {
    expect(functionSource).toContain("p_edit_token text");
    expect(functionSource).toContain("v_token <> ''");
    expect(functionSource).toContain("OWNER_AUTHORIZATION_REQUIRED");
  });
});

describe("çalışma taslağı yalıtımı — sitemap ve metadata temiz", () => {
  const sitemapSource = readFileSync(
    resolve(__dirname, "../src/app/sitemap.xml/route.ts"),
    "utf-8"
  );

  it("sitemap yalnız yayınlanmış kayıtları listeler ve taslağa bakmaz", () => {
    expect(sitemapSource).toContain('.eq("is_published", true)');
    expect(sitemapSource).not.toContain("store_working_drafts");
    expect(sitemapSource).not.toContain("get_or_create_working_draft");
  });
});
