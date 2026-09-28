import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  BLOG_BASLIK_EN_AZ,
  BLOG_BASLIK_EN_FAZLA,
  BLOG_EN_AZ_KELIME,
  BLOG_OZET_EN_AZ,
  BLOG_OZET_EN_FAZLA,
  BLOG_YAYIN_ESIGI,
  blogSeoAnalizi,
  blogYayinEngelleri,
} from "@/lib/blogSeo";

const standartYazi = {
  title: "İstanbul saç bakımı için kapsamlı rehber",
  summary:
    "İstanbul'da saç bakımı yaptırmadan önce bilmeniz gereken temel noktaları bu rehberde topladık.",
  content: `İstanbul saç bakımı ${"faydalı içerik ".repeat(300)}`,
  topic: "saç bakımı",
  city: "İstanbul",
  hasCover: true,
};

describe("blog yayın standardı", () => {
  it("standardı tutan yazıda engel bırakmaz", () => {
    expect(blogYayinEngelleri(standartYazi)).toEqual([]);
    expect(blogSeoAnalizi(standartYazi).score).toBeGreaterThanOrEqual(
      BLOG_YAYIN_ESIGI,
    );
  });

  it("başlık, özet ve kelime sayısı eksiklerini ayrı ayrı söyler", () => {
    const kisaBaslik = blogYayinEngelleri({
      ...standartYazi,
      title: "Kısa başlık",
    });
    expect(kisaBaslik).toHaveLength(1);
    expect(kisaBaslik[0]).toContain("Başlık");

    const kisaOzet = blogYayinEngelleri({
      ...standartYazi,
      summary: "Çok kısa özet.",
    });
    expect(kisaOzet).toHaveLength(1);
    expect(kisaOzet[0]).toContain("Özet");

    const kisaIcerik = blogYayinEngelleri({
      ...standartYazi,
      content: "kısa içerik ".repeat(50),
    });
    expect(kisaIcerik).toHaveLength(1);
    expect(kisaIcerik[0]).toContain(String(BLOG_EN_AZ_KELIME));
  });

  it("boş alanların hepsini birlikte bildirir", () => {
    const engeller = blogYayinEngelleri({
      title: "",
      summary: "",
      content: "",
      topic: "",
      city: "",
      hasCover: false,
    });
    expect(engeller).toHaveLength(3);
  });

  it("puan eşiği yapısal engelleri garanti etmez — kapı engellere bakar", () => {
    const puanliAmaEksik = {
      ...standartYazi,
      title: "Kısa başlık",
      summary: "Çok kısa özet.",
      content: `İstanbul saç bakımı ${"faydalı içerik ".repeat(180)}`,
    };
    expect(blogSeoAnalizi(puanliAmaEksik).score).toBeGreaterThanOrEqual(
      BLOG_YAYIN_ESIGI,
    );
    expect(blogYayinEngelleri(puanliAmaEksik).length).toBeGreaterThan(0);
  });

  it("Flutter SeoAnalysisService ile aynı eşikleri kullanır", () => {
    const dart = readFileSync(
      resolve(__dirname, "../../lib/services/seo_analysis_service.dart"),
      "utf8",
    );
    for (const esik of [
      BLOG_BASLIK_EN_AZ,
      BLOG_BASLIK_EN_FAZLA,
      BLOG_OZET_EN_AZ,
      BLOG_OZET_EN_FAZLA,
      BLOG_EN_AZ_KELIME,
    ]) {
      expect(dart, `Dart tarafında ${esik} eşiği yok`).toContain(String(esik));
    }
  });
});
