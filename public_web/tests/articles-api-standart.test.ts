import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const articlesApi = readFileSync(
  resolve(__dirname, "../src/app/api/articles/route.ts"),
  "utf8",
);
const asistanApiYolu = resolve(
  __dirname,
  "../src/app/api/articles/assistant/route.ts",
);
const yonetimSayfasi = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/blog-yonetim/page.tsx"),
  "utf8",
);
const editorSayfasi = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/blog-yonetim/[articleSlug]/page.tsx"),
  "utf8",
);

describe("blog SEO standardı sunucuda ölçülür", () => {
  it("puanı istemciden almaz, alanlardan hesaplar", () => {
    expect(articlesApi).toContain("blogSeoAnalizi");
    expect(articlesApi).not.toContain("govde.seoScore");
    expect(articlesApi).not.toContain("govde.seoErrors");
  });

  it("yayını yapısal standarda bağlar", () => {
    expect(articlesApi).toContain("blogYayinEngelleri");
    expect(articlesApi).toContain("Yayın standardı tamamlanmadı");
  });

  it("sahip kontrolünü ortak korumadan alır", () => {
    expect(articlesApi).toContain("sahipDogrula");
    expect(existsSync(asistanApiYolu), "asistan API'si yok").toBe(true);
    const asistanApi = readFileSync(asistanApiYolu, "utf8");
    expect(asistanApi).toContain("sahipDogrula");
    expect(asistanApi).toContain('status: "draft"');
    expect(asistanApi).toContain("blogTaslagiUret");
  });

  it("sahip yüzeyi asistanı kullanır ve standardı yayından önce gösterir", () => {
    expect(yonetimSayfasi).toContain("/api/articles/assistant");
    expect(editorSayfasi).toContain("blogYayinEngelleri");
    expect(editorSayfasi).toContain("Yayın standardı");
  });
});
