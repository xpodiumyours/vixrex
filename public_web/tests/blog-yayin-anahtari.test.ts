import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

/**
 * VIXREX BLOG YAYIN SÖZLEŞMESİ — Katman 1.
 *
 * Platform blogu artık kod içi dizi yerine `vixrex_blog_articles` tablosunda.
 * Bu test canlı DB'yi taklit etmez; migration + public okuma katmanı + route
 * kaynaklarının aynı güvenlik sözleşmesini koruduğunu kilitler. Gerçek RLS ve
 * migration zinciri CI'daki Supabase yerel doğrulamasında ayrıca çalışır.
 */

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

const migration = oku(
  "../supabase/migrations/20260904173500_add_vixrex_blog_articles.sql"
);
const kaynak = oku("src/data/blogYazilari.ts");

describe("Vixrex merkezi blog yayın sözleşmesi", () => {
  it("platform blogu store_articles yerine ayrı merkezi tabloda yaşar", () => {
    expect(migration).toMatch(/create table if not exists public\.vixrex_blog_articles/i);
    expect(migration).not.toMatch(/alter table public\.store_articles/i);
    expect(kaynak).toMatch(/\.from\("vixrex_blog_articles"\)/);
    expect(kaynak).not.toMatch(/BLOG_YAZILARI/);
  });

  it("public erişim yalnız published satırlara açıktır", () => {
    expect(migration).toMatch(/enable row level security/i);
    expect(migration).toMatch(/to anon, authenticated\s+using \(status = 'published'\)/i);

    const publishedFiltreleri = kaynak.match(/\.eq\("status", "published"\)/g) ?? [];
    expect(publishedFiltreleri.length).toBeGreaterThanOrEqual(3);
  });

  it("mevcut iki Vixrex yazısı migration içinde taslak kalır", () => {
    expect(migration).toContain("'kuafor-icin-internet-sitesi'");
    expect(migration).toContain("'isletmemi-googleda-nasil-gosteririm'");

    const taslakKayitlari = migration.match(/\n  'draft',\n  4,/g) ?? [];
    expect(taslakKayitlari).toHaveLength(2);
  });

  it("slug ve yayın tarihi veri bütünlüğü DB seviyesinde korunur", () => {
    expect(migration).toMatch(/slug ~ '\^\[a-z0-9\]/i);
    expect(migration).toMatch(/status in \('draft', 'published'\)/i);
    expect(migration).toMatch(/status <> 'published' or published_at is not null/i);
    expect(migration).toMatch(/unique/i);
  });

  it("liste sayfası boşken 404 davranışını korur", () => {
    const liste = oku("src/app/(site)/blog/page.tsx");
    expect(liste).toMatch(/const yazilar = await yayindakiYazilar\(\)/);
    expect(liste).toMatch(/yazilar\.length === 0\) notFound\(\)/);
  });

  it("detay sayfası yalnız merkezi public okuyucuyu kullanır", () => {
    const detay = oku("src/app/(site)/blog/[slug]/page.tsx");
    expect(detay).toMatch(/await yaziyiBul\(slug\)/);
    expect(detay).toMatch(/if \(!yazi\) notFound\(\)/);
    expect(detay).not.toMatch(/store_articles/);
    expect(detay).not.toMatch(/BLOG_YAZILARI/);
  });

  it("sitemap yalnız gerçek yayın listesi doluysa blog URL üretir", () => {
    const sitemap = oku("src/app/sitemap.xml/route.ts");
    expect(sitemap).toMatch(/await Promise\.all\(/);
    expect(sitemap).toMatch(/vixrexBlogYazilari\.length > 0/);
    expect(sitemap).toMatch(/vixrexBlogYazilari\.map/);
    expect(sitemap).not.toMatch(/BLOG_YAZILARI/);
  });

  it("altbilgi async merkezi yayın anahtarını bekler", () => {
    const footer = oku("src/components/site/SiteFooter.tsx");
    expect(footer).toMatch(/export async function SiteFooter/);
    expect(footer).toMatch(/await blogYayindaMi\(\)/);
  });
});
