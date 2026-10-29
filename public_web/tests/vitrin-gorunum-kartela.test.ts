import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { vitrinGorunum } from "../src/lib/vitrinGorunum";

function kaynak(relative: string) {
  return readFileSync(fileURLToPath(new URL(`../${relative}`, import.meta.url)), "utf8");
}

describe("vitrin görünüm kartelası", () => {
  it("fiyat her yüzeyde beyaz ve aynı kaynaktan okunur", () => {
    expect(vitrinGorunum.fiyat.ana).toBe("text-white");
    expect(kaynak("src/components/ProductDetailExperienceBase.tsx")).toContain(
      "vitrinGorunum.fiyat.ana",
    );
    expect(kaynak("src/app/v/[slug]/ProductCatalog.tsx")).toContain("vitrinGorunum.fiyat.ana");
  });

  it("detay sayfası turuncu fiyat, serif başlık ve camgöbeği geçiş taşımaz", () => {
    const detay = kaynak("src/components/ProductDetailExperienceBase.tsx");
    expect(detay).not.toContain("#E8A87C");
    expect(detay).not.toContain("font-vitrin-display");
    expect(detay).not.toContain("to-cyan-500");
    expect(detay).toContain("vitrinGorunum.buton.whatsapp");
  });

  it("sipariş panelinde ve sepette tek buton dili kullanılır", () => {
    expect(kaynak("src/components/ProductCommercePanel.tsx")).not.toContain("from-blue-600");
    expect(kaynak("src/components/VitrinCartDock.tsx")).toContain(
      "vitrinGorunum.buton.whatsappDolu",
    );
  });

  it("ürün penceresi detayla aynı fiyatı ve sepet toplamını gösterir", () => {
    const pencere = kaynak("src/components/ProductQuickViewBase.tsx");
    expect(pencere).toContain("priceAmount={fiyatTutar}");
    expect(pencere).toContain("vitrinGorunum.fiyat.ana");
    expect(pencere).not.toContain("from-blue-600");
  });

  it("detay siparişi seçilen varyantla kurar, engel notu taşımaz", () => {
    const detay = kaynak("src/components/ProductDetailExperienceBase.tsx");
    expect(detay).toContain("<ProductCommercePanel");
    expect(detay).toContain("selectedVariantId={selectedVariant?.id ?? null}");
    expect(detay).toContain("cartEnabled={!isService && !tukendi}");
    expect(detay).not.toContain("Hızlı İncele ekranından");
  });

  it("kart fatura ürününde tek fotoğrafı kırpmadan ve birim fiyatla gösterir", () => {
    const kart = kaynak("src/app/v/[slug]/ProductCatalog.tsx");
    expect(kart).toContain("birimFiyatBilgisi(product.metadata, fiyatTutar)");
    expect(kart).toContain("contain={isLunaInvoiceProduct(product)}");
  });

  it("kart kategoriyi tek yerde, özellik satırında gösterir", () => {
    const kart = kaynak("src/app/v/[slug]/ProductCatalog.tsx");
    expect(kart).toContain('ozellik.key === "category"');
    expect(kart).toContain("const kartEtiketleri =");
    expect(kart).toContain("kartEtiketleri.map");
    expect(kart).toContain('${vitrinGorunum.rozet.gorsel} px-2.5 py-1 text-[10px] font-extrabold shadow-md`}>');
  });

  it("kırmızı yalnız indirim rozetinde kalır, kaldırma ve silme nötrdür", () => {
    expect(vitrinGorunum.rozet.gorsel).toContain("bg-red-600");
    expect(kaynak("src/components/VitrinCartDock.tsx")).not.toContain("text-red-");
    expect(kaynak("src/components/ProductCommercePanel.tsx")).not.toContain("text-red-");
  });
});
