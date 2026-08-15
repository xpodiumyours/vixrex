import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * "Bu vitrini kirala" — demo vitrini taslak olarak kopyalayan RPC'nin
 * sözleşmesi. Asıl risk: kopya YAYINDA başlarsa (is_published=true) ya da
 * demo'nun sahte hukuki onay damgasını miras alırsa, kiralayan kişi
 * hiçbir şeyi kabul etmeden "kabul etmiş" görünür ve/veya taslak
 * denemeden önce vitrin gerçek müşterilere görünür olur.
 */

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const migrationSource = readFileSync(
  resolve(migrationsDir, "20260814090000_clone_demo_store_as_draft.sql"),
  "utf-8"
);
// 2026-08-15: clone_demo_store_as_draft artık start_demo_trial dışından
// çağrılamıyor (rent-demo güvenlik açığı kapatıldı, bkz. secure_rent_demo_flow
// migration'ı). Bu dosya hâlâ orijinal grant satırını taşıyor — migration'lar
// geriye dönük değiştirilmez, yetki SONRAKİ migration'da geri çekiliyor.
const secureFlowSource = readFileSync(
  resolve(migrationsDir, "20260815180000_secure_rent_demo_flow.sql"),
  "utf-8"
);

const insertBlock = migrationSource.slice(
  migrationSource.indexOf("insert into public.stores"),
  migrationSource.indexOf("if not found then")
);

describe("clone_demo_store_as_draft — kopya her zaman taslak başlar", () => {
  it("is_published sabit false, status sabit 'draft'", () => {
    expect(insertBlock).toMatch(/'draft'/);
    // SELECT listesindeki is_published DEĞİL, sabit `false` yazılıyor.
    expect(insertBlock).toMatch(/,\s*false,\s*is_store,/);
  });

  it("yalnız is_demo=true VE is_published=true kaynaklardan kopyalar", () => {
    expect(migrationSource).toContain("is_demo = true");
    expect(migrationSource).toContain("is_published = true");
  });

  it("bulunamayan/uygun olmayan kaynak için SOURCE_NOT_FOUND fırlatır", () => {
    expect(migrationSource).toContain("SOURCE_NOT_FOUND");
  });
});

describe("clone_demo_store_as_draft — hukuki onay damgası MİRAS ALINMAZ", () => {
  const legalColumns = [
    "privacy_notice_acknowledged",
    "privacy_notice_hash",
    "privacy_notice_version",
    "terms_accepted",
    "terms_hash",
    "terms_version",
    "publication_consent_accepted",
    "publication_consent_hash",
    "publication_consent_version",
    "explicit_consent_given",
    "consent_accepted_at",
  ];

  it.each(legalColumns)(
    "%s INSERT sütun listesinde yok (kopyalanmıyor)",
    (column) => {
      expect(insertBlock).not.toContain(column);
    }
  );
});

describe("clone_demo_store_as_draft — kimlik alanları yeni değerler alır", () => {
  it("id/edit_token/user_id kaynaktan kopyalanmaz — yeni slug/token, user_id null", () => {
    expect(insertBlock).toContain("p_new_slug");
    expect(insertBlock).toContain("p_edit_token");
    expect(insertBlock).toMatch(/,\s*null,\s*\n\s*name,/);
  });

  it("2026-08-14'te anon/authenticated'e açılmıştı (tarihsel — artık geçerli değil)", () => {
    expect(migrationSource).toContain(
      "grant execute on function public.clone_demo_store_as_draft(text, text, text)\n  to anon, authenticated;"
    );
  });
});

describe("clone_demo_store_as_draft — GÜVENLİK: doğrudan anon/authenticated erişimi kapalı (2026-08-15)", () => {
  it("secure_rent_demo_flow migration'ı anon/authenticated/PUBLIC'ten yetkiyi çeker", () => {
    expect(secureFlowSource).toContain(
      "revoke execute on function public.clone_demo_store_as_draft(text, text, text)\n  from public, anon, authenticated;"
    );
  });

  it("hiçbir yerde clone_demo_store_as_draft'a anon/authenticated'e yeniden grant verilmez", () => {
    expect(secureFlowSource).not.toMatch(
      /grant execute on function public\.clone_demo_store_as_draft[\s\S]*?to (anon|authenticated|public)/i
    );
  });
});
