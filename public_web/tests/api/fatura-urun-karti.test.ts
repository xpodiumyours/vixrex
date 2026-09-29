import { describe, expect, it } from "vitest";
import type { EslesmisFaturaSatiri } from "@/lib/faturaEslestir";
import { faturaSatiriniKartaDonustur, faturaSatirlariniKartlaraDonustur } from "@/lib/faturaUrunKarti";

function satir(args: {
  firma?: string;
  model?: string;
  barkod?: string;
  izin?: "yok" | "bekliyor" | "var";
  gorseller?: string[];
  eslesmis?: boolean;
}): EslesmisFaturaSatiri {
  const model = args.model ?? "SKU-101";
  const barkod = args.barkod ?? "8680000000101";
  return {
    model,
    ad: "Fatura adı",
    barkod,
    varyant: "Lacivert",
    beden: "L",
    adet: 8,
    alisBirimFiyat: 450,
    satirToplam: 3600,
    guven: 0.9,
    katalog:
      args.eslesmis === false
        ? null
        : {
            firma: args.firma ?? "Rastgele Tedarikçi A.Ş.",
            dayanak: barkod ? "barkod" : "kod",
            izinDurumu: args.izin ?? "var",
            resmiAd: "Doğrulanmış Ürün Adı",
            marka: "Doğrulanmış Marka",
            aciklama: "Resmî ürün açıklaması",
            gorseller: args.gorseller ?? ["https://example.com/1.jpg", "https://example.com/2.jpg"],
            kaynak: "https://example.com/products/sku-101",
          },
  };
}

describe("fatura eşleşmesini ürün kartına dönüştürme", () => {
  it("eşleşen ürünü doğrudan taslak ürün kartına dönüştürür", () => {
    const kart = faturaSatiriniKartaDonustur(satir({}));
    expect(kart.eslesmeDurumu).toBe("eslesti");
    expect(kart.name).toBe("Doğrulanmış Ürün Adı");
    expect(kart.brand).toBe("Doğrulanmış Marka");
    expect(kart.imageUrls).toHaveLength(2);
    expect(kart.sourceType).toBe("invoice");
    expect(kart.externalProductId).toBe("8680000000101");
    expect(kart.metadata.identifiers?.sku).toBe("SKU-101");
    expect(kart.stockQuantity).toBe(8);
    expect(kart.purchasePriceAmount).toBe(450);
    expect(kart.variants[0].options).toEqual({ color: "Lacivert", size: "L" });
    expect(kart.isVisible).toBe(false);
  });

  it("görsel izni olmayan eşleşmede kartı taslak hazırlar ama görsel eksikliğini taşır", () => {
    const kart = faturaSatiriniKartaDonustur(satir({ izin: "bekliyor", gorseller: [] }));
    expect(kart.eslesmeDurumu).toBe("eslesti");
    expect(kart.imageUrls).toEqual([]);
    expect(kart.eksikler.join(" ")).toContain("görsel kullanım izni");
    expect(kart.isVisible).toBe(false);
  });

  it("eşleşmeyen satır için ürün uydurmaz ve kartı kayda hazır saymaz", () => {
    const kart = faturaSatiriniKartaDonustur(satir({ eslesmis: false, model: "BILINMEYEN-7", barkod: "" }));
    expect(kart.eslesmeDurumu).toBe("eslesmedi");
    expect(kart.name).toBe("Fatura adı");
    expect(kart.imageUrls).toEqual([]);
    expect(kart.eksikler).toContain("Dijital ürün eşleşmesi bulunamadı.");
    expect(kart.isVisible).toBe(false);
  });

  it("firma adına özel kod olmadan farklı firmaların eşleşmelerini aynı kart sözleşmesine çevirir", () => {
    const firmalar = ["Rastgele Tekstil", "Rastgele Gıda", "Rastgele Kozmetik"];
    const kartlar = faturaSatirlariniKartlaraDonustur(
      firmalar.map((firma, index) =>
        satir({ firma, model: `SKU-${index + 1}`, barkod: `868000000010${index + 1}` }),
      ),
    );
    expect(kartlar).toHaveLength(3);
    expect(new Set(kartlar.map((kart) => kart.katalog?.firma))).toEqual(new Set(firmalar));
    expect(kartlar.every((kart) => kart.eslesmeDurumu === "eslesti")).toBe(true);
    expect(kartlar.every((kart) => kart.isVisible === false)).toBe(true);
  });
});
