import { renderToStaticMarkup } from "react-dom/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const m = vi.hoisted(() => ({
  cookie: vi.fn(),
  verifyOwner: vi.fn(),
  active: vi.fn(),
  admin: vi.fn(() => ({ from: vi.fn(), rpc: vi.fn() })),
  kanitMode: "error" as "error" | "throw" | "verified",
  sourceType: "invoice" as "invoice" | "manual",
  detailProps: vi.fn(),
  catalogProps: vi.fn(),
}));

vi.mock("next/cache", () => ({
  unstable_cache: <T extends (...args: never[]) => unknown>(fn: T) => fn,
  revalidateTag: vi.fn(),
}));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({ get: m.cookie })),
}));

vi.mock("next/navigation", () => ({
  notFound: vi.fn(() => {
    throw new Error("NEXT_NOT_FOUND");
  }),
  permanentRedirect: vi.fn(),
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: m.admin,
}));

vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: m.verifyOwner,
}));

vi.mock("@/lib/ownerSessionValidity", () => ({
  ownerSessionStillActive: m.active,
}));

vi.mock("@/lib/assistantConversationServer", () => ({
  loadAssistantMessagesForStore: vi.fn(async () => ({ conversationId: null, messages: [] })),
  loadOwnerFlowStateForStore: vi.fn(async () => null),
}));

vi.mock("@/components/ProductDetailExperience", () => ({
  default: (props: Record<string, unknown>) => {
    m.detailProps(props);
    return null;
  },
}));

vi.mock("@/components/VitrinCartDock", () => ({
  default: () => null,
}));

vi.mock("@/components/ProductViewTracker", () => ({
  default: () => null,
}));

vi.mock("@/app/v/[slug]/ProductCatalog", () => ({
  default: (props: Record<string, unknown>) => {
    m.catalogProps(props);
    return null;
  },
}));

vi.mock("@/app/v/[slug]/VitrinProfileView", () => ({
  default: (props: { catalog?: unknown }) => props.catalog ?? null,
}));

vi.mock("@/app/v/[slug]/OwnerWorkspaceShell", () => ({
  default: () => null,
}));

vi.mock("@/app/v/[slug]/components/VixrexAvatar", () => ({
  VixrexAvatar: () => null,
}));

const STORE_ROW = {
  id: "11111111-1111-4111-8111-111111111111",
  slug: "deneme-vitrin",
  name: "Deneme Vitrin",
  is_published: true,
  is_demo: false,
  logo_url: "https://cdn.example/logo.jpg",
  shelf_image_url: "https://cdn.example/shelf.jpg",
};

const INVOICE_PRODUCT = {
  id: "22222222-2222-4222-8222-222222222222",
  name: "Fatura Ürünü",
  slug: "fatura-urunu",
  description: "Açıklama",
  price_text: "299 TL",
  price_amount: 299,
  currency: "TRY",
  stock_status: "Mevcut",
  stock_quantity: 5,
  brand: "Tutku",
  barcode: null,
  metadata: {},
  variants: [{ id: "v1", options: { color: "Siyah" }, imageUrls: ["https://cdn.example/v1.jpg"] }],
  seo_title: null,
  seo_description: null,
  image_urls: ["https://cdn.example/fatura.jpg"],
  category_id: null,
  is_visible: true,
  is_active: true,
  source_type: "invoice",
};

const MANUAL_PRODUCT = {
  ...INVOICE_PRODUCT,
  id: "33333333-3333-4333-8333-333333333333",
  name: "Manuel Ürün",
  slug: "manuel-urun",
  image_urls: ["https://cdn.example/manuel.jpg"],
  source_type: "manual",
};

vi.mock("@/lib/supabase", () => ({
  supabase: {
    from: vi.fn((table: string) => ({
      select: vi.fn((cols: string) => {
        const resolveList = async () => {
          if (table === "products" && cols === "id,fatura_kanit") {
            if (m.kanitMode === "throw") throw new Error("KANIT_QUERY_THREW");
            if (m.kanitMode === "error") return { data: null, error: { message: "db error" } };
            return {
              data: [
                {
                  id: INVOICE_PRODUCT.id,
                  fatura_kanit: {
                    gorselKaynaklari: [{ hakKayitDurumu: "verified_supplier_permission" }],
                  },
                },
              ],
              error: null,
            };
          }
          if (table === "products") {
            return { data: [INVOICE_PRODUCT, MANUAL_PRODUCT], error: null };
          }
          if (table === "product_categories" || table === "store_articles") {
            return { data: [], error: null };
          }
          return { data: null, error: null };
        };

        const resolveSingle = async () => {
          if (table === "stores") return { data: STORE_ROW, error: null };
          if (table === "products" && cols === "id,fatura_kanit") {
            if (m.kanitMode === "throw") throw new Error("KANIT_QUERY_THREW");
            if (m.kanitMode === "error") return { data: null, error: { message: "db error" } };
            return {
              data: {
                id: INVOICE_PRODUCT.id,
                fatura_kanit: {
                  gorselKaynaklari: [{ hakKayitDurumu: "verified_supplier_permission" }],
                },
              },
              error: null,
            };
          }
          if (table === "products") {
            return {
              data: m.sourceType === "invoice" ? INVOICE_PRODUCT : MANUAL_PRODUCT,
              error: null,
            };
          }
          return { data: null, error: null };
        };

        const builder: Record<string, unknown> = {
          eq: () => builder,
          in: () => resolveList(),
          order: () => builder,
          limit: () => resolveList(),
          single: () => resolveSingle(),
          maybeSingle: () => resolveSingle(),
          then: (resolve: (value: unknown) => unknown, reject: (reason: unknown) => unknown) =>
            resolveList().then(resolve, reject),
        };
        return builder;
      }),
    })),
    rpc: vi.fn(async () => ({ data: null, error: null })),
  },
}));

import ProductDetailPage from "@/app/v/[slug]/urun/[productSlug]/page";
import StorePage from "@/app/v/[slug]/page";

describe("A1 ve A5: vitrin ve ürün detay sayfaları fail-closed", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    m.cookie.mockReturnValue(undefined);
    m.verifyOwner.mockReturnValue(null);
    m.active.mockResolvedValue(false);
    m.kanitMode = "error";
    m.sourceType = "invoice";
  });

  it("ürün detayında fatura_kanit sorgusu hata verirse fatura ürünü görselini gizler", async () => {
    m.kanitMode = "error";
    m.sourceType = "invoice";

    const element = await ProductDetailPage({
      params: Promise.resolve({ slug: "deneme-vitrin", productSlug: "fatura-urunu" }),
    });
    renderToStaticMarkup(element);

    expect(m.detailProps).toHaveBeenCalledOnce();
    const props = m.detailProps.mock.calls[0][0] as {
      images: string[];
      isOwner: boolean;
      product: { imageUrls: string[]; gorselIzinBekliyor?: boolean; variants?: Array<{ imageUrls?: string[] }> };
    };
    expect(props.isOwner).toBe(false);
    expect(props.images).toEqual([]);
    expect(props.product.imageUrls).toEqual([]);
    expect(props.product.gorselIzinBekliyor).toBe(true);
    expect(props.product.variants?.[0]?.imageUrls).toEqual([]);
  });

  it("ürün detayında fatura_kanit sorgusu istisna fırlatırsa fatura ürünü görselini gizler", async () => {
    m.kanitMode = "throw";
    m.sourceType = "invoice";

    const element = await ProductDetailPage({
      params: Promise.resolve({ slug: "deneme-vitrin", productSlug: "fatura-urunu" }),
    });
    renderToStaticMarkup(element);

    const props = m.detailProps.mock.calls[0][0] as {
      images: string[];
      product: { imageUrls: string[]; gorselIzinBekliyor?: boolean };
    };
    expect(props.images).toEqual([]);
    expect(props.product.imageUrls).toEqual([]);
    expect(props.product.gorselIzinBekliyor).toBe(true);
  });

  it("ürün detayında fatura_kanit hata verse bile manuel ürünün görselini korur", async () => {
    m.kanitMode = "error";
    m.sourceType = "manual";

    const element = await ProductDetailPage({
      params: Promise.resolve({ slug: "deneme-vitrin", productSlug: "manuel-urun" }),
    });
    renderToStaticMarkup(element);

    const props = m.detailProps.mock.calls[0][0] as {
      images: string[];
      product: { gorselIzinBekliyor?: boolean };
    };
    expect(props.product.gorselIzinBekliyor).toBe(false);
    expect(props.images).toEqual(["https://cdn.example/manuel.jpg"]);
  });

  it("ürün detayında iptal edilmiş oturum çereziyle isOwner true olmaz ve telif maskesi kalkmaz", async () => {
    m.kanitMode = "error";
    m.sourceType = "invoice";
    m.cookie.mockReturnValue({ value: "signed-owner-cookie" });
    m.verifyOwner.mockReturnValue({
      storeId: STORE_ROW.id,
      slug: STORE_ROW.slug,
      sessionToken: "a".repeat(64),
    });
    m.active.mockResolvedValueOnce(false);

    const element = await ProductDetailPage({
      params: Promise.resolve({ slug: "deneme-vitrin", productSlug: "fatura-urunu" }),
    });
    renderToStaticMarkup(element);

    expect(m.active).toHaveBeenCalledOnce();
    const props = m.detailProps.mock.calls[0][0] as {
      images: string[];
      isOwner: boolean;
    };
    expect(props.isOwner).toBe(false);
    expect(props.images).toEqual([]);
  });

  it("vitrin sayfasında fatura_kanit hata verirse fatura ürünü maskelenir, manuel ürün korunur", async () => {
    m.kanitMode = "error";

    const element = await StorePage({
      params: Promise.resolve({ slug: "deneme-vitrin" }),
      searchParams: Promise.resolve({}),
    });
    renderToStaticMarkup(element);

    expect(m.catalogProps).toHaveBeenCalledOnce();
    const props = m.catalogProps.mock.calls[0][0] as {
      products: Array<{
        id: string;
        imageUrls: string[];
        gorselIzinBekliyor?: boolean;
        variants?: Array<{ imageUrls?: string[] }>;
      }>;
    };
    const invoiceCard = props.products.find((p) => p.id === INVOICE_PRODUCT.id);
    const manualCard = props.products.find((p) => p.id === MANUAL_PRODUCT.id);

    expect(invoiceCard?.gorselIzinBekliyor).toBe(true);
    expect(invoiceCard?.imageUrls).toEqual([]);
    expect(invoiceCard?.variants?.[0]?.imageUrls).toEqual([]);
    expect(manualCard?.gorselIzinBekliyor).toBe(false);
    expect(manualCard?.imageUrls).toEqual(["https://cdn.example/manuel.jpg"]);
  });

  it("vitrin sayfasında fatura_kanit istisna fırlatırsa fatura ürünü fail-closed maskelenir", async () => {
    m.kanitMode = "throw";

    const element = await StorePage({
      params: Promise.resolve({ slug: "deneme-vitrin" }),
      searchParams: Promise.resolve({}),
    });
    renderToStaticMarkup(element);

    const props = m.catalogProps.mock.calls[0][0] as {
      products: Array<{ id: string; imageUrls: string[]; gorselIzinBekliyor?: boolean }>;
    };
    const invoiceCard = props.products.find((p) => p.id === INVOICE_PRODUCT.id);
    expect(invoiceCard?.gorselIzinBekliyor).toBe(true);
    expect(invoiceCard?.imageUrls).toEqual([]);
  });
});
