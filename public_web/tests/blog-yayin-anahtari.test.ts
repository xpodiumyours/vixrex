import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  BLOG_KATEGORILERI,
  BLOG_YAZILARI,
  blogYayindaMi,
  incelemeGerekenYazilar,
  yayindakiYazilar,
  yaziDurumunuHesapla,
  yaziYayinKalitesiUygun,
  yaziyiBul,
} from "@/data/blogYazilari";
import {
  govdeyiBloklaraAyir,
  icindekileriCikar,
  okumaDakikasiHesapla,
} from "@/lib/blogIcerik";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

describe("blog yayın anahtarı ve içerik sözleşmesi", () => {
  it("taslak yazılar hiçbir yayın listesine sızmaz", () => {
    const taslaklar = BLOG_YAZILARI.filter((yazi) => !yazi.yayinda);
    const yayindakiSluglar = new Set(yayindakiYazilar().map((y) => y.slug));

    for (const taslak of taslaklar) {
      expect(yayindakiSluglar.has(taslak.slug)).toBe(false);
      expect(yaziyiBul(taslak.slug)).toBeUndefined();
    }
  });

  it("arşiv durumu yayında true olsa bile arşiv olarak korunur", () => {
    const arsiv = {
      ...BLOG_YAZILARI[0],
      slug: "arsiv-test",
      yayinTarihi: "2026-01-01",
      yayinda: true,
      durum: "arsiv" as const,
    };
    expect(yaziDurumunuHesapla(arsiv, new Date("2026-09-10T00:00:00Z"))).toBe(
      "arsiv"
    );
  });

  it("arşiv durumu yayın anahtarı kapalıyken de arşiv olarak korunur", () => {
    const arsiv = {
      ...BLOG_YAZILARI[0],
      slug: "arsiv-kapali-test",
      yayinda: false,
      durum: "arsiv" as const,
    };
    expect(yaziDurumunuHesapla(arsiv, new Date("2026-09-10T00:00:00Z"))).toBe(
      "arsiv"
    );
  });

  it("blogYayindaMi yalnız yayımlanabilir yazı varken true döner", () => {
    expect(blogYayindaMi()).toBe(yayindakiYazilar().length > 0);
  });

  it("her yazının zorunlu kalite alanları dolu", () => {
    const sluglar = BLOG_YAZILARI.map((yazi) => yazi.slug);
    expect(new Set(sluglar).size).toBe(sluglar.length);

    for (const yazi of BLOG_YAZILARI) {
      expect(yazi.slug).toMatch(/^[a-z0-9]+(-[a-z0-9]+)*$/);
      expect(yazi.baslik.trim().length).toBeGreaterThan(0);
      expect(yazi.ozet.trim().length).toBeGreaterThan(0);
      expect(yazi.govde.trim().length).toBeGreaterThan(0);
      expect(yazi.cozduguSoru.trim().length).toBeGreaterThan(0);
      expect(BLOG_KATEGORILERI).toContain(yazi.kategori);
      expect(yazi.yazar.ad.trim().length).toBeGreaterThan(0);
      expect(yazi.sonKontrolTarihi).toMatch(/^\d{4}-\d{2}-\d{2}$/);
      expect(["harici_platform", "vixrex_urun", "genel"]).toContain(
        yazi.kontrolSinifi
      );
      expect(okumaDakikasiHesapla(yazi.govde)).toBeGreaterThan(0);

      if (yazi.kapak) {
        expect(yazi.kapakAlt?.trim().length).toBeGreaterThan(0);
        expect(yazi.gorselKaynagi?.trim().length).toBeGreaterThan(0);
        expect(yazi.gorselKullanimHakki?.trim().length).toBeGreaterThan(0);
      }

      if (yazi.yayinda) {
        expect(yazi.durum).not.toBe("taslak");
        expect(yazi.durum).not.toBe("arsiv");
        expect(yazi.yayinTarihi).toMatch(/^\d{4}-\d{2}-\d{2}$/);
      }
    }
  });

  it("ham HTML taşımaz; sınırlı Markdown başlıkları ayrıştırılır", () => {
    for (const yazi of BLOG_YAZILARI) {
      expect(yazi.govde).not.toMatch(/<[a-z][^>]*>/i);
      expect(govdeyiBloklaraAyir(yazi.govde).length).toBeGreaterThan(0);
      expect(icindekileriCikar(yazi.govde).every((x) => x.id.length > 0)).toBe(
        true
      );
    }
  });

  it("aynı veya işaretten oluşan başlıklar benzersiz ve boş olmayan id üretir", () => {
    const icindekiler = icindekileriCikar(
      "## Aynı başlık\n\n## Aynı başlık\n\n### ???"
    );
    expect(icindekiler.map((x) => x.id)).toEqual([
      "ayni-baslik",
      "ayni-baslik-2",
      "bolum",
    ]);
  });

  it("Google/harici platform rehberi 60 gün geçince inceleme gerekli olur", () => {
    const google = {
      ...BLOG_YAZILARI[1],
      yayinTarihi: "2026-01-01",
      sonKontrolTarihi: "2026-06-01",
      yayinda: true,
      durum: "yayinda" as const,
      kontrolSinifi: "harici_platform" as const,
    };
    expect(yaziDurumunuHesapla(google, new Date("2026-08-01T00:00:00Z"))).toBe(
      "inceleme_gerekli"
    );
  });

  it("genel rehber 90 gün geçmeden otomatik incelemeye düşmez", () => {
    const genel = {
      ...BLOG_YAZILARI[0],
      yayinTarihi: "2026-01-01",
      sonKontrolTarihi: "2026-06-01",
      yayinda: true,
      durum: "yayinda" as const,
      kontrolSinifi: "genel" as const,
    };
    expect(yaziDurumunuHesapla(genel, new Date("2026-08-01T00:00:00Z"))).toBe(
      "yayinda"
    );
  });

  it("gelecekteki son kontrol tarihi inceleme gerekli sayılır", () => {
    const yazi = {
      ...BLOG_YAZILARI[0],
      yayinTarihi: "2026-09-01",
      sonKontrolTarihi: "2026-09-11",
      yayinda: true,
      durum: "yayinda" as const,
      kontrolSinifi: "vixrex_urun" as const,
    };
    expect(yaziDurumunuHesapla(yazi, new Date("2026-09-10T12:00:00Z"))).toBe(
      "inceleme_gerekli"
    );
  });

  it("geçersiz ve gelecekteki tarihler yayın kalite kapısından geçmez", () => {
    const temel = {
      ...BLOG_YAZILARI[1],
      yayinTarihi: "2026-09-01",
      guncellemeTarihi: null,
      sonKontrolTarihi: "2026-09-10",
      yayinda: true,
      durum: "yayinda" as const,
    };
    const bugun = new Date("2026-09-10T12:00:00Z");

    expect(yaziYayinKalitesiUygun(temel, bugun)).toBe(true);
    expect(
      yaziYayinKalitesiUygun(
        { ...temel, sonKontrolTarihi: "2026-02-31" },
        bugun
      )
    ).toBe(false);
    expect(
      yaziYayinKalitesiUygun(
        { ...temel, sonKontrolTarihi: "2026-09-11" },
        bugun
      )
    ).toBe(false);
    expect(
      yaziYayinKalitesiUygun(
        { ...temel, yayinTarihi: "2026-09-11" },
        bugun
      )
    ).toBe(false);
  });

  it("son kontrol anlamlı güncellemeden eskiyse yayın kalite kapısından geçmez", () => {
    const yazi = {
      ...BLOG_YAZILARI[1],
      yayinTarihi: "2026-09-01",
      guncellemeTarihi: "2026-09-09",
      sonKontrolTarihi: "2026-09-08",
      guncellemeNotlari: [
        { tarih: "2026-09-09", aciklama: "İçerik güncellendi." },
      ],
      yayinda: true,
      durum: "yayinda" as const,
    };

    expect(
      yaziYayinKalitesiUygun(yazi, new Date("2026-09-10T12:00:00Z"))
    ).toBe(false);
  });

  it("inceleme listesi yalnız yayımdaki ve süresi dolmuş yazıları verir", () => {
    expect(incelemeGerekenYazilar(new Date("2026-09-10T00:00:00Z"))).toEqual([]);
  });

  it("beş ana kategori sözleşmesi değişmez", () => {
    expect(BLOG_KATEGORILERI).toEqual([
      "Dijital Vitrin",
      "Google ve Keşfedilme",
      "Müşteri İletişimi",
      "Vixrex’te Yenilikler",
      "İşletme Hikâyeleri",
    ]);
  });

  it("eski taslaklardaki doğrulanmamış kesin ifadeler kalmaz", () => {
    const kaynak = oku("src/data/blogYazilari.ts").toLocaleLowerCase("tr-TR");
    expect(kaynak).not.toContain("yaklaşık on dakika");
    expect(kaynak).not.toContain("bir ila dört hafta");
    expect(kaynak).not.toContain("kod içeren bir kart gönderir");
    expect(kaynak).not.toContain("bunu ücretsiz nasıl");
  });

  it("liste sayfası boşken notFound çağırıyor", () => {
    const kaynak = oku("src/app/(site)/blog/page.tsx");
    expect(kaynak).toMatch(/yazilar\.length === 0\) notFound\(\)/);
  });

  it("yazı sayfası yalnız yayın filtresinden gelen yazıyı okur", () => {
    const kaynak = oku("src/app/(site)/blog/[slug]/page.tsx");
    expect(kaynak).not.toMatch(/BLOG_YAZILARI/);
    expect(kaynak).toMatch(/yaziyiBul\(slug\)/);
    expect(kaynak).toMatch(/if \(!yazi\) notFound\(\)/);
  });

  it("site haritası blog adreslerini yayın anahtarına bağlıyor", () => {
    const kaynak = oku("src/app/sitemap.xml/route.ts");
    expect(kaynak).toMatch(/blogYayindaMi\(\)/);
    expect(kaynak).not.toMatch(/BLOG_YAZILARI/);
    expect(kaynak).toMatch(/blogSonAnlamliDegisiklikTarihi/);
    expect(kaynak).toMatch(/guncellemeTarihi \|\| yazi\.yayinTarihi/);
  });

  it("RSS yalnız yayın filtresini kullanıyor", () => {
    const kaynak = oku("src/app/(site)/blog/rss.xml/route.ts");
    expect(kaynak).toMatch(/blogYayindaMi\(\)/);
    expect(kaynak).toMatch(/yayindakiYazilar\(\)/);
    expect(kaynak).not.toMatch(/BLOG_YAZILARI/);
  });

  it("altbilgi bağlantısı mevcut yayın anahtarına bağlı kalır", () => {
    const kaynak = oku("src/components/site/SiteFooter.tsx");
    expect(kaynak).toMatch(/blogYayindaMi\(\)/);
  });
});
