import { describe, expect, it } from "vitest";
import { urunGirdisiniHazirla } from "../src/lib/productIntake";

function sahteAdmin(templateKey: string | null) {
  return {
    from() {
      return {
        select() {
          return {
            eq() {
              return {
                eq() {
                  return {
                    async maybeSingle() {
                      if (!templateKey) return { data: null, error: null };
                      return {
                        data: { id: "kategori-1", product_template_key: templateKey },
                        error: null,
                      };
                    },
                  };
                },
              };
            },
          };
        },
      };
    },
  } as never;
}

const giyimSatiri = {
  name: "Elit Erkek Elastan Sıfır Yaka Uzun Kol",
  priceText: "199 TL",
  categoryId: "kategori-1",
  imageUrls: [
    "https://tedarikci.example.com/elt1302-1.jpg",
    "https://tedarikci.example.com/elt1302-2.jpg",
    "https://tedarikci.example.com/elt1302-3.jpg",
  ],
  barcode: "8681128321677",
  variants: [{ id: "v1", options: { color: "Siyah", size: "L" } }],
  metadata: {
    attributes: [
      { key: "gender", value: "Erkek" },
      { key: "fit", value: "Normal" },
    ],
  },
};

describe("toplu ürün kapısı tekli ürünle aynı kalite zincirinden geçer", () => {
  it("beden ve renk seçenekleri toplu yolda da korunur", async () => {
    const sonuc = await urunGirdisiniHazirla({
      admin: sahteAdmin("fashion"),
      storeId: "vitrin-1",
      storeName: "Deneme Butik",
      govde: giyimSatiri,
      gorselPolitikasi: "toplu",
    });

    expect(sonuc.durum).toBe("hazir");
    if (sonuc.durum === "reddedildi") return;
    expect(sonuc.girdi.metadata.templateKey).toBe("fashion");
    expect(sonuc.girdi.variants).toHaveLength(1);
    expect(sonuc.girdi.variants[0].options).toMatchObject({ color: "Siyah", size: "L" });
    expect(sonuc.girdi.barcode).toBe("8681128321677");
  });

  it("zorunlu alanı eksik satır reddedilmez, taslak olarak döner", async () => {
    const sonuc = await urunGirdisiniHazirla({
      admin: sahteAdmin("fashion"),
      storeId: "vitrin-1",
      storeName: "Deneme Butik",
      govde: { ...giyimSatiri, metadata: { attributes: [] } },
      gorselPolitikasi: "toplu",
    });

    expect(sonuc.durum).toBe("taslak");
    if (sonuc.durum !== "taslak") return;
    expect(sonuc.eksik.length).toBeGreaterThan(0);
    expect(sonuc.girdi.variants).toHaveLength(1);
  });

  it("tek fotoğraflı satır atılmaz, fotoğraf eksiğiyle taslak olur", async () => {
    const sonuc = await urunGirdisiniHazirla({
      admin: sahteAdmin("fashion"),
      storeId: "vitrin-1",
      storeName: "Deneme Butik",
      govde: { ...giyimSatiri, imageUrls: ["https://tedarikci.example.com/elt1302-1.jpg"] },
      gorselPolitikasi: "toplu",
    });

    expect(sonuc.durum).toBe("taslak");
    if (sonuc.durum !== "taslak") return;
    expect(sonuc.eksik).toContain("fotoğraf");
    expect(sonuc.girdi.imageUrls).toHaveLength(1);
  });

  it("başka vitrinin kategorisi kabul edilmez", async () => {
    const sonuc = await urunGirdisiniHazirla({
      admin: sahteAdmin(null),
      storeId: "vitrin-1",
      storeName: "Deneme Butik",
      govde: giyimSatiri,
      gorselPolitikasi: "toplu",
    });

    expect(sonuc.durum).toBe("reddedildi");
  });

  it("sahip formunda dış bağlantılı görsel kabul edilmez, toplu yolda edilir", async () => {
    const toplu = await urunGirdisiniHazirla({
      admin: sahteAdmin("fashion"),
      storeId: "vitrin-1",
      storeName: "Deneme Butik",
      govde: giyimSatiri,
      gorselPolitikasi: "toplu",
    });
    const sahip = await urunGirdisiniHazirla({
      admin: sahteAdmin("fashion"),
      storeId: "vitrin-1",
      storeName: "Deneme Butik",
      govde: giyimSatiri,
      gorselPolitikasi: "sahip",
    });

    expect(toplu.durum).not.toBe("reddedildi");
    expect(sahip.durum).toBe("reddedildi");
  });
});
