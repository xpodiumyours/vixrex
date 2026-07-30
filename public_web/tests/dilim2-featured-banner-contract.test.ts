import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

const pageSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/page.tsx"),
  "utf-8"
);
const viewSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
  "utf-8"
);

describe("Dilim 2 öne çıkan kampanya bandı", () => {
  it("page featuredBanner prop’unu view’a geçirir", () => {
    expect(pageSource).toContain("featuredBanner={featuredBanner}");
    expect(pageSource).toContain("featured_banner_label");
    expect(pageSource).toContain("featured_banner_title");
  });

  it("view sahte kampanya metni göstermez; boşsa gizler", () => {
    expect(viewSource).toContain("showFeaturedBanner &&");
    expect(viewSource).toContain("featuredBanner");
    expect(viewSource).not.toContain("Sonbahar / Kış Koleksiyonu");
    expect(viewSource).not.toContain("349 TL");
    expect(viewSource).not.toContain("Yeni Sezon");
  });
});
