import { describe, expect, it } from "vitest";
import { blogSeoAnalizi } from "@/lib/blogSeo";

describe("Flutter ve web ortak blog SEO ölçütleri", () => {
  it("tam içerik için Flutter ile aynı 95 puanı üretir", () => {
    const content = `İstanbul saç bakımı ${"faydalı içerik ".repeat(300)}`;
    const result = blogSeoAnalizi({
      title: "İstanbul saç bakımı için kapsamlı rehber",
      summary:
        "İstanbul'da saç bakımı yaptırmadan önce bilmeniz gereken temel noktaları bu rehberde topladık.",
      content,
      topic: "saç bakımı",
      city: "İstanbul",
      hasCover: true,
    });

    expect(result).toEqual({ score: 95, recommendations: [] });
  });

  it("boş yazıda puan vermez ve eksikleri açıkça söyler", () => {
    const result = blogSeoAnalizi({
      title: "",
      summary: "",
      content: "",
      topic: "",
      city: "",
      hasCover: false,
    });

    expect(result.score).toBe(0);
    expect(result.recommendations).toHaveLength(5);
  });
});
