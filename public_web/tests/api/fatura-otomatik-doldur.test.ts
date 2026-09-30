import { describe, expect, it } from "vitest";
import { kategoriSec, otomatikOzellikler } from "@/lib/faturaOtomatikDoldur";

const KATEGORILER = [
  { id: "genel", name: "Genel", product_template_key: "generic" },
  { id: "giyim", name: "Giyim", product_template_key: "fashion" },
  { id: "gida", name: "Gıda", product_template_key: "food" },
  { id: "ev", name: "Ev ve Temizlik", product_template_key: "home" },
];

describe("fatura satırı için otomatik kategori", () => {
  it("giyim ürünü giyim kategorisine girer", () => {
    expect(kategoriSec({ ad: "IŞILAY 16747 İnterlok Penye Erkek Takım" }, KATEGORILER)).toBe("giyim");
  });

  it("gıda ürünü gıda kategorisine girer", () => {
    expect(kategoriSec({ ad: "Eti Petibör Bisküvi 300 g" }, KATEGORILER)).toBe("gida");
  });

  it("temizlik ürünü ev kategorisine girer", () => {
    expect(kategoriSec({ ad: "Sıvı Deterjan 3 L" }, KATEGORILER)).toBe("ev");
  });

  it("tahmin edilemeyen ürün ilk kategoriye düşer, kategori yoksa boş döner", () => {
    expect(kategoriSec({ ad: "Xyz 123" }, KATEGORILER)).toBe("genel");
    expect(kategoriSec({ ad: "Bisküvi" }, [])).toBe("");
  });

  it("kategori adı üründe geçiyorsa o kategori seçilir", () => {
    expect(kategoriSec({ ad: "Gıda kolisi" }, KATEGORILER)).toBe("gida");
  });
});

describe("fatura satırı için otomatik özellik", () => {
  it("ürün adında cinsiyet yazıyorsa şablonun seçeneğiyle doldurulur", () => {
    expect(otomatikOzellikler({ ad: "Erkek İnterlok Takım" }, "fashion")).toEqual([
      { key: "gender", value: "erkek" },
    ]);
    expect(otomatikOzellikler({ ad: "Kadın Termal Atlet" }, "fashion")).toEqual([
      { key: "gender", value: "kadin" },
    ]);
  });

  it("adda yazmayan bilgi uydurulmaz", () => {
    expect(otomatikOzellikler({ ad: "İnterlok Takım" }, "fashion")).toEqual([]);
  });

  it("gıdada net miktar addan alınır", () => {
    expect(otomatikOzellikler({ ad: "Petibör Bisküvi 300 g" }, "food")).toEqual([
      { key: "netQuantity", value: "300 g" },
    ]);
  });

  it("şablonda olmayan özellik eklenmez", () => {
    expect(otomatikOzellikler({ ad: "Erkek Bisküvi 300 g" }, "food")).toEqual([
      { key: "netQuantity", value: "300 g" },
    ]);
    expect(otomatikOzellikler({ ad: "Erkek Takım 500 g" }, "generic")).toEqual([]);
  });
});
