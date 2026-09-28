import { describe, expect, it } from "vitest";
import {
  buildVariantOptionGroups,
  findMatchingVariant,
  variantOptionIsAvailable,
} from "../src/lib/productCardPresentation";
import {
  formatVariantPrice as detailFormatVariantPrice,
  stockTone as detailStockTone,
  whatsappWithVariantSelection,
} from "../src/components/ProductDetailExperienceBase";
import {
  formatVariantPrice as quickFormatVariantPrice,
  stockTone as quickStockTone,
  productWhatsappUrl,
} from "../src/components/ProductQuickViewBase";

const UC_LU_URUN_VARYANTLARI = [
  {
    id: "siyah-m",
    options: { color: "Siyah", size: "M" },
    priceAmount: 749,
    stockQuantity: 4,
    stockStatus: "Stokta",
  },
  {
    id: "siyah-l",
    options: { color: "Siyah", size: "L" },
    priceAmount: 779,
    stockQuantity: 0,
    stockStatus: "Stokta",
  },
  {
    id: "beyaz-m",
    options: { color: "Beyaz", size: "M" },
    priceAmount: 759,
    stockQuantity: 2,
    stockStatus: "Son 2 adet",
  },
];

function selectedVariantTextFromGruplar(
  gruplar: ReturnType<typeof buildVariantOptionGroups>,
  secilenler: Record<string, string>,
): string {
  return gruplar
    .map((grup) => {
      const value = secilenler[grup.key];
      return value ? `${grup.label}: ${value}` : null;
    })
    .filter((value): value is string => Boolean(value))
    .join(", ");
}

describe("ürün detay sayfası: beden/renk seçimi gerçek davranışı", () => {
  it("Siyah + L seçildiğinde tükenmiş varyant eşleşir ve fiyatı/stok tonu değişir", () => {
    const gruplar = buildVariantOptionGroups(UC_LU_URUN_VARYANTLARI, "fashion");
    const secilenler = { color: "Siyah", size: "L" };
    const varyant = findMatchingVariant(UC_LU_URUN_VARYANTLARI, secilenler, "fashion");

    expect(varyant?.id).toBe("siyah-l");
    expect(varyant?.stockQuantity).toBe(0);
    expect(detailFormatVariantPrice(varyant!.priceAmount!, "TRY")).toContain("779");
    expect(detailStockTone("Tükendi")).toBe("text-red-300");

    const metin = selectedVariantTextFromGruplar(gruplar, secilenler);
    expect(metin).toBe("Renk: Siyah, Beden: L");

    const whatsapp = whatsappWithVariantSelection(
      "https://wa.me/905551112233?text=Merhaba",
      metin,
    );
    expect(whatsapp).not.toBeNull();
    const parsed = new URL(whatsapp!);
    expect(parsed.searchParams.get("text")).toBe("Merhaba\nSeçenek: Renk: Siyah, Beden: L");
  });

  it("Beyaz + M seçildiğinde farklı varyant, farklı fiyat ve düşük stok tonu görünür", () => {
    const gruplar = buildVariantOptionGroups(UC_LU_URUN_VARYANTLARI, "fashion");
    const secilenler = { color: "Beyaz", size: "M" };
    const varyant = findMatchingVariant(UC_LU_URUN_VARYANTLARI, secilenler, "fashion");

    expect(varyant?.id).toBe("beyaz-m");
    expect(varyant?.stockQuantity).toBe(2);
    expect(detailFormatVariantPrice(varyant!.priceAmount!, "TRY")).toContain("759");
    expect(detailStockTone(varyant!.stockStatus)).toBe("text-amber-300");

    const metin = selectedVariantTextFromGruplar(gruplar, secilenler);
    expect(metin).toBe("Renk: Beyaz, Beden: M");

    const whatsapp = whatsappWithVariantSelection("https://wa.me/905551112233", metin);
    const parsed = new URL(whatsapp!);
    expect(parsed.searchParams.get("text")).toBe("Seçenek: Renk: Beyaz, Beden: M");
  });

  it("var olmayan Beyaz + L kombinasyonu seçilemez işaretlenir", () => {
    expect(
      variantOptionIsAvailable(
        UC_LU_URUN_VARYANTLARI,
        { color: "Beyaz", size: "" },
        "size",
        "L",
        "fashion",
      ),
    ).toBe(false);
    expect(findMatchingVariant(UC_LU_URUN_VARYANTLARI, { color: "Beyaz", size: "L" }, "fashion")).toBeNull();
  });
});

describe("hızlı incele penceresi: beden/renk seçimi gerçek davranışı", () => {
  it("Siyah + M seçiminde WhatsApp mesajına seçilen seçenek satırı eklenir", () => {
    const gruplar = buildVariantOptionGroups(UC_LU_URUN_VARYANTLARI, "fashion");
    const secilenler = { color: "Siyah", size: "M" };
    const varyant = findMatchingVariant(UC_LU_URUN_VARYANTLARI, secilenler, "fashion");

    expect(varyant?.id).toBe("siyah-m");
    expect(varyant?.stockQuantity).toBe(4);
    expect(quickFormatVariantPrice(varyant!.priceAmount!, "TRY")).toContain("749");
    expect(quickStockTone(varyant!.stockStatus)).toBe("text-emerald-300");

    const metin = selectedVariantTextFromGruplar(gruplar, secilenler);
    const url = productWhatsappUrl(
      "https://wa.me/905551112233",
      "Test Mağaza",
      "Kadın Ceket",
      false,
      metin,
    );

    expect(url).not.toBeNull();
    const decoded = decodeURIComponent(new URL(url!).searchParams.get("text") || "");
    expect(decoded).toBe(
      'Merhaba, Test Mağaza vitrininizdeki "Kadın Ceket" ürünü hakkında bilgi almak istiyorum.\nSeçenek: Renk: Siyah, Beden: M',
    );
  });

  it("seçim değiştiğinde WhatsApp mesajındaki seçenek satırı da değişir", () => {
    const gruplar = buildVariantOptionGroups(UC_LU_URUN_VARYANTLARI, "fashion");
    const ilkMetin = selectedVariantTextFromGruplar(gruplar, { color: "Siyah", size: "M" });
    const ikinciMetin = selectedVariantTextFromGruplar(gruplar, { color: "Beyaz", size: "M" });

    const ilkUrl = productWhatsappUrl(
      "https://wa.me/905551112233",
      "Test Mağaza",
      "Kadın Ceket",
      false,
      ilkMetin,
    );
    const ikinciUrl = productWhatsappUrl(
      "https://wa.me/905551112233",
      "Test Mağaza",
      "Kadın Ceket",
      false,
      ikinciMetin,
    );

    expect(ilkUrl).not.toBe(ikinciUrl);
    expect(decodeURIComponent(ilkUrl || "")).toContain("Seçenek: Renk: Siyah, Beden: M");
    expect(decodeURIComponent(ikinciUrl || "")).toContain("Seçenek: Renk: Beyaz, Beden: M");
  });
});
