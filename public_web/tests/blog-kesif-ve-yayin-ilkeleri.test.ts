import { describe, expect, it } from "vitest";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import type { BlogListeYazisi } from "@/data/blogYazilari";
import { blogYazilariniFiltrele } from "@/lib/blogKesif";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

const YAZILAR: BlogListeYazisi[] = [
  {
    slug: "kuafor-rehberi",
    baslik: "Kuaför için dijital vitrin rehberi",
    ozet: "Müşteri iletişimi ve işletme bilgileri",
    kategori: "Dijital Vitrin",
    icerikTuru: "rehber",
    sektorler: ["kuaför", "berber"],
    kapak: null,
    kapakAlt: null,
    yayinTarihi: "2026-09-01",
    guncellemeTarihi: null,
    okumaDakika: 4,
  },
  {
    slug: "google-rehberi",
    baslik: "Google İşletme Profili rehberi",
    ozet: "Google'da keşfedilme ve profil doğrulama",
    kategori: "Google ve Keşfedilme",
    icerikTuru: "rehber",
    sektorler: [],
    kapak: null,
    kapakAlt: null,
    yayinTarihi: "2026-09-02",
    guncellemeTarihi: null,
    okumaDakika: 5,
  },
];

describe("blog keşif ve yayın ilkeleri sözleşmesi", () => {
  it("Türkçe karakter farklarında aramayı bozmaz", () => {
    const sonuc = blogYazilariniFiltrele(YAZILAR, "kuafor", "Tümü");
    expect(sonuc.map((yazi) => yazi.slug)).toEqual(["kuafor-rehberi"]);
  });

  it("çok kelimeli aramada tüm kelimeleri aranabilir metinde arar", () => {
    const sonuc = blogYazilariniFiltrele(YAZILAR, "google profil", "Tümü");
    expect(sonuc.map((yazi) => yazi.slug)).toEqual(["google-rehberi"]);
  });

  it("kategori filtresi yalnız seçilen kategoriyi döndürür", () => {
    const sonuc = blogYazilariniFiltrele(
      YAZILAR,
      "",
      "Google ve Keşfedilme",
    );
    expect(sonuc.map((yazi) => yazi.slug)).toEqual(["google-rehberi"]);
  });

  it("blogdaki Yayın ilkeleri bağlantısının gerçek sayfası vardır", () => {
    const yol = "src/app/(site)/blog/yayin-ilkeleri/page.tsx";
    expect(existsSync(resolve(KOK, yol))).toBe(true);

    const kesif = oku("src/components/blog/BlogKesif.tsx");
    const ilkeler = oku(yol);
    expect(kesif).toContain('href="/blog/yayin-ilkeleri"');
    expect(ilkeler).toMatch(/blogYayindaMi\(\)/);
    expect(ilkeler).toMatch(/notFound\(\)/);
  });

  it("blog metadata bütün yazıları kaynaklıymış gibi tanımlamaz", () => {
    const kaynak = oku("src/app/(site)/blog/page.tsx").toLocaleLowerCase("tr-TR");
    expect(kaynak).not.toContain("kaynaklı işletme rehberleri");
    expect(kaynak).toContain("kontrol edilmiş işletme rehberleri");
  });
});
