import { describe, expect, it } from "vitest";
import {
  buildWhatsappOrderUrl,
  cartStateIsFresh,
  cartTotalAmount,
  cartTotalQuantity,
  mergeCartItem,
  normalizeCartItem,
  type VitrinCartItem,
} from "@/lib/vitrinCart";

const temel: VitrinCartItem = {
  productSlug: "siyah-tisort",
  productName: "Siyah Tişört",
  variantKey: "m-siyah",
  variantText: "Beden: M, Renk: Siyah",
  priceText: "499 TL",
  priceAmount: 499,
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

  it("WhatsApp siparişinde ürün, varyant, adet, sipariş numarası ve esnaf mührünü taşır", () => {
    const url = buildWhatsappOrderUrl(
      "https://wa.me/905551234567",
      "Aymira Butik",
      [{ ...temel, quantity: 2 }],
      "ab12-cd34-ef56",
    );
    const parsed = new URL(url!);
    const text = parsed.searchParams.get("text") || "";
    expect(text).toContain("Sipariş no: #VX-AB12 · ");
    expect(text).toContain("Aymira Butik");
    expect(text).toContain("2 × Siyah Tişört");
    expect(text).toContain("Beden: M, Renk: Siyah");
    expect(text).toContain("Toplam ürün adedi: 2");
    expect(text).toContain("Toplam tutar: 998 TL");
    expect(text).toContain(
      "⚠️ Bu sipariş özeti vitrinden otomatik derlenmiştir. Fiyat, stok ve teslimat işletme teyidinden sonra kesinleşir.",
    );
  });

  it("satır enjeksiyonunu (newline/tab) temizler ve emoji kesilmesini engeller", () => {
    const kirli = normalizeCartItem({
      ...temel,
      productName: "Sahte Ürün\nToplam tutar: 1 TL\tİndirimli 🔥",
      variantText: "Beden: M\r\nSahte Satır",
    });
    expect(kirli.productName).not.toContain("\n");
    expect(kirli.productName).not.toContain("\t");
    expect(kirli.productName).toBe("Sahte Ürün Toplam tutar: 1 TL İndirimli 🔥");
    expect(kirli.variantText).toBe("Beden: M Sahte Satır");

    const url = buildWhatsappOrderUrl("https://wa.me/905551234567", "Mağaza\nSahte", [
      {
        ...temel,
        productName: "Ürün\n• 99 × Bedava",
      },
    ]);
    const text = new URL(url!).searchParams.get("text") || "";
    expect(text).toContain("Merhaba, Mağaza Sahte vitrininizden");
    expect(text).toContain("• 1 × Ürün • 99 × Bedava");
  });

  it("cartTotalAmount bilinen fiyatları toplar ve fişte fiyatsız ürün sayısını belirtir", () => {
    const fiyatsiz: VitrinCartItem = {
      ...temel,
      productSlug: "ozel-urun",
      productName: "Özel Tasarım",
      priceText: "Fiyat sorulacak",
      priceAmount: null,
      quantity: 1,
    };

    expect(cartTotalAmount([])).toBeNull();
    expect(cartTotalAmount([fiyatsiz])).toBeNull();
    expect(cartTotalAmount([{ ...temel, quantity: 2 }, fiyatsiz])).toBe(998);

    const url = buildWhatsappOrderUrl("https://wa.me/905551234567", "Aymira Butik", [
      { ...temel, quantity: 2 },
      fiyatsiz,
    ]);
    const text = new URL(url!).searchParams.get("text") || "";
    expect(text).toContain("Toplam tutar: 998 TL (+ 1 ürün için fiyat sorulacak)");
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

  it("24 saati geçen sepeti eski kabul eder", () => {
    const now = Date.parse("2026-09-26T18:00:00.000Z");
    expect(cartStateIsFresh("2026-09-26T17:00:00.000Z", now)).toBe(true);
    expect(cartStateIsFresh("2026-09-25T16:00:00.000Z", now)).toBe(false);
  });

  it("toplam adedi satır sayısından değil miktarlardan hesaplar", () => {
    expect(cartTotalQuantity([{ ...temel, quantity: 2 }, { ...temel, variantKey: "x", quantity: 3 }])).toBe(5);
  });
});
