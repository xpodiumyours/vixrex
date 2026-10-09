import { describe, expect, it } from "vitest";
import { kategoriSec, otomatikOzellikler, faturaVaryantlari } from "@/lib/faturaOtomatikDoldur";

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

  it("kanıt yoksa kategori uydurmaz, kategori yoksa da boş döner", () => {
    expect(kategoriSec({ ad: "Xyz 123" }, KATEGORILER)).toBe("");
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


describe("fatura assorti varyantlari", () => {
  it("sekiz adet dort bedenin seceneklerini korur, beden basina stok uydurmaz", () => {
    const variants = faturaVaryantlari({ model: "16747", barkod: "", varyant: "", beden: "M/L/XL/XXL", stok: 8 });
    expect(variants?.map((v) => v.options.size)).toEqual(["M", "L", "XL", "XXL"]);
    expect(variants?.every((v) => !("stockQuantity" in v))).toBe(true);
  });
  it("tek bilinen varyantin gercek adedini korur", () => {
    const variants = faturaVaryantlari({ model: "16747", barkod: "", varyant: "Siyah", beden: "L", stok: 8 });
    expect(variants).toHaveLength(1);
    expect(variants?.[0].options).toEqual({ color: "Siyah", size: "L" });
    expect(variants?.[0].stockQuantity).toBe(8);
  });
  it("kaynakta olmayan renk beden kombinasyonlarini uydurmaz", () => {
    const variants = faturaVaryantlari({ model: "16747", barkod: "", varyant: "Siyah/Beyaz", beden: "M/L", stok: 8,
      kaynakVaryantlar: [
        { ad: "Siyah / M", barkod: "8690000000123", gorseller: [] },
        { ad: "Beyaz / L", barkod: "8690000000130", gorseller: [] },
      ],
    });
    expect(variants?.map((v) => v.options)).toEqual([{ color: "Siyah", size: "M" }, { color: "Beyaz", size: "L" }]);
    expect(variants?.every((v) => !("stockQuantity" in v))).toBe(true);
    expect(faturaVaryantlari({ model: "16747", barkod: "", varyant: "Siyah/Beyaz", beden: "M/L", stok: 8 })).toBeUndefined();
  });
});
