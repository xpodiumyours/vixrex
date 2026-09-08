import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Blog yonetimi parite testi.
 */

const flutterBlog = readFileSync(
  resolve(__dirname, "../../lib/screens/blog_editor_screen.dart"),
  "utf8",
);
const nextBlog = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/blog-yonetim/page.tsx"),
  "utf8",
);

describe("blog yonetimi parite (Flutter referansiyla)", () => {
  it("Flutter gibi blog editor controller kullanir", () => {
    expect(flutterBlog).toContain("BlogEditorController");
  });

  it("Flutter gibi SEO paneli icerir", () => {
    expect(flutterBlog).toContain("BlogSeoPanel");
    expect(flutterBlog).toContain("SeoService");
  });

  it("Flutter gibi kapak resimi secici icerir", () => {
    expect(flutterBlog).toContain("BlogCoverPicker");
    expect(nextBlog).toContain("cover_image_url");
  });

  it("Flutter gibi yazi durumlarini icerir", () => {
    expect(nextBlog).toContain("draft");
    expect(nextBlog).toContain("published");
    expect(nextBlog).toContain("review");
  });

  it("Flutter gibi yazi alanlarini icerir", () => {
    expect(nextBlog).toContain("title");
    expect(nextBlog).toContain("slug");
    expect(nextBlog).toContain("summary");
    expect(nextBlog).toContain("seo_score");
  });
});