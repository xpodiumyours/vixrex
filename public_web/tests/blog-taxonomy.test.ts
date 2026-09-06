import { describe, expect, it } from "vitest";
import { BUSINESS_CATEGORIES } from "@/lib/businessCategories";
import {
  BLOG_LOCATION_SCOPES,
  BLOG_PURPOSES,
  BLOG_TAXONOMY_RULES,
  BLOG_TOPICS,
  blogSectorFromUrl,
  blogSectorUrl,
  normalizeBlogTags,
  validBlogPurpose,
  validBlogSectorIds,
  validBlogTopic,
} from "@/lib/blogTaxonomy";

describe("Vixrex merkezi blog taksonomisi", () => {
  it("7 konu ve 7 kullanım amacı tek sözleşmeden gelir", () => {
    expect(BLOG_TOPICS).toHaveLength(7);
    expect(BLOG_PURPOSES).toHaveLength(7);
    expect(new Set(BLOG_TOPICS.map((item) => item.id)).size).toBe(7);
    expect(new Set(BLOG_PURPOSES.map((item) => item.id)).size).toBe(7);
  });

  it("sektör sözlüğünü çoğaltmaz; mevcut 19 kanonik ID'yi kullanır", () => {
    expect(BUSINESS_CATEGORIES).toHaveLength(19);
    expect(validBlogSectorIds(BUSINESS_CATEGORIES.map((item) => item.id))).toBe(true);
    expect(validBlogSectorIds(["uydurma-sektor"])).toBe(false);
  });

  it("konu ve amaç kimlikleri kontrollüdür", () => {
    expect(validBlogTopic("google-yerel-gorunurluk")).toBe(true);
    expect(validBlogPurpose("musteri-kazanma")).toBe(true);
    expect(validBlogTopic("serbest-konu")).toBe(false);
    expect(validBlogPurpose("serbest-amac")).toBe(false);
  });

  it("konum kapsamı yalnız national/province/district olabilir", () => {
    expect(BLOG_LOCATION_SCOPES).toEqual(["national", "province", "district"]);
  });

  it("etiketleri normalize eder, tekilleştirir ve 8 ile sınırlar", () => {
    const tags = normalizeBlogTags([
      "Google İşletme",
      "Google İşletme",
      "Yerel SEO",
      "Kuaför",
      "Harita",
      "Müşteri",
      "WhatsApp",
      "Vitrin",
      "İstanbul",
      "Fazla Etiket",
    ]);
    expect(tags.length).toBe(BLOG_TAXONOMY_RULES.maxTagsPerArticle);
    expect(new Set(tags).size).toBe(tags.length);
    expect(tags).toContain("google-işletme");
  });

  it("sektör URL dönüşümü mevcut kategori kimliğiyle birebir geri döner", () => {
    const kategori = BUSINESS_CATEGORIES.find((item) => item.id === "kafe_lokanta");
    expect(kategori).toBeTruthy();
    const url = blogSectorUrl("kafe_lokanta");
    expect(url).toBe("kafe-lokanta");
    expect(blogSectorFromUrl(url)?.id).toBe("kafe_lokanta");
  });
});
