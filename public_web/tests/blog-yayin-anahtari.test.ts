import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  BLOG_YAZILARI,
  blogYayindaMi,
  yayindakiYazilar,
  yaziyiBul,
} from "@/data/blogYazilari";

/**
 * BLOG YAYIN ANAHTARI SÖZLEŞMESİ (2026-08-28).
 *
 * Casper'ın kararı: blog altyapısı şimdi kurulur ama Keşfet gerçek
 * vitrinlerle dolana kadar YAYINA ÇIKMAZ. Boş ya da üç yazılık blog
 * yokluktan kötüdür — yazıyı okuyan kişi Keşfet'e gidip 9 demo vitrin
 * görürse bir daha dönmez.
 *
 * Bu test o kararı koda bağlar. Taslak bir yazının kazara yayına sızması,
 * bir sayfanın kırık adres bildirmesi ya da site haritasına var olmayan
 * bir adresin girmesi buradan geçemez.
 */

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

describe("blog yayın anahtarı", () => {
  it("taslak yazılar hiçbir listeye sızmaz", () => {
    const taslaklar = BLOG_YAZILARI.filter((yazi) => !yazi.yayinda);
    const yayindakiSluglar = new Set(yayindakiYazilar().map((y) => y.slug));

    for (const taslak of taslaklar) {
      expect(yayindakiSluglar.has(taslak.slug)).toBe(false);
      expect(yaziyiBul(taslak.slug)).toBeUndefined();
    }
  });

  it("blogYayindaMi yalnız yayındaki yazı varken true döner", () => {
    expect(blogYayindaMi()).toBe(yayindakiYazilar().length > 0);
  });

  it("her yazının adresi benzersiz ve geçerli", () => {
    const sluglar = BLOG_YAZILARI.map((yazi) => yazi.slug);
    expect(new Set(sluglar).size).toBe(sluglar.length);

    for (const yazi of BLOG_YAZILARI) {
      // Adres deseni: Türkçe karakter, büyük harf ve boşluk olmaz.
      expect(yazi.slug).toMatch(/^[a-z0-9]+(-[a-z0-9]+)*$/);
      expect(yazi.baslik.trim().length).toBeGreaterThan(0);
      expect(yazi.ozet.trim().length).toBeGreaterThan(0);
      expect(yazi.govde.trim().length).toBeGreaterThan(0);
      expect(yazi.okumaDakika).toBeGreaterThan(0);
    }
  });

  it("liste sayfası boşken notFound çağırıyor", () => {
    // Kaynak taraması: `yayindakiYazilar` boş dönerse sayfa 404 vermeli.
    // Bu kontrol kaldırılırsa boş bir blog listesi yayına çıkar.
    const kaynak = oku("src/app/(site)/blog/page.tsx");
    expect(kaynak).toMatch(/yazilar\.length === 0\)\s*notFound\(\)/);
  });

  it("yazı sayfası yalnız yayındaki yazıyı okur", () => {
    const kaynak = oku("src/app/(site)/blog/[slug]/page.tsx");
    // `yaziyiBul` taslakları elemektedir; doğrudan BLOG_YAZILARI'na
    // gitmek o elemeyi atlatır.
    expect(kaynak).not.toMatch(/BLOG_YAZILARI/);
    expect(kaynak).toMatch(/yaziyiBul\(slug\)/);
    expect(kaynak).toMatch(/if \(!yazi\) notFound\(\)/);
  });

  it("site haritası blog adreslerini yayın anahtarına bağlıyor", () => {
    const kaynak = oku("src/app/sitemap.xml/route.ts");
    expect(kaynak).toMatch(/blogYayindaMi\(\)/);
    expect(kaynak).not.toMatch(/BLOG_YAZILARI/);
  });

  it("altbilgi bağlantısı yayın anahtarına bağlı", () => {
    const kaynak = oku("src/components/site/SiteFooter.tsx");
    expect(kaynak).toMatch(/blogYayindaMi\(\)/);
  });

  it("gövdeler ham HTML taşımıyor", () => {
    // Gövde biçimi düz metin. HTML yazılırsa temizleyiciden geçse bile
    // paragraflama mantığı sessizce değişir.
    for (const yazi of BLOG_YAZILARI) {
      expect(yazi.govde).not.toMatch(/<[a-z][^>]*>/i);
    }
  });
});
