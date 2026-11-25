import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const m = vi.hoisted(() => ({
  from: vi.fn(),
  rpc: vi.fn(async () => ({ data: null, error: null })),
  cookie: vi.fn(),
  verifyOwner: vi.fn(),
  active: vi.fn(),
  admin: vi.fn(() => ({ from: vi.fn(), rpc: vi.fn() })),
  unstableCache: vi.fn(),
  notFound: vi.fn(() => {
    throw new Error("NEXT_NOT_FOUND");
  }),
  detailProps: vi.fn(),
  catalogProps: vi.fn(),
  vitrinProps: vi.fn(),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: {
    from: m.from,
    rpc: m.rpc,
  },
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: m.admin,
}));

vi.mock("next/cache", () => ({
  unstable_cache: (
    loader: () => unknown,
    keys?: string[],
    options?: { tags?: string[]; revalidate?: number },
  ) => {
    m.unstableCache(keys, options);
    return loader;
  },
  revalidateTag: vi.fn(),
}));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({ get: m.cookie })),
}));

vi.mock("next/navigation", () => ({
  notFound: m.notFound,
  permanentRedirect: vi.fn(),
}));

vi.mock("next/link", () => ({
  default: (props: { href: string; children?: unknown; className?: string }) =>
    createElement(
      "a",
      { href: props.href, className: props.className },
      props.children as never,
    ),
}));

vi.mock("next/image", () => ({
  default: (props: { src: string; alt: string; className?: string }) =>
    createElement("img", {
      src: props.src,
      alt: props.alt,
      className: props.className,
    }),
}));

vi.mock("@/lib/siteUrl", () => ({
  getSiteUrl: () => "https://vixrex.test",
  buildSiteUrl: (path: string) => `https://vixrex.test${path}`,
  isExternalHttpUrl: (url: string) => /^https?:\/\//i.test(url),
}));

vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: m.verifyOwner,
}));

vi.mock("@/lib/ownerSessionValidity", () => ({
  ownerSessionStillActive: m.active,
}));

vi.mock("@/lib/assistantConversationServer", () => ({
  loadAssistantMessagesForStore: vi.fn(async () => ({
    conversationId: null,
    messages: [],
  })),
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

vi.mock("@/app/v/[slug]/ProductCatalog", () => ({
  default: (props: Record<string, unknown>) => {
    m.catalogProps(props);
    return null;
  },
}));

vi.mock("@/app/v/[slug]/VitrinProfileView", () => ({
  default: (props: Record<string, unknown> & { catalog?: unknown }) => {
    m.vitrinProps(props);
    return props.catalog ?? null;
  },
}));

vi.mock("@/app/v/[slug]/OwnerWorkspaceShell", () => ({
  default: () => null,
}));

vi.mock("@/app/v/[slug]/components/VixrexAvatar", () => ({
  VixrexAvatar: () => null,
}));

import {
  GET as sitemapGet,
  revalidate as sitemapRevalidate,
} from "@/app/sitemap.xml/route";
import ProductDetailPage, {
  generateMetadata as generateProductMetadata,
  revalidate as productRevalidate,
} from "@/app/v/[slug]/urun/[productSlug]/page";
import BlogIndexPage, {
  generateMetadata as generateBlogMetadata,
  revalidate as blogIndexRevalidate,
} from "@/app/v/[slug]/yazilar/page";
import ArticleDetailPage, {
  generateMetadata as generateArticleMetadata,
  revalidate as articleDetailRevalidate,
} from "@/app/v/[slug]/yazilar/[articleSlug]/page";
import StorePage, {
  generateMetadata as generateStoreMetadata,
} from "@/app/v/[slug]/page";
import { OwnerAuthLayout } from "@/components/owner/OwnerAuthLayout";
import PrivacyPage from "@/app/privacy/page";

type SelectRecord = { table: string; columns: string };

function createTableRouter(
  handler: (table: string, columns: string) => {
    listData?: unknown;
    singleData?: unknown;
    error?: { message: string; code?: string } | null;
  },
) {
  const selects: SelectRecord[] = [];

  m.from.mockImplementation((table: string) => ({
    select: vi.fn((columns: string) => {
      selects.push({ table, columns });
      const resolved = handler(table, columns);
      const listResult = {
        data: resolved.listData ?? null,
        error: resolved.error ?? null,
      };
      const singleResult = {
        data: resolved.singleData ?? null,
        error: resolved.error ?? null,
      };

      const builder: Record<string, unknown> = {
        eq: () => builder,
        in: () => Promise.resolve(listResult),
        order: () => builder,
        limit: () => Promise.resolve(listResult),
        single: () => Promise.resolve(singleResult),
        maybeSingle: () => Promise.resolve(singleResult),
        then: (
          onFulfilled: (value: unknown) => unknown,
          onRejected?: (reason: unknown) => unknown,
        ) => Promise.resolve(listResult).then(onFulfilled, onRejected),
      };
      return builder;
    }),
  }));

  return selects;
}

const SAMPLE_STORE = {
  id: "11111111-1111-4111-8111-111111111111",
  slug: "ornek-magaza",
  name: "Örnek Mağaza",
  business_type: "Butik",
  description: "Kaliteli tekstil ürünleri",
  corporate_bio: "Kurumsal öykü",
  whatsapp: "905551112233",
  phone: "05551112233",
  email: "iletisim@ornek.test",
  hero_badge: null,
  instagram: "ornek",
  website: null,
  address: "Kadıköy, İstanbul",
  status: "Açık",
  marketplace_links: [],
  gallery_items: [],
  faq_items: [],
  about_kicker: null,
  about_title: null,
  about_image_url: null,
  about_image_caption: null,
  about_values: [],
  gallery_section_kicker: null,
  gallery_section_title: null,
  show_storefront_rating: false,
  show_directions_link: true,
  references_link: null,
  shelf_image_url: "https://cdn.vixrex.test/shelf.jpg",
  logo_url: "https://cdn.vixrex.test/logo.jpg",
  working_hours: null,
  is_published: true,
  is_demo: false,
  kategori: "Moda",
  latitude: null,
  longitude: null,
  google_business_link: null,
  business_verified_at: null,
  product_storage_version: 2,
  featured_banner_label: null,
  featured_banner_title: null,
  featured_banner_description: null,
  featured_banner_image_url: null,
  featured_banner_price_text: null,
  hero_location_text: null,
  map_label: null,
  province_name: "İstanbul",
  district_name: "Kadıköy",
  neighborhood_name: null,
  category_section_title: null,
  product_section_title: null,
  gallery_action_label: null,
  gallery_action_href: null,
  blog_section_kicker: null,
  blog_section_title: null,
  faq_section_kicker: null,
  faq_section_title: null,
  faq_section_description: null,
  section_visibility: null,
};

const SAMPLE_PRODUCT = {
  id: "22222222-2222-4222-8222-222222222222",
  name: "Keten Ceket",
  slug: "keten-ceket",
  description: "Yazlık keten ceket",
  price_text: "950 TL",
  price_amount: 950,
  old_price_amount: null,
  badge_tag: null,
  fulfillment_region: null,
  currency: "TRY",
  stock_status: "Mevcut",
  stock_quantity: 5,
  brand: "VixMarka",
  barcode: null,
  metadata: {},
  variants: [
    {
      id: "v1",
      options: { color: "Bej" },
      imageUrls: ["https://cdn.vixrex.test/variant-1.jpg"],
    },
  ],
  seo_title: null,
  seo_description: null,
  image_urls: ["https://cdn.vixrex.test/keten.jpg"],
  category_id: "33333333-3333-4333-8333-333333333333",
  is_visible: true,
  is_active: true,
  source_type: "manual",
};

describe("DB egress daraltma ve cache davranış sözleşmesi", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    m.cookie.mockReturnValue(undefined);
    m.verifyOwner.mockReturnValue(null);
    m.active.mockResolvedValue(false);
  });

  it("sitemap.xml dar kolonları seçer, revalidate 3600 ve SWR Cache-Control başlığı döner", async () => {
    const selects = createTableRouter((table) => {
      if (table === "stores") {
        return {
          listData: [
            {
              id: "store-1",
              slug: "ornek-butik",
              name: "Örnek Butik",
              updated_at: "2026-11-24T10:00:00.000Z",
              is_demo: false,
            },
            {
              id: "store-test",
              slug: "test-magaza",
              name: "Test Mağaza",
              updated_at: "2026-11-24T10:00:00.000Z",
              is_demo: false,
            },
          ],
        };
      }
      if (table === "products") {
        return {
          listData: [
            {
              store_id: "store-1",
              slug: "keten-ceket",
              name: "Keten Ceket",
              image_urls: ["https://cdn.vixrex.test/keten.jpg"],
              source_type: "manual",
              fatura_kanit: null,
              updated_at: "2026-11-24T11:00:00.000Z",
            },
          ],
        };
      }
      return {
        listData: [
          {
            store_slug: "ornek-butik",
            slug: "yaz-rehberi",
            updated_at: "2026-11-24T12:00:00.000Z",
          },
        ],
      };
    });

    const response = await sitemapGet();
    const xml = await response.text();

    expect(response.status).toBe(200);
    expect(sitemapRevalidate).toBe(3600);
    expect(m.unstableCache).toHaveBeenCalledWith(["sitemap"], {
      tags: ["sitemap"],
      revalidate: 3600,
    });
    expect(response.headers.get("Cache-Control")).toBe(
      "public, max-age=3600, s-maxage=3600, stale-while-revalidate=86400",
    );
    expect(response.headers.get("Cache-Control")).not.toContain("max-age=300");

    const storesSelect = selects.find((s) => s.table === "stores")?.columns ?? "";
    const productsSelect =
      selects.find((s) => s.table === "products")?.columns ?? "";
    expect(storesSelect).not.toContain("district_name");
    expect(storesSelect).not.toContain("province_name");
    expect(productsSelect).not.toContain("description");

    expect(xml).toContain("<loc>https://vixrex.test/v/ornek-butik</loc>");
    expect(xml).toContain(
      "<loc>https://vixrex.test/v/ornek-butik/urun/keten-ceket</loc>",
    );
    expect(xml).toContain(
      "<image:loc>https://cdn.vixrex.test/keten.jpg</image:loc>",
    );
    expect(xml).toContain(
      "<loc>https://vixrex.test/v/ornek-butik/yazilar/yaz-rehberi</loc>",
    );
    expect(xml).not.toContain("test-magaza");
  });

  it("urun/[productSlug] stores sorgusunda ölü products kolonunu istemez, revalidate 900 kullanır ve görseli iletir", async () => {
    const selects = createTableRouter((table, cols) => {
      if (table === "stores") {
        return { singleData: SAMPLE_STORE };
      }
      if (table === "products" && cols === "id,fatura_kanit") {
        return { singleData: { id: SAMPLE_PRODUCT.id, fatura_kanit: null } };
      }
      if (table === "products") {
        return { singleData: SAMPLE_PRODUCT };
      }
      if (table === "product_categories") {
        return { singleData: { id: SAMPLE_PRODUCT.category_id, name: "Dış Giyim" } };
      }
      return {};
    });

    const params = Promise.resolve({
      slug: SAMPLE_STORE.slug,
      productSlug: SAMPLE_PRODUCT.slug,
    });
    const metadata = await generateProductMetadata({ params });
    const element = await ProductDetailPage({ params });
    renderToStaticMarkup(element);

    expect(productRevalidate).toBe(900);
    expect(m.unstableCache).toHaveBeenCalledWith(
      [`product-${SAMPLE_STORE.slug}-${SAMPLE_PRODUCT.slug}`],
      expect.objectContaining({ revalidate: 900 }),
    );

    const storeSelectCols = (
      selects.find((s) => s.table === "stores")?.columns ?? ""
    )
      .split(",")
      .map((col) => col.trim());
    expect(storeSelectCols).not.toContain("products");
    expect(storeSelectCols).not.toContain("*");
    expect(selects.some((s) => s.table === "products" && s.columns === "id,fatura_kanit")).toBe(true);

    expect(metadata.title).toContain(SAMPLE_PRODUCT.name);
    expect(m.detailProps).toHaveBeenCalledOnce();
    const detailCall = m.detailProps.mock.calls[0][0] as {
      images: string[];
      storeName: string;
    };
    expect(detailCall.storeName).toBe(SAMPLE_STORE.name);
    expect(detailCall.images).toEqual(["https://cdn.vixrex.test/keten.jpg"]);
  });

  it("urun/[productSlug] izni bekleyen fatura ürününde görselleri maskeler ve olmayan üründe notFound fırlatır", async () => {
    createTableRouter((table, cols) => {
      if (table === "stores") {
        return { singleData: SAMPLE_STORE };
      }
      if (table === "products" && cols === "id,fatura_kanit") {
        return {
          singleData: {
            id: SAMPLE_PRODUCT.id,
            fatura_kanit: { gorselKaynaklari: [{ hakKayitDurumu: "unknown" }] },
          },
        };
      }
      if (table === "products") {
        return { singleData: { ...SAMPLE_PRODUCT, source_type: "invoice" } };
      }
      return { singleData: null };
    });

    const element = await ProductDetailPage({
      params: Promise.resolve({
        slug: SAMPLE_STORE.slug,
        productSlug: SAMPLE_PRODUCT.slug,
      }),
    });
    renderToStaticMarkup(element);

    const maskedCall = m.detailProps.mock.calls[0][0] as {
      images: string[];
      product: {
        imageUrls: string[];
        gorselIzinBekliyor?: boolean;
        variants?: Array<{ imageUrls?: string[] }>;
      };
    };
    expect(maskedCall.images).toEqual([]);
    expect(maskedCall.product.imageUrls).toEqual([]);
    expect(maskedCall.product.gorselIzinBekliyor).toBe(true);
    expect(maskedCall.product.variants?.[0]?.imageUrls).toEqual([]);

    createTableRouter((table) => {
      if (table === "stores") return { singleData: SAMPLE_STORE };
      return { singleData: null };
    });

    await expect(
      ProductDetailPage({
        params: Promise.resolve({
          slug: SAMPLE_STORE.slug,
          productSlug: "olmayan-urun",
        }),
      }),
    ).rejects.toThrow("NEXT_NOT_FOUND");
    expect(m.notFound).toHaveBeenCalled();

    const missingMeta = await generateProductMetadata({
      params: Promise.resolve({
        slug: SAMPLE_STORE.slug,
        productSlug: "olmayan-urun",
      }),
    });
    expect(missingMeta).toEqual({ robots: { index: false, follow: false } });
  });

  it("v/[slug]/yazilar BlogIndexPage select('*') kullanmaz, yazıları render eder ve boş listede notFound fırlatır", async () => {
    const selects = createTableRouter((table) => {
      if (table === "stores") {
        return {
          singleData: {
            slug: SAMPLE_STORE.slug,
            name: SAMPLE_STORE.name,
            logo_url: SAMPLE_STORE.logo_url,
            is_demo: false,
          },
        };
      }
      return {
        listData: [
          {
            id: "art-1",
            slug: "keten-bakim-rehberi",
            title: "Keten Bakım Rehberi",
            summary: "Keten kumaş nasıl ütülenir?",
            content: "Detaylı bakım adımları burada yer alır.",
            cover_image_url: "https://cdn.vixrex.test/yazi.jpg",
            article_type: "Rehber",
            published_at: "2026-11-20T09:00:00.000Z",
            created_at: "2026-11-19T09:00:00.000Z",
            target_city: "İstanbul",
          },
        ],
      };
    });

    const params = Promise.resolve({ slug: SAMPLE_STORE.slug });
    const meta = await generateBlogMetadata({ params });
    const html = renderToStaticMarkup(await BlogIndexPage({ params }));

    expect(blogIndexRevalidate).toBe(900);
    expect(m.unstableCache).toHaveBeenCalledWith(
      [`store-${SAMPLE_STORE.slug}`],
      { tags: [`store-${SAMPLE_STORE.slug}`], revalidate: 900 },
    );

    const articleCols = (
      selects.find((s) => s.table === "store_articles")?.columns ?? ""
    )
      .split(",")
      .map((col) => col.trim());
    expect(articleCols).not.toContain("*");
    expect(articleCols).toEqual(
      expect.arrayContaining([
        "id",
        "slug",
        "title",
        "summary",
        "content",
        "cover_image_url",
        "article_type",
        "published_at",
        "created_at",
        "target_city",
      ]),
    );

    expect(meta.title).toContain(SAMPLE_STORE.name);
    expect(html).toContain("Keten Bakım Rehberi");
    expect(html).toContain("Keten kumaş nasıl ütülenir?");
    expect(html).toContain("İstanbul");
    expect(html).toContain(
      `href="/v/${SAMPLE_STORE.slug}/yazilar/keten-bakim-rehberi"`,
    );

    createTableRouter((table) => {
      if (table === "stores") {
        return {
          singleData: {
            slug: SAMPLE_STORE.slug,
            name: SAMPLE_STORE.name,
            logo_url: null,
            is_demo: false,
          },
        };
      }
      return { listData: [] };
    });

    await expect(BlogIndexPage({ params })).rejects.toThrow("NEXT_NOT_FOUND");
  });

  it("v/[slug]/yazilar/[articleSlug] ArticleDetailPage select('*') kullanmaz, içeriği render eder ve olmayan makalede notFound fırlatır", async () => {
    const selects = createTableRouter(() => ({
      singleData: {
        slug: "keten-bakim-rehberi",
        title: "Keten Bakım Rehberi",
        summary: "Keten kumaş ömrünü uzatın.",
        content: "Soğuk suda nazik yıkama önerilir.",
        cover_image_url: "https://cdn.vixrex.test/yazi-kapak.jpg",
        article_type: "Rehber",
        target_city: "İstanbul",
        published_at: "2026-11-20T09:00:00.000Z",
        created_at: "2026-11-19T09:00:00.000Z",
        updated_at: "2026-11-21T09:00:00.000Z",
        store: {
          name: SAMPLE_STORE.name,
          logo_url: SAMPLE_STORE.logo_url,
          slug: SAMPLE_STORE.slug,
        },
      },
    }));

    const params = Promise.resolve({
      slug: SAMPLE_STORE.slug,
      articleSlug: "keten-bakim-rehberi",
    });
    const meta = await generateArticleMetadata({ params });
    const html = renderToStaticMarkup(await ArticleDetailPage({ params }));

    expect(articleDetailRevalidate).toBe(900);
    expect(m.unstableCache).toHaveBeenCalledWith(
      [`article-${SAMPLE_STORE.slug}-keten-bakim-rehberi`],
      {
        tags: [
          `store-${SAMPLE_STORE.slug}`,
          `article-${SAMPLE_STORE.slug}-keten-bakim-rehberi`,
        ],
        revalidate: 900,
      },
    );

    const articleSelect =
      selects.find((s) => s.table === "store_articles")?.columns ?? "";
    expect(articleSelect.trim().startsWith("*")).toBe(false);
    expect(articleSelect).not.toMatch(/(^|[,\s])\*([,\s]|$)/);
    expect(articleSelect).toContain("store:stores(name, logo_url, slug)");
    expect(articleSelect).toContain("updated_at");

    expect(meta.title).toContain("Keten Bakım Rehberi");
    expect(meta.alternates?.canonical).toBe(
      `/v/${SAMPLE_STORE.slug}/yazilar/keten-bakim-rehberi`,
    );
    expect(html).toContain("Keten Bakım Rehberi");
    expect(html).toContain("Keten kumaş ömrünü uzatın.");
    expect(html).toContain("Soğuk suda nazik yıkama önerilir.");
    expect(html).toContain(SAMPLE_STORE.name);

    createTableRouter(() => ({ singleData: null }));
    const missingParams = Promise.resolve({
      slug: SAMPLE_STORE.slug,
      articleSlug: "bulunamayan-yazi",
    });

    await expect(
      ArticleDetailPage({ params: missingParams }),
    ).rejects.toThrow("NEXT_NOT_FOUND");
    expect(await generateArticleMetadata({ params: missingParams })).toEqual({});
  });

  it("v/[slug]/page.tsx booking_settings ve store_articles sorgularında select('*') kullanmaz ve cache süresini 300sn tutar", async () => {
    const selects = createTableRouter((table, cols) => {
      if (table === "stores") {
        return { singleData: SAMPLE_STORE };
      }
      if (table === "booking_settings") {
        return {
          singleData: {
            is_enabled: true,
            capacity: 2,
            working_hours: {
              "1": { start: "09:00", end: "19:00", active: true },
            },
            lunch_break: { start: "12:00", end: "13:00", active: true },
          },
        };
      }
      if (table === "store_articles") {
        return {
          listData: [
            {
              id: "art-1",
              slug: "yazi-1",
              title: "Vitrin Yazısı",
              summary: "Kısa özet",
              content: "Yazı içeriği",
            },
          ],
        };
      }
      if (table === "product_categories") {
        return { listData: [] };
      }
      if (table === "products" && cols === "id,fatura_kanit") {
        return { listData: [] };
      }
      if (table === "products") {
        return { listData: [SAMPLE_PRODUCT] };
      }
      return {};
    });

    const params = Promise.resolve({ slug: SAMPLE_STORE.slug });
    const searchParams = Promise.resolve({});
    const meta = await generateStoreMetadata({ params, searchParams });
    const element = await StorePage({ params, searchParams });
    renderToStaticMarkup(element);

    expect(m.unstableCache).toHaveBeenCalledWith(
      [`store-${SAMPLE_STORE.slug}`],
      {
        tags: [`store-${SAMPLE_STORE.slug}`, `products-${SAMPLE_STORE.slug}`],
        revalidate: 300,
      },
    );

    const bookingCols = (
      selects.find((s) => s.table === "booking_settings")?.columns ?? ""
    )
      .split(",")
      .map((col) => col.trim());
    expect(bookingCols).not.toContain("*");
    expect(bookingCols).toEqual([
      "is_enabled",
      "capacity",
      "working_hours",
      "lunch_break",
    ]);

    const articleCols = (
      selects.find((s) => s.table === "store_articles")?.columns ?? ""
    )
      .split(",")
      .map((col) => col.trim());
    expect(articleCols).not.toContain("*");
    expect(articleCols).toEqual(["id", "slug", "title", "summary", "content"]);

    expect(
      selects.some((s) => s.table === "products" && s.columns === "id,fatura_kanit"),
    ).toBe(true);
    expect(meta.title).toContain(SAMPLE_STORE.name);
    expect(m.vitrinProps).toHaveBeenCalledOnce();
    const vitrinCall = m.vitrinProps.mock.calls[0][0] as {
      isBookingEnabled: boolean;
      articles: Array<{ title: string }>;
    };
    expect(vitrinCall.isBookingEnabled).toBe(true);
    expect(vitrinCall.articles).toHaveLength(1);
    expect(vitrinCall.articles[0].title).toBe("Vitrin Yazısı");

    createTableRouter(() => ({ singleData: null }));
    const missingParams = Promise.resolve({ slug: "olmayan-magaza" });
    await expect(
      StorePage({ params: missingParams, searchParams }),
    ).rejects.toThrow("NEXT_NOT_FOUND");
    expect(
      await generateStoreMetadata({ params: missingParams, searchParams }),
    ).toEqual({ robots: { index: false, follow: false } });
  });
});

describe("Google OAuth yasal link ve gizlilik politikası sözleşmesi", () => {
  it("OwnerAuthLayout /privacy ve /legal/terms linklerini koyu tema tokenlarıyla render eder", () => {
    const html = renderToStaticMarkup(
      createElement(
        OwnerAuthLayout,
        {
          title: "Google ile Devam Et",
          description: "Kalıcı erişim için giriş yap.",
        } as Parameters<typeof OwnerAuthLayout>[0],
        createElement("div", null, "İçerik"),
      ),
    );

    expect(html).toContain('href="/privacy"');
    expect(html).toContain("Gizlilik Politikası");
    expect(html).toContain('href="/legal/terms"');
    expect(html).toContain("Kullanım Şartları");
    expect(html).not.toContain('href="/terms"');
    expect(html).toContain("border-[var(--owner-border)]");
    expect(html).toContain("text-[var(--owner-muted)]");
  });

  it("privacy/page.tsx Bölüm 4 içinde Google Gemini API, OpenRouter ve Aksakal Ticaret bilgilerini barındırır", () => {
    const html = renderToStaticMarkup(createElement(PrivacyPage));

    expect(html).toContain("Google Gemini API");
    expect(html).toContain("OpenRouter");
    expect(html).toContain("Aksakal Ticaret");
    expect(html).toContain("Furkan Aksakal");
    expect(html).toContain("destek@vixrex.com");
    expect(html).toContain("KVKK");

    const geminiIdx = html.indexOf("Google Gemini API");
    const openRouterIdx = html.indexOf("OpenRouter");
    const bolum4Idx = html.indexOf("4. Verilerin Paylaşılması");
    const bolum5Idx = html.indexOf("5. Veri Saklama");

    expect(bolum4Idx).toBeGreaterThan(-1);
    expect(geminiIdx).toBeGreaterThan(bolum4Idx);
    expect(geminiIdx).toBeLessThan(bolum5Idx);
    expect(openRouterIdx).toBeGreaterThan(bolum4Idx);
    expect(openRouterIdx).toBeLessThan(bolum5Idx);
  });
});
