import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  from: vi.fn(),
  cookiesGet: vi.fn(),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: {
    from: mocks.from,
  },
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: vi.fn(() => ({})),
}));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({
    get: mocks.cookiesGet,
  })),
}));

vi.mock("next/navigation", () => ({
  notFound: vi.fn(() => {
    throw new Error("NEXT_NOT_FOUND");
  }),
}));

vi.mock("next/cache", () => ({
  unstable_cache: <T extends (...args: never[]) => unknown>(fn: T) => fn,
}));

vi.mock("@/components/ProductDetailExperience", () => ({
  default: () => null,
}));

vi.mock("@/components/VitrinCartDock", () => ({
  default: () => null,
}));

import { generateMetadata as generateProductMetadata } from "@/app/v/[slug]/urun/[productSlug]/page";
import { GET as getMerchantFeed } from "@/app/api/feeds/merchant.xml/route";
import { GET as getIndexNowKey } from "@/app/api/indexnow/key/route";
import { indexnowBildir } from "@/lib/indexnow";
import { webSiteJsonLd } from "@/lib/jsonLd";
import { MAX_PRODUCT_IMAGES } from "@/lib/productImagePolicy";

type MockError = {
  code?: string;
  message?: string;
} | null;

type MockResult<T = unknown> = {
  data: T;
  error: MockError;
};

type MockQueryBuilder<T = unknown> = {
  select: ReturnType<typeof vi.fn>;
  eq: ReturnType<typeof vi.fn>;
  in: ReturnType<typeof vi.fn>;
  order: ReturnType<typeof vi.fn>;
  single: ReturnType<typeof vi.fn>;
  maybeSingle: ReturnType<typeof vi.fn>;
  range?: ReturnType<typeof vi.fn>;
  then: PromiseLike<MockResult<T>>["then"];
};

function createQueryBuilder<T>(
  data: T,
  error: MockError = null,
): MockQueryBuilder<T> {
  const result: MockResult<T> = { data, error };
  const builder = {} as MockQueryBuilder<T>;
  builder.select = vi.fn(() => builder);
  builder.eq = vi.fn(() => builder);
  builder.in = vi.fn(() => builder);
  builder.order = vi.fn(() => builder);
  builder.single = vi.fn(async () => result);
  builder.maybeSingle = vi.fn(async () => result);
  builder.then = (onFulfilled, onRejected) =>
    Promise.resolve(result).then(onFulfilled, onRejected);
  return builder;
}

const VALID_STORE = {
  id: "store-aksakal",
  slug: "aksakal-butik",
  name: "Aksakal Butik",
  description: "Kadın ve çocuk giyim mağazası",
  is_demo: false,
  is_published: true,
};

function makeFeedProduct(overrides: Record<string, unknown> = {}) {
  return {
    id: "prod-1",
    store_id: "store-aksakal",
    name: "Keten Gömlek",
    slug: "keten-gomlek",
    description: "Yazlık doğal keten gömlek",
    price_amount: 1299.5,
    currency: "TRY",
    stock_status: "Mevcut",
    stock_quantity: 5,
    brand: "Aksakal",
    barcode: "8690000000005",
    image_urls: ["https://cdn.vixrex.com/products/keten-1.webp"],
    google_product_category: "Apparel & Accessories > Clothing > Shirts & Tops",
    is_active: true,
    is_visible: true,
    source_type: "manual",
    fatura_kanit: null,
    metadata: { itemKind: "physical" },
    ...overrides,
  };
}

describe("SEO, Google Merchant Feed ve IndexNow kurumsal sözleşmesi", () => {
  const originalSiteUrl = process.env.NEXT_PUBLIC_SITE_URL;
  const originalIndexNowKey = process.env.INDEXNOW_KEY;

  beforeEach(() => {
    vi.clearAllMocks();
    mocks.cookiesGet.mockReturnValue(undefined);
    process.env.NEXT_PUBLIC_SITE_URL = "https://vixrex.com";
    delete process.env.INDEXNOW_KEY;
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    if (originalSiteUrl === undefined) {
      delete process.env.NEXT_PUBLIC_SITE_URL;
    } else {
      process.env.NEXT_PUBLIC_SITE_URL = originalSiteUrl;
    }
    if (originalIndexNowKey === undefined) {
      delete process.env.INDEXNOW_KEY;
    } else {
      process.env.INDEXNOW_KEY = originalIndexNowKey;
    }
  });

  describe("Ürün detay generateMetadata (og:type çökme koruması)", () => {
    it("openGraph.type olarak geçerli 'website' üretir ('product' üretmez) ve tüm meta alanlarını döndürür", async () => {
      const storeRow = {
        ...VALID_STORE,
        shelf_image_url: "https://cdn.vixrex.com/stores/raf.webp",
        logo_url: "https://cdn.vixrex.com/stores/logo.webp",
      };
      const productRow = {
        id: "prod-1",
        name: "Keten Gömlek",
        slug: "keten-gomlek",
        description: "Doğal keten yazlık gömlek.",
        price_text: "1.299 TL",
        price_amount: 1299,
        currency: "TRY",
        stock_status: "Mevcut",
        stock_quantity: 4,
        brand: "Aksakal",
        barcode: "8690000000005",
        metadata: { itemKind: "physical" },
        variants: [],
        seo_title: null,
        seo_description: null,
        image_urls: ["https://cdn.vixrex.com/products/keten-1.webp"],
        category_id: "cat-1",
        is_visible: true,
        is_active: true,
        source_type: "manual",
      };

      mocks.from.mockImplementation((table: string) => {
        if (table === "stores") return createQueryBuilder(storeRow);
        if (table === "product_categories") {
          return createQueryBuilder({ id: "cat-1", name: "Gömlek" });
        }
        const builder = createQueryBuilder<unknown>(productRow);
        builder.select = vi.fn((cols: string) => {
          if (cols.includes("fatura_kanit")) {
            return createQueryBuilder({ id: "prod-1", fatura_kanit: null });
          }
          return builder;
        });
        return builder;
      });

      const meta = await generateProductMetadata({
        params: Promise.resolve({
          slug: "aksakal-butik",
          productSlug: "keten-gomlek",
        }),
      });

      const og = meta.openGraph as Record<string, unknown> | undefined;
      expect(og).toBeDefined();
      expect(og?.type).toBe("website");
      expect(og?.type).not.toBe("product");
      expect(meta.title).toBe("Keten Gömlek - Aksakal Butik | Vixrex");
      expect(meta.description).toBe("Doğal keten yazlık gömlek.");
      expect(meta.alternates?.canonical).toBe(
        "/v/aksakal-butik/urun/keten-gomlek",
      );
      expect(og?.url).toBe("https://vixrex.com/v/aksakal-butik/urun/keten-gomlek");
      expect(og?.images).toEqual([
        { url: "https://cdn.vixrex.com/products/keten-1.webp" },
      ]);
      expect(meta.twitter).toEqual({
        card: "summary_large_image",
        title: "Keten Gömlek - Aksakal Butik | Vixrex",
        description: "Doğal keten yazlık gömlek.",
        images: ["https://cdn.vixrex.com/products/keten-1.webp"],
      });
    });

    it("demo mağaza ürününde noindex ve follow: true döndürür", async () => {
      mocks.from.mockImplementation((table: string) => {
        if (table === "stores") {
          return createQueryBuilder({ ...VALID_STORE, is_demo: true });
        }
        return createQueryBuilder({
          id: "prod-demo",
          name: "Demo Ürün",
          slug: "demo-urun",
          description: null,
          price_text: "100 TL",
          price_amount: 100,
          currency: "TRY",
          stock_status: "Mevcut",
          stock_quantity: 2,
          brand: null,
          barcode: null,
          metadata: {},
          variants: [],
          seo_title: null,
          seo_description: null,
          image_urls: ["https://cdn.vixrex.com/products/demo.webp"],
          category_id: null,
          is_visible: true,
          is_active: true,
          source_type: "manual",
        });
      });

      const meta = await generateProductMetadata({
        params: Promise.resolve({
          slug: "aksakal-butik",
          productSlug: "demo-urun",
        }),
      });

      expect(meta.robots).toEqual({ index: false, follow: true });
    });
  });

  describe("GET /api/feeds/merchant.xml", () => {
    it("is_demo ve isTestOrDenemeStore (deneme-vitrin, test-magaza, asdf-123) mağaza ürünlerini eler", async () => {
      const storesBuilder = createQueryBuilder([
        VALID_STORE,
        {
          id: "store-demo",
          slug: "kiralik-vitrin",
          name: "Kiralık Vitrin",
          description: null,
          is_demo: true,
          is_published: true,
        },
        {
          id: "store-deneme",
          slug: "deneme-vitrin",
          name: "Butik",
          description: null,
          is_demo: false,
          is_published: true,
        },
        {
          id: "store-test",
          slug: "test-magaza",
          name: "Mağaza",
          description: null,
          is_demo: false,
          is_published: true,
        },
        {
          id: "store-junk",
          slug: "asdf-123",
          name: "Vitrin",
          description: null,
          is_demo: false,
          is_published: true,
        },
      ]);

      const productsBuilder = createQueryBuilder([
        makeFeedProduct({ id: "gercek-1", store_id: "store-aksakal", slug: "gercek-urun" }),
        makeFeedProduct({ id: "demo-1", store_id: "store-demo", slug: "demo-urun" }),
        makeFeedProduct({ id: "deneme-1", store_id: "store-deneme", slug: "deneme-urun" }),
        makeFeedProduct({ id: "test-1", store_id: "store-test", slug: "test-urun" }),
        makeFeedProduct({ id: "junk-1", store_id: "store-junk", slug: "junk-urun" }),
      ]);

      mocks.from.mockImplementation((table: string) =>
        table === "stores" ? storesBuilder : productsBuilder,
      );

      const res = await getMerchantFeed();
      const xml = await res.text();

      expect(res.status).toBe(200);
      expect(storesBuilder.eq).toHaveBeenCalledWith("is_published", true);
      expect(storesBuilder.eq).toHaveBeenCalledWith("is_demo", false);
      expect(productsBuilder.in).toHaveBeenCalledWith("store_id", ["store-aksakal"]);
      expect(xml).toContain("<g:id>gercek-1</g:id>");
      expect(xml).not.toContain("demo-1");
      expect(xml).not.toContain("deneme-1");
      expect(xml).not.toContain("test-1");
      expect(xml).not.toContain("junk-1");
    });

    it("fatura ürünlerinde telif izni yoksa fail-closed eler; verified_supplier_permission ile beslemeye alır ve ticari sır sızdırmaz", async () => {
      mocks.from.mockImplementation((table: string) => {
        if (table === "stores") return createQueryBuilder([VALID_STORE]);
        return createQueryBuilder([
          makeFeedProduct({
            id: "inv-null",
            slug: "inv-null",
            source_type: "invoice",
            fatura_kanit: null,
          }),
          makeFeedProduct({
            id: "inv-empty",
            slug: "inv-empty",
            source_type: "invoice",
            fatura_kanit: { gorselKaynaklari: [] },
          }),
          makeFeedProduct({
            id: "inv-unknown",
            slug: "inv-unknown",
            source_type: "invoice",
            fatura_kanit: {
              gorselKaynaklari: [{ hakKayitDurumu: "unknown" }],
            },
          }),
          makeFeedProduct({
            id: "inv-denied",
            slug: "inv-denied",
            source_type: "invoice",
            fatura_kanit: {
              gorselKaynaklari: [{ hakKayitDurumu: "denied" }],
            },
          }),
          makeFeedProduct({
            id: "inv-verified",
            slug: "inv-verified",
            source_type: "invoice",
            fatura_kanit: {
              tedarikciVkn: "1234567890",
              ettn: "f47ac10b-58cc-4372-a567-0e02b2c3d479",
              alisFiyati: 450,
              gorselKaynaklari: [
                { hakKayitDurumu: "verified_supplier_permission" },
              ],
            },
          }),
        ]);
      });

      const res = await getMerchantFeed();
      const xml = await res.text();

      expect(res.status).toBe(200);
      expect(xml).toContain("<g:id>inv-verified</g:id>");
      expect(xml).not.toContain("inv-null");
      expect(xml).not.toContain("inv-empty");
      expect(xml).not.toContain("inv-unknown");
      expect(xml).not.toContain("inv-denied");
      expect(xml).not.toContain("1234567890");
      expect(xml).not.toContain("f47ac10b-58cc-4372-a567-0e02b2c3d479");
      expect(xml).not.toContain("450");
    });

    it("hizmet, fiyatsız/0 fiyatlı ve geçerli https görseli olmayan ürünleri eler; ek görselleri MAX_PRODUCT_IMAGES sınırıyla basar", async () => {
      const cokluGorsel = Array.from(
        { length: MAX_PRODUCT_IMAGES + 2 },
        (_, idx) => `https://cdn.vixrex.com/products/coklu-${idx + 1}.webp`,
      );

      mocks.from.mockImplementation((table: string) => {
        if (table === "stores") return createQueryBuilder([VALID_STORE]);
        return createQueryBuilder([
          makeFeedProduct({
            id: "srv-1",
            slug: "sac-kesimi",
            metadata: { itemKind: "service" },
          }),
          makeFeedProduct({
            id: "no-price",
            slug: "fiyatsiz-urun",
            price_amount: null,
          }),
          makeFeedProduct({
            id: "zero-price",
            slug: "sifir-fiyat",
            price_amount: 0,
          }),
          makeFeedProduct({
            id: "neg-price",
            slug: "eksi-fiyat",
            price_amount: -25,
          }),
          makeFeedProduct({
            id: "no-img",
            slug: "gorselsiz",
            image_urls: [],
          }),
          makeFeedProduct({
            id: "http-img",
            slug: "http-gorsel",
            image_urls: ["http://cdn.vixrex.com/products/guvensiz.jpg"],
          }),
          makeFeedProduct({
            id: "mascot-img",
            slug: "maskot-gorsel",
            image_urls: [
              "/images/vixrex_v_crystal_mascot.webp",
              "https://vixrex.com/images/vixrex_v_crystal_mascot.webp",
            ],
          }),
          makeFeedProduct({
            id: "screenshot-img",
            slug: "ekran-goruntusu",
            image_urls: ["https://cdn.vixrex.com/products/screenshot-panel.png"],
          }),
          makeFeedProduct({
            id: "valid-multi",
            slug: "coklu-gorsel-urun",
            currency: "tl",
            image_urls: cokluGorsel,
          }),
        ]);
      });

      const res = await getMerchantFeed();
      const xml = await res.text();

      expect(res.status).toBe(200);
      expect(xml).not.toContain("srv-1");
      expect(xml).not.toContain("no-price");
      expect(xml).not.toContain("zero-price");
      expect(xml).not.toContain("neg-price");
      expect(xml).not.toContain("no-img");
      expect(xml).not.toContain("http-img");
      expect(xml).not.toContain("mascot-img");
      expect(xml).not.toContain("screenshot-img");

      expect(xml).toContain("<g:id>valid-multi</g:id>");
      expect(xml).toContain("<g:price>1299.50 TRY</g:price>");
      expect(xml).toContain(
        "<g:image_link>https://cdn.vixrex.com/products/coklu-1.webp</g:image_link>",
      );
      expect(xml.match(/<g:additional_image_link>/g)).toHaveLength(
        MAX_PRODUCT_IMAGES - 1,
      );
      expect(xml).not.toContain(`coklu-${MAX_PRODUCT_IMAGES + 1}.webp`);
    });

    it("Türkçe 'Tükendi', 'Stokta yok', 'Mevcut değil' ve stock_quantity: 0 ürünlerinde out_of_stock üretir", async () => {
      mocks.from.mockImplementation((table: string) => {
        if (table === "stores") return createQueryBuilder([VALID_STORE]);
        return createQueryBuilder([
          makeFeedProduct({
            id: "tukendi-1",
            slug: "tukendi-1",
            stock_status: "Tükendi",
            stock_quantity: null,
          }),
          makeFeedProduct({
            id: "stokta-yok-1",
            slug: "stokta-yok-1",
            stock_status: "Stokta yok",
            stock_quantity: 3,
          }),
          makeFeedProduct({
            id: "mevcut-degil-1",
            slug: "mevcut-degil-1",
            stock_status: "Mevcut değil",
            stock_quantity: null,
          }),
          makeFeedProduct({
            id: "sifir-adet-1",
            slug: "sifir-adet-1",
            stock_status: "Mevcut",
            stock_quantity: 0,
          }),
          makeFeedProduct({
            id: "stokta-var-1",
            slug: "stokta-var-1",
            stock_status: "Mevcut",
            stock_quantity: 2,
          }),
        ]);
      });

      const res = await getMerchantFeed();
      const xml = await res.text();

      expect(res.status).toBe(200);
      expect(xml.match(/<g:availability>out_of_stock<\/g:availability>/g)).toHaveLength(4);
      expect(xml.match(/<g:availability>in_stock<\/g:availability>/g)).toHaveLength(1);
    });

    it("hatalı check-digit ve 2000000000008 dahili barkodu eler, identifier_exists=no basar; geçerli EAN-13 ve MPN kurallarını uygular", async () => {
      mocks.from.mockImplementation((table: string) => {
        if (table === "stores") return createQueryBuilder([VALID_STORE]);
        return createQueryBuilder([
          makeFeedProduct({
            id: "bad-check",
            slug: "bad-check",
            barcode: "8690000000001",
            brand: null,
          }),
          makeFeedProduct({
            id: "internal-gtin",
            slug: "internal-gtin",
            barcode: "2000000000008",
            brand: "Aksakal",
          }),
          makeFeedProduct({
            id: "valid-gtin",
            slug: "valid-gtin",
            barcode: "8690000000005",
            brand: "Alize",
          }),
          makeFeedProduct({
            id: "valid-mpn",
            slug: "valid-mpn",
            barcode: null,
            brand: "İzeltaş",
            metadata: {
              itemKind: "physical",
              identifiers: { mpn: "IZL-4500" },
              attributes: [{ key: "condition", value: "refurbished" }],
            },
          }),
        ]);
      });

      const res = await getMerchantFeed();
      const xml = await res.text();

      expect(res.status).toBe(200);
      expect(xml).not.toContain("8690000000001");
      expect(xml).not.toContain("2000000000008");
      expect(xml).toContain("<g:gtin>8690000000005</g:gtin>");
      expect(xml).toContain("<g:mpn>IZL-4500</g:mpn>");
      expect(xml).toContain("<g:condition>refurbished</g:condition>");
      expect(xml.match(/<g:identifier_exists>no<\/g:identifier_exists>/g)).toHaveLength(2);
    });

    it("google_product_category sütunu yokken (42703) fallback sorgusuyla 200 döner; gerçek DB hatasında 500 döner", async () => {
      let productCallCount = 0;
      const selectedColsList: string[] = [];

      mocks.from.mockImplementation((table: string) => {
        if (table === "stores") return createQueryBuilder([VALID_STORE]);
        productCallCount += 1;
        if (productCallCount === 1) {
          const failBuilder = createQueryBuilder<unknown[]>(null as unknown as unknown[], {
            code: "42703",
            message: "column products.google_product_category does not exist",
          });
          failBuilder.select = vi.fn((cols: string) => {
            selectedColsList.push(cols);
            return failBuilder;
          });
          return failBuilder;
        }
        const okBuilder = createQueryBuilder([
          makeFeedProduct({
            id: "fallback-ok",
            slug: "fallback-ok",
            google_product_category: undefined,
          }),
        ]);
        okBuilder.select = vi.fn((cols: string) => {
          selectedColsList.push(cols);
          return okBuilder;
        });
        return okBuilder;
      });

      const okRes = await getMerchantFeed();
      const okXml = await okRes.text();

      expect(okRes.status).toBe(200);
      expect(productCallCount).toBe(2);
      expect(selectedColsList[0]).toContain("google_product_category");
      expect(selectedColsList[1]).not.toContain("google_product_category");
      expect(okXml).toContain("<g:id>fallback-ok</g:id>");

      mocks.from.mockImplementation((table: string) => {
        if (table === "stores") return createQueryBuilder([VALID_STORE]);
        return createQueryBuilder<unknown[]>(null as unknown as unknown[], {
          code: "42P01",
          message: "relation does not exist",
        });
      });

      const errRes = await getMerchantFeed();
      expect(errRes.status).toBe(500);
      expect(await errRes.text()).toBe("Feed generation failed");
    });

    it("XML özel karakterlerini (&, <, >, \", ') güvenli biçimde kaçırır", async () => {
      mocks.from.mockImplementation((table: string) => {
        if (table === "stores") return createQueryBuilder([VALID_STORE]);
        return createQueryBuilder([
          makeFeedProduct({
            id: "escape-1",
            slug: "escape-urun",
            name: `Keten & İpek <Özel> "Seri" '2026'`,
            description: `Boyut <L> & >M "Pamuk" 'Saf'`,
            brand: `Aksakal & Co <TR>`,
            image_urls: ["https://cdn.vixrex.com/products/urun.webp?a=1&b=2"],
          }),
        ]);
      });

      const res = await getMerchantFeed();
      const xml = await res.text();

      expect(res.status).toBe(200);
      expect(xml).toContain(
        "<title>Keten &amp; İpek &lt;Özel&gt; &quot;Seri&quot; &apos;2026&apos;</title>",
      );
      expect(xml).toContain(
        "<description>Boyut &lt;L&gt; &amp; &gt;M &quot;Pamuk&quot; &apos;Saf&apos;</description>",
      );
      expect(xml).toContain("<g:brand>Aksakal &amp; Co &lt;TR&gt;</g:brand>");
      expect(xml).toContain(
        "<g:image_link>https://cdn.vixrex.com/products/urun.webp?a=1&amp;b=2</g:image_link>",
      );
    });

    it("1000 satır sınırını aşan ürünlerde range ile tüm sayfaları eksiksiz birleştirir", async () => {
      const ilkSayfa = Array.from({ length: 1000 }, (_, idx) =>
        makeFeedProduct({
          id: `page1-${idx + 1}`,
          slug: `urun-p1-${idx + 1}`,
        }),
      );
      const ikinciSayfa = [
        makeFeedProduct({ id: "page2-1001", slug: "urun-p2-1001" }),
        makeFeedProduct({ id: "page2-1002", slug: "urun-p2-1002" }),
      ];

      const rangeCalls: Array<[number, number]> = [];
      mocks.from.mockImplementation((table: string) => {
        if (table === "stores") return createQueryBuilder([VALID_STORE]);
        const builder = createQueryBuilder<unknown[]>([]);
        builder.range = vi.fn(async (from: number, to: number) => {
          rangeCalls.push([from, to]);
          return {
            data: from === 0 ? ilkSayfa : ikinciSayfa,
            error: null,
          };
        });
        return builder;
      });

      const res = await getMerchantFeed();
      const xml = await res.text();

      expect(res.status).toBe(200);
      expect(rangeCalls).toEqual([
        [0, 999],
        [1000, 1999],
      ]);
      expect(xml).toContain("<g:id>page1-1</g:id>");
      expect(xml).toContain("<g:id>page1-1000</g:id>");
      expect(xml).toContain("<g:id>page2-1002</g:id>");
    });
  });

  describe("IndexNow doğrulama ucu ve bildirim yardımcısı", () => {
    it("INDEXNOW_KEY tanımsız veya geçersizken /api/indexnow/key 404 döner ve indexnowBildir fetch çağırmaz", async () => {
      const fetchMock = vi.fn();
      vi.stubGlobal("fetch", fetchMock);

      for (const badKey of ["", "kisa123", "gecersiz_anahtar_altcizgi", "bosluk var 12345"]) {
        process.env.INDEXNOW_KEY = badKey;
        const res = await getIndexNowKey();
        expect(res.status).toBe(404);
        await indexnowBildir(["https://vixrex.com/v/aksakal-butik"]);
      }

      delete process.env.INDEXNOW_KEY;
      const missingRes = await getIndexNowKey();
      expect(missingRes.status).toBe(404);
      await indexnowBildir(["https://vixrex.com/v/aksakal-butik"]);

      expect(fetchMock).not.toHaveBeenCalled();
    });

    it("geçerli INDEXNOW_KEY ile /api/indexnow/key 200 döner, indexnowBildir doğru yük gönderir ve ağ hatasını yutar", async () => {
      const validKey = "vixrex-indexnow-test-key-2026";
      process.env.INDEXNOW_KEY = `  ${validKey}  `;

      const keyRes = await getIndexNowKey();
      expect(keyRes.status).toBe(200);
      expect(await keyRes.text()).toBe(validKey);

      const fetchMock = vi.fn().mockResolvedValue({ ok: true, status: 200 });
      vi.stubGlobal("fetch", fetchMock);

      await indexnowBildir(["  https://vixrex.com/v/aksakal-butik  ", ""]);

      expect(fetchMock).toHaveBeenCalledTimes(1);
      const [endpoint, init] = fetchMock.mock.calls[0] as [
        string,
        RequestInit,
      ];
      expect(endpoint).toBe("https://api.indexnow.org/indexnow");
      expect(init.method).toBe("POST");
      expect(init.signal).toBeInstanceOf(AbortSignal);
      expect(JSON.parse(String(init.body))).toEqual({
        host: "vixrex.com",
        key: validKey,
        keyLocation: "https://vixrex.com/api/indexnow/key",
        urlList: ["https://vixrex.com/v/aksakal-butik"],
      });

      fetchMock.mockRejectedValueOnce(new Error("IndexNow network timeout"));
      await expect(
        indexnowBildir(["https://vixrex.com/v/aksakal-butik"]),
      ).resolves.toBeUndefined();
    });
  });

  describe("webSiteJsonLd SearchAction", () => {
    it("SearchAction ve /kesfet?q={search_term_string} hedefini eksiksiz üretir", () => {
      const schema = webSiteJsonLd("https://vixrex.com");

      expect(schema).toMatchObject({
        "@context": "https://schema.org",
        "@type": "WebSite",
        name: "Vixrex",
        url: "https://vixrex.com",
        potentialAction: {
          "@type": "SearchAction",
          target: "https://vixrex.com/kesfet?q={search_term_string}",
          "query-input": "required name=search_term_string",
        },
      });
    });
  });
});
