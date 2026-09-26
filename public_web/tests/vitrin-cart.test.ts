import { describe, expect, it } from "vitest";
import {
  buildWhatsappOrderUrl,
  cartTotalQuantity,
  mergeCartItem,
  type VitrinCartItem,
} from "@/lib/vitrinCart";

const temel: VitrinCartItem = {
  productSlug: "siyah-tisort",
  productName: "Siyah Tişört",
  variantKey: "m-siyah",
  variantText: "Beden: M, Renk: Siyah",
  priceText: "499 TL",
  imageUrl: null,
  maxQuantity: 10,
  quantity: 1,
};

describe("Vitrin sepeti", () => {
  it("aynı ürün ve varyantı ikinci satır açmadan adet olarak birleştirir", () => {
    const sonuc = mergeCartItem([temel], { ...temel, quantity: 2 });
    expect(sonuc).toHaveLength(1);
    expect(sonuc[0].quantity).toBe(3);
  });

  it("farklı varyantı ayrı satır tutar", () => {
    const sonuc = mergeCartItem([temel], {
      ...temel,
      variantKey: "l-siyah",
      variantText: "Beden: L, Renk: Siyah",
    });
    expect(sonuc).toHaveLength(2);
  });

  it("WhatsApp siparişinde ürün, varyant ve adedi taşır", () => {
    const url = buildWhatsappOrderUrl("https://wa.me/905551234567", "Aymira Butik", [
      { ...temel, quantity: 2 },
    ]);
    const parsed = new URL(url!);
    const text = parsed.searchParams.get("text") || "";
    expect(text).toContain("Aymira Butik");
    expect(text).toContain("2 × Siyah Tişört");
    expect(text).toContain("Beden: M, Renk: Siyah");
    expect(text).toContain("Toplam ürün adedi: 2");
  });

  it("stok tavanının üzerinde adet oluşturmaz", () => {
    const sonuc = mergeCartItem(
      [{ ...temel, quantity: 4, maxQuantity: 5 }],
      { ...temel, quantity: 4, maxQuantity: 5 },
    );
    expect(sonuc[0].quantity).toBe(5);
  });

  it("aynı ürün tekrar eklenince güncel fiyat ve stok anlık görüntüsünü kullanır", () => {
    const sonuc = mergeCartItem(
      [{ ...temel, priceText: "399 TL", maxQuantity: 8 }],
      { ...temel, priceText: "499 TL", maxQuantity: 5 },
    );
    expect(sonuc[0].priceText).toBe("499 TL");
    expect(sonuc[0].maxQuantity).toBe(5);
  });

  it("toplam adedi satır sayısından değil miktarlardan hesaplar", () => {
    expect(cartTotalQuantity([{ ...temel, quantity: 2 }, { ...temel, variantKey: "x", quantity: 3 }])).toBe(5);
  });
});
