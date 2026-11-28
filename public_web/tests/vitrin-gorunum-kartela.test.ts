import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import { vitrinGorunum } from "../src/lib/vitrinGorunum";
import {
  birimFiyatBilgisi,
  eskiFiyatYazisi,
  tutarYazisi,
} from "../src/lib/productCardPresentation";

vi.mock("next/navigation", () => ({
  useSearchParams: () => new URLSearchParams(),
  usePathname: () => "/v/ornek-magaza",
  useRouter: () => ({ push: vi.fn(), replace: vi.fn() }),
}));

vi.mock("next/image", () => ({
  default: (props: Record<string, unknown>) =>
    createElement("img", {
      src: String(props.src ?? ""),
      alt: String(props.alt ?? ""),
      className: String(props.className ?? ""),
    }),
}));

import ProductCatalog from "../src/app/v/[slug]/ProductCatalog";
import { TELIF_ANAHTARI } from "../src/components/ProductDetailExperienceBase";

function kaynak(relative: string) {
  return readFileSync(fileURLToPath(new URL(`../${relative}`, import.meta.url)), "utf8");
}

describe("vitrin görünüm kartelası", () => {
  it("fiyat her yüzeyde beyaz ve aynı kaynaktan okunur", () => {
    expect(vitrinGorunum.fiyat.ana).toBe("text-white");
    expect(kaynak("src/components/ProductSurfaceShared.tsx")).toContain(
      "vitrinGorunum.fiyat.ana",
    );
    expect(kaynak("src/components/ProductDetailExperienceBase.tsx")).toContain(
      "<ProductInfoBody",
    );
    expect(kaynak("src/components/ProductQuickViewBase.tsx")).toContain("<ProductInfoBody");
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
    expect(pencere).toContain("<ProductInfoBody");
    expect(kaynak("src/components/ProductSurfaceShared.tsx")).toContain("vitrinGorunum.fiyat.ana");
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
    expect(kart).toContain("object-contain");
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

  it("kart varyantlı üründe sepet doluyken bile seçenekler düğmesini korur, tekil üründe sepete ekle ve stok sınırı uygular", () => {
    const kart = kaynak("src/app/v/[slug]/ProductCatalog.tsx");
    expect(kart).toContain("Rafta Ayırt");
    expect(kart).toContain('aria-label="Seçenekleri gör"');
    expect(kart).toContain('aria-label="Sepete ekle"');
    expect(kart).toContain("productVariantCount(product.variants, metadata.templateKey) > 1");
    expect(kart).toContain("const matchingCartItems = cartItems.filter((item) => item.productSlug === productSlug);");
    expect(kart).toContain("const totalProductCartQty = matchingCartItems.reduce((acc, item) => acc + item.quantity, 0);");
    expect(kart).toContain("const stokSinirinda = maxQuantity != null && totalProductCartQty >= maxQuantity;");
    expect(kart).toContain("if (!trackingEnabled)");
  });

  it("ürün kartı koyu çerçevede 4/5 iç sahne ve kategori başlığında sabit 2 satır yüksekliği kullanır", () => {
    const kart = kaynak("src/app/v/[slug]/ProductCatalog.tsx");
    const profil = kaynak("src/app/v/[slug]/VitrinProfileView.tsx");
    const pencere = kaynak("src/components/ProductQuickViewBase.tsx");
    const detay = kaynak("src/components/ProductDetailExperienceBase.tsx");

    expect(kart).toContain('bg-[#08132D] p-2');
    expect(kart).toContain('aspect-[4/5]');
    expect(kart).not.toContain('"bg-white"');
    expect(kart).not.toContain("from-[#0B1120]/45");
    expect(profil).toContain('min-h-[2.5em] text-[15px] font-bold leading-tight text-white line-clamp-2');

    expect(pencere).toContain(
      '${!telifKalkanli && currentImage ? "bg-white" : "bg-slate-900"}',
    );
    expect(pencere).toContain("rounded-lg border bg-white transition");

    expect(detay).toContain(
      '${!telifKalkanli && currentImage ? "bg-white" : "bg-slate-950"}',
    );
    expect(detay).toContain("rounded-xl border bg-white transition");
  });

  it("fiyat biçimi iki kuruş basamağı ve ₺ simgesi üretir, geçersiz değerleri reddeder", () => {
    expect(tutarYazisi(1290)).toBe("1.290,00 ₺");
    expect(tutarYazisi(54.6)).toBe("54,60 ₺");
    expect(tutarYazisi(0)).toBe("Fiyat sorun");
    expect(tutarYazisi(-10)).toBe("Fiyat sorun");
    expect(tutarYazisi(Number.NaN)).toBe("Fiyat sorun");
    expect(eskiFiyatYazisi(1500)).toBe("1.500,00 ₺");
    expect(eskiFiyatYazisi(0)).toBeNull();
    expect(eskiFiyatYazisi(-120)).toBeNull();
    expect(eskiFiyatYazisi(Number.NaN)).toBeNull();
    expect(
      birimFiyatBilgisi(
        { attributes: [{ key: "netQuantity", value: "500 g" }] },
        64.5,
      ),
    ).toEqual({
      miktar: "500 g",
      birimFiyat: "129,00 ₺/kg",
    });
    expect(birimFiyatBilgisi({}, 100)).toBeNull();
  });

  it("ürün, hizmet, varyant, stoksuz, telif kalkanlı ve görselsiz kartları Kural 30 girdi-çıktı sınırlarıyla işler", () => {
    const html = renderToStaticMarkup(
      createElement(ProductCatalog, {
        storeSlug: "ornek-magaza",
        storeName: "Örnek Mağaza",
        whatsappBaseUrl: "https://wa.me/905551112233",
        trackingEnabled: false,
        categoryMap: [{ id: "cat-1", name: "Giyim" }],
        products: [
          {
            id: "u-1",
            slug: "keten-gomlek",
            name: "Keten Gömlek",
            brand: "Mavi",
            price: "1290 TL",
            priceAmount: 1290,
            oldPriceAmount: 1500,
            stockStatus: "Mevcut",
            stockQuantity: 4,
            category: "Giyim",
            categoryId: "cat-1",
            imageUrls: ["https://cdn.example/gomlek.jpg"],
            metadata: { itemKind: "physical", templateKey: "fashion" },
          },
          {
            id: "h-1",
            slug: "sac-kesimi",
            name: "Saç Kesimi ve Bakım",
            price: "54,6 TL",
            priceAmount: 54.6,
            imageUrls: ["https://cdn.example/sac.jpg"],
            metadata: {
              itemKind: "service",
              templateKey: "service",
              service: { serviceType: "Kuaför" },
            },
          },
          {
            id: "v-1",
            slug: "varyantli-tisort",
            name: "Pamuk Tişört",
            price: "350 TL",
            priceAmount: 350,
            stockQuantity: 5,
            imageUrls: ["https://cdn.example/tisort.jpg"],
            variants: [
              { id: "v1", options: { size: "S" }, stockQuantity: 2 },
              { id: "v2", options: { size: "M" }, stockQuantity: 3 },
            ],
            metadata: { itemKind: "physical", templateKey: "fashion" },
          },
          {
            id: "t-1",
            slug: "telifli-urun",
            name: "Telifli Ürün",
            price: "299 TL",
            priceAmount: 299,
            imageUrls: ["https://cdn.example/telif.jpg"],
            [TELIF_ANAHTARI]: true,
            metadata: { itemKind: "physical", templateKey: "generic" },
          },
          {
            id: "y-1",
            slug: "gorselsiz-tukendi",
            name: "Görselsiz Tükenen",
            price: "100 TL",
            priceAmount: 100,
            stockQuantity: 0,
            imageUrls: [],
            metadata: { itemKind: "physical", templateKey: "generic" },
          },
        ],
      }),
    );

    expect(html).toContain("bg-[#08132D] p-2");
    expect(html).toContain("aspect-[4/5]");
    expect(html).toContain("bg-[#0B1730]");
    expect(html).not.toContain("bg-[#F4F7FC]");
    expect(html).toContain("bg-[#112448]/70");
    expect(html).toContain("object-cover object-top");
    expect(html).toContain("object-contain p-3");
    expect(html).toContain("1.290,00 ₺");
    expect(html).toContain("1.500,00 ₺");
    expect(html).toContain("54,60 ₺");
    expect(html).toContain("Kuaför");
    expect(html).toContain("Rafta Ayırt");
    expect(html).toContain('aria-label="Sepete ekle"');
    expect(html).toContain("Hizmeti incele →");
    expect(html).toContain('aria-label="Seçenekleri gör"');
    expect(html).toContain("Tükendi");
    expect(html).toContain('aria-label="WhatsApp&#x27;tan Sor"');
    expect(html).toContain("https://wa.me/905551112233");
    expect(html).toContain("Fotoğraf üreticide");
    expect(html).not.toContain("telif.jpg");
    expect(html).toContain("flex-col gap-1.5");
    expect(html).toContain("Ürün görseli yok");

    const tekOzellikHtml = renderToStaticMarkup(
      createElement(ProductCatalog, {
        storeSlug: "ornek-magaza",
        storeName: "Örnek Mağaza",
        whatsappBaseUrl: null,
        trackingEnabled: false,
        categoryMap: [{ id: "cat-1", name: "Giyim" }],
        products: [
          {
            id: "u-3",
            slug: "tek-ozellik",
            name: "Keten Elbise",
            priceAmount: 890,
            category: "Giyim",
            categoryId: "cat-1",
            imageUrls: ["https://cdn.example/elbise.jpg"],
            metadata: {
              itemKind: "physical",
              templateKey: "fashion",
              attributes: [{ key: "color", value: "Siyah" }],
            },
          },
          {
            id: "h-2",
            slug: "hizmet-wapsiz",
            name: "Ekran Değişimi",
            priceAmount: 1200,
            imageUrls: [],
            metadata: {
              itemKind: "service",
              templateKey: "service",
            },
          },
        ],
      }),
    );

    expect(tekOzellikHtml).toContain("Giyim · Siyah");
    expect(tekOzellikHtml).toContain("Hizmeti incele →");
    expect(tekOzellikHtml).not.toContain('aria-label="WhatsApp&#x27;tan Sor"');

    const yalnizHizmetHtml = renderToStaticMarkup(
      createElement(ProductCatalog, {
        storeSlug: "ornek-magaza",
        storeName: "Örnek Mağaza",
        whatsappBaseUrl: null,
        trackingEnabled: false,
        categoryMap: [],
        products: [
          {
            id: "h-2",
            slug: "hizmet-wapsiz",
            name: "Ekran Değişimi",
            priceAmount: 1200,
            imageUrls: [],
            metadata: {
              itemKind: "service",
              templateKey: "service",
            },
          },
        ],
      }),
    );

    expect(yalnizHizmetHtml).toContain("Hizmeti incele →");
    expect(yalnizHizmetHtml).not.toContain('aria-label="WhatsApp&#x27;tan Sor"');
    expect(yalnizHizmetHtml).not.toContain('aria-label="Sepete ekle"');

    const whatsappYokHtml = renderToStaticMarkup(
      createElement(ProductCatalog, {
        storeSlug: "ornek-magaza",
        storeName: "Örnek Mağaza",
        whatsappBaseUrl: null,
        trackingEnabled: false,
        categoryMap: [],
        products: [
          {
            id: "u-2",
            slug: "tek-urun",
            name: "Tek Ürün",
            price: "100 TL",
            priceAmount: 100,
            stockQuantity: 2,
            imageUrls: [],
            metadata: { itemKind: "physical", templateKey: "generic" },
          },
        ],
      }),
    );

    expect(whatsappYokHtml).not.toContain("WhatsApp&#x27;tan Sor");
    expect(whatsappYokHtml).not.toContain("bg-[#F4F7FC]");
    expect(whatsappYokHtml).toContain("h-5 min-h-[20px]");
  });
});
