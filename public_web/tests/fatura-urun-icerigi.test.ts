import { describe, expect, it } from "vitest";
import { faturaKatalogMetadatasi } from "@/lib/faturaUrunIcerigi";
import { normalizeProductMetadata } from "@/lib/productRichData";
import { buildProductDetailFacts } from "@/lib/productCardPresentation";
import { katalogJsonunuOku } from "@/lib/faturaGoru";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";

const source = {
  uretici: "Örnek Üretici A.Ş.", gramaj: "175 g",
  kaynak: "https://manufacturer.example/product", dogrulamaDurumu: "? Belirsiz",
  ozellikler: [
    { key: "ingredients", label: "İçindekiler", value: "Kaynakta yazan içerik" },
    { key: "allergens", label: "Alerjenler", value: ["Buğday", "Süt"] },
    { key: "energy", label: "Enerji", value: 125, unit: "kcal", section: "Besin değerleri" },
    { key: "storage", label: "Saklama", value: "Kaynakta yazan saklama bilgisi" },
  ],
};

describe("OpenRouter katalog bilgisi → profesyonel ürün kartı", () => {
  it("JSON'dan başlayıp katalog ve tüketici kartına kadar liste/sayı/birim taşınır", () => {
    const parsed = katalogJsonunuOku(JSON.stringify({ satirlar: [{
      ad: "Test ürün", uretici: source.uretici, gramaj: source.gramaj,
      site_sayfa: source.kaynak, dogrulama_durumu: source.dogrulamaDurumu,
      ozellikler: source.ozellikler,
    }] }));
    const row = faturaSatiriniAktar(parsed.satirlar[0], "Test toptancı");
    const facts = buildProductDetailFacts({ metadata: faturaKatalogMetadatasi(row.katalog ?? {}) });
    expect(facts).toEqual(expect.arrayContaining([
      { key: "energy", label: "Enerji", value: "125 kcal" },
      { key: "allergens", label: "Alerjenler", value: "Buğday, Süt" },
    ]));
    expect(row.sonuc).toBe("eksik");
  });
  it("üretici ve gramaj yalnız üst alanlarda gelse de tüketici özelliklerine taşınır", () => {
    const metadata = faturaKatalogMetadatasi({ ...source, ozellikler: [] });
    expect(metadata.attributes).toEqual(expect.arrayContaining([
      { key: "manufacturer", label: "Üretici", value: source.uretici },
      { key: "netQuantity", label: "Gramaj / hacim", value: "175 g" },
    ]));
    expect(normalizeProductMetadata(metadata).manufacturerSource).toEqual({
      url: source.kaynak, verificationStatus: "? Belirsiz",
    });
  });
  it("bütün gelen özellikler, birimleri ve sayısal/liste değerleri kaybolmadan sunulur", () => {
    const metadata = faturaKatalogMetadatasi(source);
    const facts = buildProductDetailFacts({ metadata });
    expect(facts).toEqual(expect.arrayContaining([
      { key: "ingredients", label: "İçindekiler", value: "Kaynakta yazan içerik" },
      { key: "allergens", label: "Alerjenler", value: "Buğday, Süt" },
      { key: "energy", label: "Enerji", value: "125 kcal" },
      { key: "netQuantity", label: "Gramaj / hacim", value: "175 g" },
    ]));
  });
  it("aynı gramajı iki kez eklemez, farklı gelen değerlerden doğru olanı seçmez", () => {
    const same = faturaKatalogMetadatasi({ gramaj: "175 g", ozellikler: [{ key: "netQuantity", value: "175 g" }] });
    expect(same.attributes).toHaveLength(1);
    const different = faturaKatalogMetadatasi({ gramaj: "175 g", ozellikler: [{ key: "netQuantity", value: "450 g" }] });
    expect(different.attributes?.map((attribute) => attribute.value)).toEqual(["450 g", "175 g"]);
  });
  it("eksik üretici, gramaj, içerik veya resmî kaynak uydurmaz", () => {
    const metadata = faturaKatalogMetadatasi({});
    expect(metadata.attributes).toBeUndefined();
    expect(metadata.manufacturerSource).toBeUndefined();
    expect(buildProductDetailFacts({ metadata })).toEqual([]);
  });
  it("faturanın alış fiyatı, tedarikçisi, vergi numarası otomatik tüketici alanı olmaz", () => {
    const raw = { ...source, alisBirimFiyat: 20, tedarikci: "Özel Toptancı", tedarikciVergiNo: "TEST-PRIVATE" };
    const serialized = JSON.stringify(faturaKatalogMetadatasi(raw));
    expect(serialized).not.toContain("alisBirimFiyat");
    expect(serialized).not.toContain("Özel Toptancı");
    expect(serialized).not.toContain("TEST-PRIVATE");
  });
});
