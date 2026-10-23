import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({ index: 0, values: [] as unknown[] }));

vi.mock("react", async (importOriginal) => {
  const actual = await importOriginal<typeof import("react")>();
  return {
    ...actual,
    useState(initial: unknown) {
      const index = state.index++;
      return actual.useState(index < state.values.length ? state.values[index] : initial);
    },
  };
});

vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));
vi.mock("@/lib/supabase", () => ({ supabase: {} }));
vi.mock("@/components/owner/OwnerProductManager", () => ({
  OwnerProductManager: ({ storeSlug, products }: {
    storeSlug: string;
    products: Array<{ id: string; name: string }>;
  }) => createElement("section", { "data-testid": "urun-yonetimi", "data-store": storeSlug },
    products.map((product) => createElement("span", { key: product.id }, product.name))),
}));

import UrunlerPage from "@/app/app/urunler/page";

const store = {
  id: "store-1",
  slug: "ornek-vitrin",
  name: "Örnek mağaza",
  kategori: null,
  business_type: null,
  products: [{ id: "product-1", name: "Faturadan gelen ürün" }],
  product_categories: [],
};

function renderPage(loadedStore: typeof store | null, loading: boolean, error = "") {
  state.index = 0;
  state.values = [loadedStore, loading, error];
  return renderToStaticMarkup(createElement(UrunlerPage));
}

function productManager(html: string) {
  return html.match(/<section data-testid="urun-yonetimi".*?<\/section>/)?.[0];
}

describe("ürün sayfası yenileme sürekliliği", () => {
  it("ilk yüklemede mevcut yükleme ekranını gösterir", () => {
    const html = renderPage(null, true);
    expect(html).toContain("animate-pulse");
    expect(productManager(html)).toBeUndefined();
    expect(html).not.toContain("Vitrin yok");
  });

  it("ilk yükleme başarısızsa hata ve dönüş bağlantısı görünür", () => {
    const html = renderPage(null, false, "Vitrin bulunamadı. Önce vitrin oluştur.");
    expect(html).toContain("Vitrin bulunamadı. Önce vitrin oluştur.");
    expect(html).toContain('href="/app"');
    expect(productManager(html)).toBeUndefined();
  });

  it("yüklü mağazanın ürünlerini yönetim ekranına taşır", () => {
    const html = renderPage(store, false);
    expect(html).toContain("Örnek mağaza");
    expect(productManager(html)).toContain("Faturadan gelen ürün");
    expect(html).not.toContain("animate-pulse");
  });

  it("yenileme devam ederken mevcut ürün yönetimini ekranda tutar", () => {
    const loaded = renderPage(store, false);
    const refreshing = renderPage(store, true);
    expect(productManager(refreshing)).toBeDefined();
    expect(productManager(refreshing)).toBe(productManager(loaded));
    expect(refreshing).not.toContain("animate-pulse");
  });

  it.each([
    "Ürünler yüklenemedi.",
    "Vitrin bulunamadı. Önce vitrin oluştur.",
    "Vitrin slug okunamadı.",
  ])("yenileme hatasında yönetim ekranını ve hatayı birlikte gösterir: %s", (error) => {
    const loaded = renderPage(store, false);
    const failed = renderPage(store, false, error);
    expect(productManager(failed)).toBeDefined();
    expect(productManager(failed)).toBe(productManager(loaded));
    expect(failed).toContain('role="alert"');
    expect(failed).toContain(error);
    expect(failed).toContain("Örnek mağaza");
  });
});
