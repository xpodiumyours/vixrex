import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

const migration = oku(
  "../supabase/migrations/20260904193000_add_vixrex_blog_library_metadata.sql"
);
const kaynak = oku("src/data/blogYazilari.ts");

describe("Katman 2 merkezi blog kütüphanesi sözleşmesi", () => {
  it("mevcut merkezi tabloyu genişletir, store_articles semantiğine dokunmaz", () => {
    expect(migration).toMatch(/alter table public\.vixrex_blog_articles/i);
    expect(migration).not.toMatch(/alter table public\.store_articles/i);
    expect(migration).not.toMatch(/create table .*store_articles/i);
  });

  it("konu, amaç, sektör, konum, etiket ve provenance metadata alanlarını taşır", () => {
    for (const alan of [
      "primary_topic",
      "purpose",
      "sector_ids",
      "location_scope",
      "province_codes",
      "district_targets",
      "tags",
      "provenance",
      "source_urls",
    ]) {
      expect(migration).toContain(alan);
      expect(kaynak).toContain(alan);
    }
  });

  it("yayındaki merkezi yazı konu ve amaç olmadan yayınlanamaz", () => {
    expect(migration).toMatch(/published_library_metadata_check/i);
    expect(migration).toMatch(/status <> 'published'/i);
    expect(migration).toMatch(/primary_topic is not null/i);
    expect(migration).toMatch(/purpose is not null/i);
  });

  it("ilgili yazılar FK relation tablosunda ve public iki uç published şartıyla korunur", () => {
    expect(migration).toMatch(/create table if not exists public\.vixrex_blog_article_relations/i);
    expect(migration).toMatch(/references public\.vixrex_blog_articles\(id\) on delete cascade/i);
    expect(migration).toMatch(/a\.status = 'published'/i);
    expect(migration).toMatch(/b\.status = 'published'/i);
    expect(kaynak).toContain('from("vixrex_blog_article_relations")');
  });

  it("public sorgular konu/sektör/il/etiket filtrelerini DB seviyesinde uygular", () => {
    expect(kaynak).toContain('.eq("primary_topic", filtreler.konu)');
    expect(kaynak).toContain('.contains("sector_ids", [filtreler.sektor])');
    expect(kaynak).toContain('.contains("province_codes", [filtreler.ilKodu])');
    expect(kaynak).toContain('.contains("tags", [filtreler.etiket])');
  });

  it("kontrollü konu ve sektör route'ları vardır", () => {
    const konu = oku("src/app/(site)/blog/konu/[topic]/page.tsx");
    const sektor = oku("src/app/(site)/blog/sektor/[sector]/page.tsx");
    expect(konu).toMatch(/yayindakiYazilar\(\{ konu: konu\.id \}\)/);
    expect(sektor).toMatch(/yayindakiYazilar\(\{ sektor: sektor\.id \}\)/);
  });

  it("sitemap yalnız yayın içeriği bulunan kontrollü konu/sektör sayfalarını ekler", () => {
    const sitemap = oku("src/app/sitemap.xml/route.ts");
    expect(sitemap).toContain("blogKonuIdleri");
    expect(sitemap).toContain("blogSektorIdleri");
    expect(sitemap).toContain("/blog/konu/");
    expect(sitemap).toContain("/blog/sektor/");
  });

  it("merkezi kapak yükleme owner-session'dan ayrıdır ve ortak sıkıştırma çekirdeğini kullanır", () => {
    const upload = oku("src/app/api/vixrex-blog/admin-upload/route.ts");
    const auth = oku("src/lib/platformAdminAuth.ts");
    const compression = oku("src/lib/gorselSikistir.ts");

    expect(upload).toContain("platformAdminDogrula");
    expect(upload).toContain("gorseliSikistir");
    expect(upload).toContain('vixrex-blog/covers/');
    expect(upload).not.toContain("OWNER_SESSION_COOKIE");
    expect(upload).not.toContain("FIELD_BY_KEY");
    expect(auth).toContain('.from("admins")');
    expect(auth).toContain("auth.getUser(token)");
    expect(compression).toContain("export const UZUN_KENAR = 1600");
    expect(compression).toContain("export const KALITE = 82");
  });
});
