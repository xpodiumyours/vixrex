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
});
