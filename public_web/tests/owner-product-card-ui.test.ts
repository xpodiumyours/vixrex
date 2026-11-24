import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";

const hookState = vi.hoisted(() => ({ index: 0, values: {} as Record<number, unknown> }));

vi.mock("react", async (importOriginal) => {
  const actual = await importOriginal<typeof import("react")>();
  return {
    ...actual,
    useState(initial: unknown) {
      const idx = hookState.index++;
      return actual.useState(Object.hasOwn(hookState.values, idx) ? hookState.values[idx] : initial);
    },
  };
});

import {
  OwnerProductManager,
  kartSatisFiyatiHazirla,
  kartStokAdimiHesapla,
  type OwnerProduct,
} from "@/components/owner/OwnerProductManager";
import InvoiceToProducts from "@/components/owner/InvoiceToProducts";

const KATEGORILER = [
  { id: "cat-1", name: "Elektronik", product_template_key: "generic" },
  { id: "cat-2", name: "Danismanlik", product_template_key: "service" },
];

const FATURA_URUNU: OwnerProduct = {
  id: "p-taslak",
  slug: "taslak-urun",
  name: "Taslak Kulaklik",
  description: "Aciklama",
  price_text: "499 TL",
  image_urls: ["https://example.com/a.jpg"],
  category_id: "cat-1",
  stock_status: "Mevcut",
  stock_quantity: 0,
  is_visible: false,
  source_type: "invoice",
  product_categories: { name: "Elektronik", product_template_key: "generic" },
};

const MANUEL_URUN: OwnerProduct = {
  id: "p-yayin",
  slug: "yayin-urun",
  name: "Yayinda Hizmet",
  description: "Hizmet",
  price_text: "900 TL",
  image_urls: null,
  category_id: "cat-2",
  stock_status: "",
  stock_quantity: null,
  is_visible: true,
  source_type: "manual",
  product_categories: { name: "Danismanlik", product_template_key: "service" },
};

function renderKartYonetimi(
  products: OwnerProduct[],
  values: Record<number, unknown> = {},
  categories: Array<{ id: string; name: string; product_template_key?: string | null }> = KATEGORILER,
): string {
  hookState.index = 0;
  hookState.values = values;
  return renderToStaticMarkup(
    createElement(OwnerProductManager, {
      storeSlug: "test-vitrin",
      products,
      categories,
      onRefresh: async () => {},
    }),
  );
}

describe("kartSatisFiyatiHazirla negatif uc durumlari", () => {
  it.each([
    "",
    "   ",
    "abc",
    "TL",
    "...",
    "0",
    "0,00 TL",
    "-50",
    "-12,50 TL",
    "TL -10",
    "12.34.56",
  ])("gecersiz veya sifir/negatif fiyati filtreler: %s", (giris) => {
    expect(kartSatisFiyatiHazirla(giris, "149,90 TL")).toEqual({
      gecerli: false,
      degisti: false,
      priceText: null,
    });
  });

  it("mevcut fiyatla ayni degerde gereksiz guncelleme tetiklemez", () => {
    expect(kartSatisFiyatiHazirla("  149,90 TL  ", "149,90 TL")).toEqual({
      gecerli: true,
      degisti: false,
      priceText: "149,90 TL",
    });
  });

  it("gecerli yeni fiyati kirpar ve degisikligi isaretler", () => {
    expect(kartSatisFiyatiHazirla("  249,90 TL ", "149,90 TL")).toEqual({
      gecerli: true,
      degisti: true,
      priceText: "249,90 TL",
    });
  });
});

describe("kartStokAdimiHesapla negatif uc durumlari", () => {
  it("stok sayisi 0 altina dusmez", () => {
    expect(kartStokAdimiHesapla(0, -1)).toBe(0);
    expect(kartStokAdimiHesapla(null, -1)).toBe(0);
    expect(kartStokAdimiHesapla(undefined, -5)).toBe(0);
    expect(kartStokAdimiHesapla(-4, -1)).toBe(0);
    expect(kartStokAdimiHesapla(2, -10)).toBe(0);
  });

  it("NaN ve sonsuz degerlerde guvenli taban degeri korur", () => {
    expect(kartStokAdimiHesapla(4, Number.NaN)).toBe(4);
    expect(kartStokAdimiHesapla(Number.NaN, 1)).toBe(1);
    expect(kartStokAdimiHesapla(Number.POSITIVE_INFINITY, -1)).toBe(0);
  });

  it("tam sayi artirma ve azaltma adimlarini dogru hesaplar", () => {
    expect(kartStokAdimiHesapla(0, 1)).toBe(1);
    expect(kartStokAdimiHesapla(5, -1)).toBe(4);
    expect(kartStokAdimiHesapla(5, 1)).toBe(6);
  });
});

describe("OwnerProductManager kart arayuz sozlesmesi", () => {
  it("taslak ve yayindaki kartlari yeni duzenle render eder", () => {
    const html = renderKartYonetimi([FATURA_URUNU, MANUEL_URUN]);

    expect(html).toContain("aspect-[16/11]");
    expect(html).toContain("Fotoğraf yok");
    expect(html).toContain("min-h-[44px]");
    expect(html).toContain("Satış fiyatı");
    expect(html).toContain("Stok");
    expect(html).toContain("Yayınla");
    expect(html).toContain("✓ Yayında");
    expect(html).toContain("⋮");
    expect(html).not.toContain("🧾 Faturaya dön");
  });

  it("fatura urununun acik secenek menusu uc isi ogelesini render eder", () => {
    const html = renderKartYonetimi([FATURA_URUNU], { 24: FATURA_URUNU.id });

    expect(html).toContain('role="menu"');
    expect(html).toContain("Fatura Detayı");
    expect(html).toContain("Başlık &amp; Açıklama");
    expect(html).toContain("Ürünü Sil");
  });

  it("coklu ve filtresiz kartlar suruklenebilir; etkilesim kontrolleri surukleme yuzeyinin icinde render edilir", () => {
    const html = renderKartYonetimi([FATURA_URUNU, MANUEL_URUN]);

    expect(html).toContain('draggable="true"');
    expect(html).toContain("cursor-grab");
    expect(html).toContain('id="kart-fiyat-p-taslak"');
    expect(html).toContain('aria-label="Taslak Kulaklik stoğu azalt"');
    expect(html).toContain('aria-haspopup="menu"');
  });

  it("secim modunda surukleme kapanir ve kart secim kutusuna donusur", () => {
    const html = renderKartYonetimi([FATURA_URUNU, MANUEL_URUN], { 11: true });

    expect(html).not.toContain('draggable="true"');
    expect(html).toContain("Bu ürünü seç");
  });

  it("yalniz fotografsiz urun kartinda aspect-[16/11] yerine kompakt serit ve Duzenle butonu gosterir", () => {
    const html = renderKartYonetimi([MANUEL_URUN]);

    expect(html).not.toContain("aspect-[16/11]");
    expect(html).toContain("h-[72px]");
    expect(html).toContain("Fotoğraf yok");
    expect(html).toContain("Düzenle");
  });

  it("hizmet urununde stok butonlari gizlenir, fiyat birimi ve yayinda rozeti gosterilir", () => {
    const html = renderKartYonetimi([MANUEL_URUN]);

    expect(html).not.toContain("stoğu azalt");
    expect(html).not.toContain("stoğu artır");
    expect(html).toContain("900 TL");
    expect(html).toContain("✓ Yayında");
  });

  it("bos kategori listesinde select ve Tum Kategoriler (0) secenegi gosterir", () => {
    const html = renderKartYonetimi([FATURA_URUNU], {}, []);

    expect(html).toContain("<select");
    expect(html).toContain("Tüm Kategoriler (0)");
  });

  it("secim modunda fiyat, stok ve aksiyon satiri gizlenir", () => {
    const html = renderKartYonetimi([FATURA_URUNU, MANUEL_URUN], { 11: true });

    expect(html).not.toContain("kart-fiyat-");
    expect(html).not.toContain("stoğu azalt");
    expect(html).not.toContain("Yayınla");
    expect(html).not.toContain("✓ Yayında");
  });

  it("birim iceren fiyatta ekstra TL simgesi render edilmez ve yeni kapsayici siniflari bulunur", () => {
    const htmlBirimli = renderKartYonetimi([{ ...FATURA_URUNU, price_text: "325 TL" }]);
    const htmlBirimsiz = renderKartYonetimi([{ ...FATURA_URUNU, price_text: "325" }]);

    expect(htmlBirimli).not.toContain(">₺<");
    expect(htmlBirimsiz).toContain(">₺<");
    expect(htmlBirimli).toContain("min-h-[36px]");
    expect(htmlBirimli).toContain("minmax(min(100%,280px),1fr)");
  });
});

describe("InvoiceToProducts okunuyor okuma ekrani", () => {
  it("belge gelmeden halka, gecen sure sayaci ve uc gercek adim kartini gosterir", () => {
    hookState.index = 0;
    hookState.values = {
      0: "okunuyor",
      1: null,
    };

    const html = renderToStaticMarkup(
      createElement(InvoiceToProducts, {
        storeSlug: "test-vitrin",
        onUploaded: async () => {},
      }),
    );

    expect(html).toContain("fatura-okuma-ring");
    expect(html).toContain("fatura-okuma-halka");
    expect(html).toContain("fatura-gecen-sure");
    expect(html).toContain("00:00");
    expect(html).toContain("fatura-adim-ray");
    expect(html).toContain("Fatura görüntüsü alındı");
    expect(html).toContain("Fatura okunuyor ve resmî ürünler araştırılıyor");
    expect(html).toContain("Ürün kartları ve görseller hazırlanıyor");
    expect((html.match(/class="fatura-adim-satir fatura-adim-satir--/g) ?? []).length).toBe(3);
    expect([...html.matchAll(/<span class="fatura-adim-durum">(tamam|sürüyor|bekliyor)<\/span>/g)].map((e) => e[1]))
      .toEqual(["bekliyor", "sürüyor", "bekliyor"]);
    expect(html).not.toContain("fatura-hologram-kart");
    expect(html).toContain("fatura-sayilar");
    expect(html).toContain("<dt>Satır</dt>");
    expect(html).toContain("<dt>Miktar</dt>");
    expect(html).toContain("<dt>Tutar</dt>");
  });
});
