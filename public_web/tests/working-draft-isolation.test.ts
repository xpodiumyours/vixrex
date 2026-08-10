import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

// implementation_plan.md Commit 6 (koruma sınırı 3): sahip çalışma taslağı
// müşteri yanıtına, SEO verisine, sitemap'e veya paylaşım bağlantısına sızmaz.

const CUSTOMER_PATHS = [
  resolve(__dirname, "../src/app/v/[slug]/urun/[productSlug]/page.tsx"),
  resolve(__dirname, "../src/app/v/[slug]/yazilar/page.tsx"),
  resolve(__dirname, "../src/app/v/[slug]/yazilar/[articleSlug]/page.tsx"),
  resolve(__dirname, "../src/app/sitemap.xml/route.ts"),
  resolve(__dirname, "../src/app/robots.txt/route.ts"),
];

const MAIN_PAGE_PATH = resolve(__dirname, "../src/app/v/[slug]/page.tsx");
const pageSource = readFileSync(MAIN_PAGE_PATH, "utf-8");

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

// 2026-08-10 — get_or_create_working_draft en son BURADA yeniden tanımlanır
// (bir sonraki migration'da eklenen strip_draft_secrets çağrısıyla). Bu
// sözleşme testi en güncel tanımı, dosyada nerede olursa olsun, okur.
const SECRETS_MIGRATION_PATH = resolve(
  __dirname,
  "../../supabase/migrations/20260810190000_strip_draft_secrets_shared.sql"
);
const secretsMigrationSource = readFileSync(SECRETS_MIGRATION_PATH, "utf-8");

const latestFunctionStart = secretsMigrationSource.indexOf(
  "create or replace function public.get_or_create_working_draft"
);
const latestFunctionSource = secretsMigrationSource.slice(
  latestFunctionStart,
  secretsMigrationSource.indexOf("$$;", latestFunctionStart) + 3
);

const sessionFunctionStart = secretsMigrationSource.indexOf(
  "create or replace function public.get_working_draft_for_session"
);
const sessionFunctionSource = secretsMigrationSource.slice(
  sessionFunctionStart,
  secretsMigrationSource.indexOf("$$;", sessionFunctionStart) + 3
);

describe("çalışma taslağı yalıtımı — müşteri yolu taslağa dokunmaz", () => {
  it("müşteri vitrin (ürün, yazı), sitemap ve robots yolları çalışma taslağını hiç kullanmaz", () => {
    for (const filePath of CUSTOMER_PATHS) {
      const source = readFileSync(filePath, "utf-8");
      expect(source, filePath).not.toContain("store_working_drafts");
      expect(source, filePath).not.toContain("get_or_create_working_draft");
    }
  });

  it("ana sayfa müşteri veri sorgusu (_getStoreData) taslağa bakmaz", () => {
    const customerQuery = pageSource.slice(
      pageSource.indexOf("async function _getStoreData"),
      pageSource.indexOf("const getStoreData")
    );
    expect(customerQuery).not.toContain("store_working_drafts");
    expect(customerQuery).not.toContain("get_or_create_working_draft");
    expect(customerQuery).not.toContain("getWorkingDraft");
  });

  it("ana sayfa preview_token veri sorgusu (getStorePreviewData) taslağa bakmaz", () => {
    const previewQuery = pageSource.slice(
      pageSource.indexOf("async function getStorePreviewData"),
      pageSource.indexOf("/// Sahip çalışma alanı:")
    );
    expect(previewQuery).not.toContain("store_working_drafts");
    expect(previewQuery).not.toContain("get_or_create_working_draft");
    expect(previewQuery).not.toContain("getWorkingDraft");
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

// code-review 2026-08-10: get_or_create_working_draft (Flutter'ın hâlâ
// çağırdığı, eski RPC) taslağı ilk oluştururken edit_token/user_id/yasal
// onay hash'lerini AYIKLAMADAN gömüyordu — get_working_draft_for_session
// (Next.js'in kullandığı güncel RPC) bunu temizliyordu. İki RPC aynı
// temizleme mantığını kopyalamıştı, biri güncellenmiş biri unutulmuştu.
// Artık ikisi de tek paylaşılan public.strip_draft_secrets(jsonb)
// fonksiyonunu çağırıyor — kopyalama hatası bir daha olamaz.
describe("çalışma taslağı yalıtımı — paylaşılan sır temizleme", () => {
  const SECRET_KEYS = [
    "edit_token",
    "user_id",
    "privacy_notice_hash",
    "terms_hash",
    "publication_consent_hash",
  ];

  it("strip_draft_secrets tek kaynak fonksiyonu tanımlıdır ve 5 sırrı da kapsar", () => {
    expect(secretsMigrationSource).toContain(
      "create or replace function public.strip_draft_secrets"
    );
    const stripFnStart = secretsMigrationSource.indexOf(
      "create or replace function public.strip_draft_secrets"
    );
    const stripFnSource = secretsMigrationSource.slice(
      stripFnStart,
      secretsMigrationSource.indexOf("$$;", stripFnStart) + 3
    );
    for (const key of SECRET_KEYS) {
      expect(stripFnSource, key).toContain(key);
    }
  });

  it("get_or_create_working_draft artık oluştururken VE dönerken strip_draft_secrets çağırır", () => {
    // Oluşturma dalı (to_jsonb(s) ham satırı taslağa yazan INSERT).
    expect(latestFunctionSource).toMatch(
      /insert into public\.store_working_drafts[\s\S]*?strip_draft_secrets\(to_jsonb\(s\)\)/
    );
    // Dönüş — "ikinci kalkan": bu düzeltmeden önce oluşmuş kirli satırlar da temiz döner.
    expect(latestFunctionSource).toMatch(
      /'draft_data',\s*public\.strip_draft_secrets\(/
    );
    // Artık kendi başına ham anahtar listesi tekrarlamıyor — tek kaynağa devrediyor.
    expect(latestFunctionSource).not.toContain(
      "'{edit_token,user_id,privacy_notice_hash,terms_hash,publication_consent_hash}'"
    );
  });

  it("get_working_draft_for_session da aynı paylaşılan fonksiyonu çağırır, kendi kopyasını tutmaz", () => {
    expect(sessionFunctionSource).toMatch(
      /insert into public\.store_working_drafts[\s\S]*?strip_draft_secrets\(to_jsonb\(s\)\)/
    );
    expect(sessionFunctionSource).toMatch(
      /'draft_data',\s*public\.strip_draft_secrets\(/
    );
    expect(sessionFunctionSource).not.toContain(
      "'{edit_token,user_id,privacy_notice_hash,terms_hash,publication_consent_hash}'"
    );
  });

  it("mevcut kirli satırlar için tek seferlik, geri dönüşlü temizleme UPDATE'i vardır", () => {
    expect(secretsMigrationSource).toContain(
      "create table if not exists public._backup_store_working_drafts_pre_strip"
    );
    expect(secretsMigrationSource).toMatch(
      /update public\.store_working_drafts[\s\S]*?strip_draft_secrets\(draft_data\)/
    );
    // Yalnız gerçekten kirli satırlara dokunur — kör bir UPDATE değil. Anahtar
    // listesi burada tekrar yazılmaz, tespit paylaşılan fonksiyondan geçer.
    expect(secretsMigrationSource).toContain(
      "draft_data <> public.strip_draft_secrets(draft_data)"
    );
  });

  it("yedek tablo da RLS ile korunur — sızıntıyı yeni bir tabloda tekrarlamaz", () => {
    expect(secretsMigrationSource).toMatch(
      /alter table public\._backup_store_working_drafts_pre_strip enable row level security/
    );
    // store_working_drafts ile aynı desen: RLS açık, hiç politika yok.
    const policyStatements = secretsMigrationSource
      .split(/\bcreate policy\b/i)
      .slice(1);
    for (const statement of policyStatements) {
      expect(statement, statement).not.toMatch(
        /_backup_store_working_drafts_pre_strip/i
      );
    }
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
