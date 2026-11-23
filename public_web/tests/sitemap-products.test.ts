import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  from: vi.fn(),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: {
    from: mocks.from,
  },
}));

vi.mock("next/cache", () => ({
  unstable_cache: (loader: () => unknown) => loader,
}));

vi.mock("@/lib/siteUrl", () => ({
  getSiteUrl: () => "https://vixrex.test",
}));

import { GET } from "@/app/sitemap.xml/route";
import { MAX_PRODUCT_IMAGES } from "@/lib/productImagePolicy";

type QueryResult = {
  data: unknown[];
  error: null;
};

type QueryBuilder = {
  select: ReturnType<typeof vi.fn>;
  eq: ReturnType<typeof vi.fn>;
  then: PromiseLike<QueryResult>["then"];
};

function createQueryBuilder(data: unknown[]): QueryBuilder {
  const result: QueryResult = { data, error: null };
  const builder = {} as QueryBuilder;
  builder.select = vi.fn(() => builder);
  builder.eq = vi.fn(() => builder);
  builder.then = (onFulfilled, onRejected) =>
    Promise.resolve(result).then(onFulfilled, onRejected);
  return builder;
}

let productQuery: QueryBuilder;

describe("GET /sitemap.xml product URLs", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    productQuery = createQueryBuilder([
      {
        store_id: "store-1",
        slug: "iliski-urun",
        updated_at: "2026-08-20T11:30:00.000Z",
      },
      {
        store_id: "unpublished-store",
        slug: "gizli-urun",
        updated_at: "2026-08-20T12:00:00.000Z",
      },
    ]);

    const queries: Record<string, QueryBuilder> = {
      stores: createQueryBuilder([
        {
          id: "store-1",
          slug: "ornek-magaza",
          updated_at: "2026-08-19T10:00:00.000Z",
          products: [],
        },
      ]),
      store_articles: createQueryBuilder([]),
      products: productQuery,
    };

    mocks.from.mockImplementation((table: string) => queries[table]);
  });

  it("reads the relational products table and lists only products of published stores", async () => {
    const response = await GET();
    const xml = await response.text();

    expect(response.status).toBe(200);
    expect(mocks.from).toHaveBeenCalledWith("products");
    expect(productQuery.eq).toHaveBeenCalledWith("is_active", true);
    expect(productQuery.eq).toHaveBeenCalledWith("is_visible", true);
    expect(xml).toContain(
      "<loc>https://vixrex.test/v/ornek-magaza/urun/iliski-urun</loc>",
    );
    expect(xml).toContain("<lastmod>2026-08-20T11:30:00.000Z</lastmod>");
    expect(xml).not.toContain("gizli-urun");
  });

  it("emits image:image tags with XML escaping and MAX_PRODUCT_IMAGES cap for permitted products", async () => {
    const fazlaGorseller = Array.from(
      { length: MAX_PRODUCT_IMAGES + 2 },
      (_, idx) => `https://cdn.vixrex.test/fatura-${idx + 1}.jpg`,
    );

    const queries: Record<string, QueryBuilder> = {
      stores: createQueryBuilder([
        {
          id: "store-1",
          slug: "ornek-magaza",
          name: "Kral & Ticaret <A.Ş.>",
          updated_at: "2026-08-19T10:00:00.000Z",
          is_demo: false,
        },
      ]),
      store_articles: createQueryBuilder([]),
      products: createQueryBuilder([
        {
          store_id: "store-1",
          slug: "manuel-urun",
          name: 'Çay "Özel" & Kahve',
          image_urls: ["https://cdn.vixrex.test/urun.jpg?w=800&h=800"],
          source_type: "manual",
          fatura_kanit: null,
          updated_at: "2026-08-20T11:30:00.000Z",
        },
        {
          store_id: "store-1",
          slug: "izinli-fatura-urun",
          name: "Fatura Ürünü",
          image_urls: fazlaGorseller,
          source_type: "invoice",
          fatura_kanit: {
            gorselKaynaklari: [
              { hakKayitDurumu: "verified_supplier_permission" },
            ],
          },
          updated_at: "2026-08-20T11:35:00.000Z",
        },
      ]),
    };

    mocks.from.mockImplementation((table: string) => queries[table]);

    const response = await GET();
    const xml = await response.text();

    expect(response.status).toBe(200);
    expect(xml).toContain(
      'xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"',
    );
    expect(xml).toContain(
      "<image:loc>https://cdn.vixrex.test/urun.jpg?w=800&amp;h=800</image:loc>",
    );
    expect(xml).not.toContain("<image:title>");
    expect(xml).not.toContain("<image:caption>");
    expect(xml).not.toContain("<image:geo_location>");
    expect(xml).toContain(
      "<image:loc>https://cdn.vixrex.test/fatura-1.jpg</image:loc>",
    );
    expect(xml).toContain(
      `<image:loc>https://cdn.vixrex.test/fatura-${MAX_PRODUCT_IMAGES}.jpg</image:loc>`,
    );
    expect(xml).not.toContain(`fatura-${MAX_PRODUCT_IMAGES + 1}.jpg`);
  });

  it("blocks image:image tags when copyright permission is missing or pending while preserving product URL", async () => {
    const queries: Record<string, QueryBuilder> = {
      stores: createQueryBuilder([
        {
          id: "store-1",
          slug: "ornek-magaza",
          name: "Örnek Mağaza",
          updated_at: "2026-08-19T10:00:00.000Z",
          is_demo: false,
        },
      ]),
      store_articles: createQueryBuilder([]),
      products: createQueryBuilder([
        {
          store_id: "store-1",
          slug: "fatura-kanitsiz",
          name: "Kanıtsız Fatura Ürünü",
          image_urls: ["https://cdn.vixrex.test/yasak-1.jpg"],
          source_type: "invoice",
          fatura_kanit: null,
          updated_at: "2026-08-20T11:30:00.000Z",
        },
        {
          store_id: "store-1",
          slug: "fatura-bekleyen",
          name: "Bekleyen Fatura Ürünü",
          image_urls: ["https://cdn.vixrex.test/yasak-2.jpg"],
          source_type: "invoice",
          fatura_kanit: {
            gorselKaynaklari: [{ hakKayitDurumu: "unknown" }],
          },
          updated_at: "2026-08-20T11:31:00.000Z",
        },
        {
          store_id: "store-1",
          slug: "fatura-bos-kanit",
          name: "Boş Kanıtlı Fatura Ürünü",
          image_urls: ["https://cdn.vixrex.test/yasak-3.jpg"],
          source_type: "invoice",
          fatura_kanit: {},
          updated_at: "2026-08-20T11:32:00.000Z",
        },
        {
          store_id: "store-1",
          slug: "manuel-reddedilen",
          name: "Reddedilen Görsel Ürünü",
          image_urls: ["https://cdn.vixrex.test/yasak-4.jpg"],
          source_type: "manual",
          fatura_kanit: {
            gorselKaynaklari: [{ hakKayitDurumu: "denied" }],
          },
          updated_at: "2026-08-20T11:33:00.000Z",
        },
      ]),
    };

    mocks.from.mockImplementation((table: string) => queries[table]);

    const response = await GET();
    const xml = await response.text();

    expect(response.status).toBe(200);
    expect(xml).toContain(
      "<loc>https://vixrex.test/v/ornek-magaza/urun/fatura-kanitsiz</loc>",
    );
    expect(xml).toContain(
      "<loc>https://vixrex.test/v/ornek-magaza/urun/fatura-bekleyen</loc>",
    );
    expect(xml).toContain(
      "<loc>https://vixrex.test/v/ornek-magaza/urun/fatura-bos-kanit</loc>",
    );
    expect(xml).toContain(
      "<loc>https://vixrex.test/v/ornek-magaza/urun/manuel-reddedilen</loc>",
    );
    expect(xml).not.toContain("<image:image>");
    expect(xml).not.toContain("<image:loc>");
    expect(xml).not.toContain("yasak-1.jpg");
    expect(xml).not.toContain("yasak-2.jpg");
    expect(xml).not.toContain("yasak-3.jpg");
    expect(xml).not.toContain("yasak-4.jpg");
  });

  it("filters out http, javascript, and invalid image URLs", async () => {
    const queries: Record<string, QueryBuilder> = {
      stores: createQueryBuilder([
        {
          id: "store-1",
          slug: "ornek-magaza",
          name: "Örnek Mağaza",
          updated_at: "2026-08-19T10:00:00.000Z",
          is_demo: false,
        },
      ]),
      store_articles: createQueryBuilder([]),
      products: createQueryBuilder([
        {
          store_id: "store-1",
          slug: "karisik-gorsel",
          name: "Karışık Görselli Ürün",
          image_urls: [
            "http://cdn.vixrex.test/http-only.jpg",
            "javascript:alert(1)",
            "data:image/png;base64,AAAA",
            "/local/path.jpg",
            "https://",
            "https://cdn.vixrex.test/gecerli.jpg",
          ],
          source_type: "manual",
          fatura_kanit: null,
          updated_at: "2026-08-20T11:30:00.000Z",
        },
        {
          store_id: "store-1",
          slug: "tamami-gecersiz",
          name: "Geçersiz Görselli Ürün",
          image_urls: [
            "http://cdn.vixrex.test/yalniz-http.jpg",
            "javascript:void(0)",
          ],
          source_type: "manual",
          fatura_kanit: null,
          updated_at: "2026-08-20T11:31:00.000Z",
        },
      ]),
    };

    mocks.from.mockImplementation((table: string) => queries[table]);

    const response = await GET();
    const xml = await response.text();

    expect(response.status).toBe(200);
    expect(xml).toContain(
      "<loc>https://vixrex.test/v/ornek-magaza/urun/karisik-gorsel</loc>",
    );
    expect(xml).toContain(
      "<loc>https://vixrex.test/v/ornek-magaza/urun/tamami-gecersiz</loc>",
    );
    expect(xml).toContain(
      "<image:loc>https://cdn.vixrex.test/gecerli.jpg</image:loc>",
    );
    expect(xml.match(/<image:image>/g)).toHaveLength(1);
    expect(xml).not.toContain("http-only.jpg");
    expect(xml).not.toContain("javascript:");
    expect(xml).not.toContain("data:image");
    expect(xml).not.toContain("/local/path.jpg");
    expect(xml).not.toContain("yalniz-http.jpg");
    expect(xml).not.toContain("<image:loc>https://</image:loc>");
  });
});
