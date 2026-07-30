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
const catalogSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/ProductCatalog.tsx"),
  "utf-8"
);

describe("Dilim 3–8 Atmosfer yükseltme", () => {
  it("Hakkımızda / galeri / SSS prop’larını bağlar", () => {
    expect(pageSource).toContain("aboutSection={aboutSection}");
    expect(pageSource).toContain("gallerySection={gallerySection}");
    expect(pageSource).toContain("faqItems={faqItems}");
    expect(viewSource).toContain('id="hakkimizda"');
    expect(viewSource).toContain('id="galeri"');
    expect(viewSource).toContain('id="sss"');
    expect(viewSource).toContain("showAbout &&");
    expect(viewSource).toContain("showGallery &&");
    expect(viewSource).toContain("showFaq &&");
  });

  it("ürün kartında fulfillmentRegion gösterir", () => {
    expect(catalogSource).toContain("product.fulfillmentRegion");
  });

  it("puan ve yol tarifi anahtarlarını uygular", () => {
    expect(pageSource).toContain("showDirectionsLink");
    expect(pageSource).toContain("showStorefrontRating");
    expect(viewSource).toContain("showRating");
    expect(viewSource).toContain("showContact &&");
    expect(viewSource).toContain("productCount > 0 &&");
  });

  it("sahte demo içerik göstermez", () => {
    expect(viewSource).not.toContain("4.9 (128 değerlendirme)");
    expect(viewSource).not.toContain("merhaba@${storeSlug}.com");
    expect(viewSource).not.toContain("Sonbahar / Kış Koleksiyonu");
  });
});
