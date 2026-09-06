import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

const migration = oku(
  "../supabase/migrations/20260904225525_add_vixrex_blog_store_import.sql",
);
const api = oku("src/app/api/articles/import-vixrex/route.ts");
const webYonetim = oku("src/app/v/[slug]/blog-yonetim/page.tsx");
const flutterService = oku("../lib/services/article_service.dart");
const flutterListe = oku("../lib/screens/blog_post_list_screen.dart");

describe("Katman 3 merkezi yazıyı vitrine taslak çekme sözleşmesi", () => {
  it("kaynak provenance alanlarını ve kaynak silinince kopyayı koruyan FK'yi ekler", () => {
    for (const alan of [
      "source_vixrex_blog_article_id",
      "source_vixrex_blog_article_slug",
      "source_vixrex_blog_import_mode",
      "source_vixrex_blog_imported_at",
    ]) {
      expect(migration).toContain(alan);
    }
    expect(migration).toMatch(
      /references public\.vixrex_blog_articles\(id\)[\s\S]*on delete set null/i,
    );
  });

  it("aynı merkezi kaynak aynı vitrinde partial unique index ile idempotenttir", () => {
    expect(migration).toMatch(
      /create unique index if not exists uq_store_articles_vixrex_source_slug[\s\S]*store_slug, source_vixrex_blog_article_slug[\s\S]*where source_vixrex_blog_article_slug is not null/i,
    );
    expect(migration).toMatch(
      /on conflict \(store_slug, source_vixrex_blog_article_slug\)[\s\S]*do nothing/i,
    );
    expect(migration).toContain("'created', false");
  });

  it("DB yalnız published merkezi kaynaktan daima draft vitrin yazısı üretir", () => {
    expect(migration).toMatch(/a\.status = 'published'/i);
    expect(migration).toContain("SOURCE_NOT_PUBLISHED");
    expect(migration).toMatch(/[\s,]'draft',[\s\n]*v_source\.id/i);
    expect(migration).not.toMatch(/v_source\.published_at/i);
  });

  it("iki import modu dışında değer kabul etmez", () => {
    expect(migration).toContain("'linked_excerpt', 'adaptable_draft'");
    expect(migration).toContain("INVALID_IMPORT_MODE");
    expect(api).toContain('mode !== "linked_excerpt" && mode !== "adaptable_draft"');
  });

  it("DB hedef vitrinin yetkisini owner-session veya auth.uid ile yeniden doğrular", () => {
    expect(migration).toContain("public.owner_sessions");
    expect(migration).toContain("os.store_id = v_store_id");
    expect(migration).toContain("os.session_token_hash = v_token_hash");
    expect(migration).toContain("os.expires_at > now()");
    expect(migration).toContain("s.user_id = auth.uid()");
    expect(migration).toContain("STORE_NOT_AUTHORIZED");
  });

  it("Next.js import yolu imzalı owner cookieyi doğrular ve aynı dar RPC'yi çağırır", () => {
    expect(api).toContain("OWNER_SESSION_COOKIE");
    expect(api).toContain("verifyOwnerSession(ownerCookie, slug)");
    expect(api).toContain('"import_vixrex_blog_article_to_store"');
    expect(api).toContain("p_session_token: ownerSession.sessionToken");
    expect(api).not.toContain("SUPABASE_SERVICE_ROLE_KEY");
    expect(api).not.toContain('status: "published"');
  });

  it("Next.js mevcut Blog Yönetimi içinde bounded published kütüphaneyi kullanır ve mevcut editöre döner", () => {
    expect(webYonetim).toContain("Vixrex Kütüphanesinden Yazı Ekle");
    expect(webYonetim).toContain("const KUTUPHANE_LIMIT = 20");
    expect(webYonetim).toContain('.eq("status", "published")');
    expect(webYonetim).toContain(".range(0, KUTUPHANE_LIMIT - 1)");
    expect(webYonetim).toContain('fetch("/api/articles/import-vixrex"');
    expect(webYonetim).toContain("/blog-yonetim/${sonuc.yaziSlug}");
    expect(webYonetim).toContain('"linked_excerpt"');
    expect(webYonetim).toContain('"adaptable_draft"');
  });

  it("Flutter ayrı backend kurmadan aynı published kütüphane ve aynı RPC sözleşmesini kullanır", () => {
    expect(flutterService).toContain("fetchVixrexLibrary");
    expect(flutterService).toContain(".eq('status', 'published')");
    expect(flutterService).toContain("final safeLimit = limit.clamp(1, 50).toInt();");
    expect(flutterService).toContain("'import_vixrex_blog_article_to_store'");
    expect(flutterService).toContain("'p_session_token': null");
    expect(flutterListe).toContain("Vixrex Kütüphanesi");
    expect(flutterListe).toContain("'linked_excerpt'");
    expect(flutterListe).toContain("'adaptable_draft'");
    expect(flutterListe).toContain("AppRouter.navigateToBlogEditor");
  });

  it("RPC public'e açık bırakılmaz; yalnız gerekli istemci rolleri execute alır", () => {
    expect(migration).toMatch(
      /revoke execute on function public\.import_vixrex_blog_article_to_store\([\s\S]*\) from public/i,
    );
    expect(migration).toMatch(
      /grant execute on function public\.import_vixrex_blog_article_to_store\([\s\S]*\) to anon, authenticated/i,
    );
  });
});
