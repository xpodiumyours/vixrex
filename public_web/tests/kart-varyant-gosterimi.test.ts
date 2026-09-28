import { describe, expect, it } from "vitest";
import { buildProductCardFacts } from "../src/lib/productCardPresentation";

const giyimMetadata = {
  schemaVersion: 1,
  itemKind: "physical",
  templateKey: "fashion",
  attributes: [
    { key: "gender", value: "Erkek" },
    { key: "material", value: "%94 pamuk" },
  ],
};

const varyantlar = [
  { id: "v1", options: { color: "Siyah", size: "L" } },
  { id: "v2", options: { color: "Siyah", size: "M" } },
  { id: "v3", options: { color: "Beyaz", size: "L" } },
];

describe("ürün kartı varyantları gösterir", () => {
  it("beden ve renk seçenekleri kart etiketlerine girer", () => {
    const sonuc = buildProductCardFacts({
      brand: "Tutku Elit",
      metadata: giyimMetadata,
      variants: varyantlar,
      limit: 4,
    });

    const degerler = sonuc.ozellikler.map((ozellik) => ozellik.value).join(" | ");
    expect(degerler).toContain("Siyah");
    expect(degerler).toContain("Beyaz");
    expect(degerler).toMatch(/L/);
    expect(degerler).toMatch(/M/);
  });

  it("varyant yoksa kart eskisi gibi davranır", () => {
    const sonuc = buildProductCardFacts({ brand: "Tutku Elit", metadata: giyimMetadata });
    expect(sonuc.ozellikler.every((ozellik) => !ozellik.key.startsWith("variant:"))).toBe(true);
  });

  it("hizmet ürününde varyant etiketi eklenmez", () => {
    const sonuc = buildProductCardFacts({
      metadata: { schemaVersion: 1, itemKind: "service", templateKey: "service", attributes: [] },
      variants: varyantlar,
    });
    expect(sonuc.ozellikler.every((ozellik) => !ozellik.key.startsWith("variant:"))).toBe(true);
  });
});
