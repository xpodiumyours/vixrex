import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { NextRequest } from "next/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const h = vi.hoisted(() => ({
  supabaseRpc: vi.fn(),
  supabaseFrom: vi.fn(),
  adminRpc: vi.fn(),
  getSupabaseAdmin: vi.fn(),
  getClientIp: vi.fn(),
  fingerprintClient: vi.fn(),
  cookieGet: vi.fn(),
  verifyOwnerSession: vi.fn(),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: {
    rpc: h.supabaseRpc,
    from: h.supabaseFrom,
  },
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: h.getSupabaseAdmin,
}));

vi.mock("@/lib/rentDemoSecurity", () => ({
  getClientIp: h.getClientIp,
  fingerprintClient: h.fingerprintClient,
}));

vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: h.verifyOwnerSession,
}));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({ get: h.cookieGet })),
}));

vi.mock("next/cache", () => ({
  unstable_cache: (loader: () => unknown) => loader,
  revalidateTag: vi.fn(),
}));

vi.mock("@/lib/siteUrl", () => ({
  getSiteUrl: () => "https://vixrex.test",
}));

import { GET as yakinGet } from "@/app/api/kesfet/yakin/route";
import { GET as sitemapGet } from "@/app/sitemap.xml/route";
import { GET as appointmentsGet } from "@/app/api/appointments/route";

const migrationSql = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20261122110500_postgis_search_path_ve_hold_temizlik.sql",
  ),
  "utf8",
);

type QueryResult = {
  data: unknown[];
  error: null;
};

type QueryBuilder = {
  select: ReturnType<typeof vi.fn>;
  eq: ReturnType<typeof vi.fn>;
  then: PromiseLike<QueryResult>["then"];
};

function createSitemapQueryBuilder(data: unknown[]): QueryBuilder {
  const result: QueryResult = { data, error: null };
  const builder = {} as QueryBuilder;
  builder.select = vi.fn(() => builder);
  builder.eq = vi.fn(() => builder);
  builder.then = (onFulfilled, onRejected) =>
    Promise.resolve(result).then(onFulfilled, onRejected);
  return builder;
}

function mockSitemapTables(tables: Record<string, unknown[]>) {
  const queries: Record<string, QueryBuilder> = {};
  for (const [tablo, satirlar] of Object.entries(tables)) {
    queries[tablo] = createSitemapQueryBuilder(satirlar);
  }
  h.supabaseFrom.mockImplementation((tablo: string) => queries[tablo]);
}

function mockExploreProducts(rows: Array<{ store_id: string; name: string | null }> = []) {
  const eqVisible = vi.fn().mockResolvedValue({ data: rows, error: null });
  const eqActive = vi.fn().mockReturnValue({ eq: eqVisible });
  const inFn = vi.fn().mockReturnValue({ eq: eqActive });
  const select = vi.fn().mockReturnValue({ in: inFn });
  h.supabaseFrom.mockReturnValue({ select });
}

type UpdateCall = { method: "update" | "eq" | "lte"; args: unknown[] };

function createAppointmentsAdmin(options: {
  updateError?: { message: string } | null;
  rows?: unknown[];
} = {}) {
  const updateCalls: UpdateCall[] = [];
  const updateResult = { error: options.updateError ?? null };

  const updateChain = {} as {
    eq: ReturnType<typeof vi.fn>;
    lte: ReturnType<typeof vi.fn>;
    then: PromiseLike<typeof updateResult>["then"];
  };
  updateChain.eq = vi.fn((...args: unknown[]) => {
    updateCalls.push({ method: "eq", args });
    return updateChain;
  });
  updateChain.lte = vi.fn((...args: unknown[]) => {
    updateCalls.push({ method: "lte", args });
    return updateChain;
  });
  updateChain.then = (onFulfilled, onRejected) =>
    Promise.resolve(updateResult).then(onFulfilled, onRejected);

  const update = vi.fn((payload: unknown) => {
    updateCalls.push({ method: "update", args: [payload] });
    return updateChain;
  });

  const selectChain = {} as {
    eq: ReturnType<typeof vi.fn>;
    order: ReturnType<typeof vi.fn>;
  };
  selectChain.eq = vi.fn(() => selectChain);
  selectChain.order = vi.fn(() =>
    Promise.resolve({ data: options.rows ?? [], error: null }),
  );
  const select = vi.fn(() => selectChain);

  const from = vi.fn(() => ({ update, select }));

  return { from, update, updateCalls, updateResult };
}

afterEach(() => {
  delete process.env.VERCEL_ENV;
});

describe("PostGIS search_path ve hold temizliği migration sözleşmesi", () => {
  it("üç fonksiyonun tamamında search_path pg_catalog ile başlar", () => {
    const searchPaths = [...migrationSql.matchAll(/SET search_path = ([^;\n]+)/g)].map(
      (eslesme) => eslesme[1].trim(),
    );

    expect(searchPaths.length).toBeGreaterThanOrEqual(3);
    for (const searchPath of searchPaths) {
      expect(searchPath.startsWith("pg_catalog")).toBe(true);
    }

    expect(migrationSql).toContain("public.stores_sync_location_geography()");
    expect(migrationSql).toContain("public.search_nearby_stores(");
    expect(migrationSql).toContain("public.create_product_hold(");
  });

  it("fonksiyon yetkilerini daraltır: hold yalnız service_role, yakın arama geniş kitle", () => {
    expect(migrationSql).toMatch(
      /REVOKE ALL ON FUNCTION public\.stores_sync_location_geography\(\) FROM PUBLIC, anon, authenticated;/,
    );
    expect(migrationSql).toMatch(
      /REVOKE ALL ON FUNCTION public\.search_nearby_stores\([^)]+\) FROM PUBLIC;/,
    );
    expect(migrationSql).toMatch(
      /GRANT EXECUTE ON FUNCTION public\.search_nearby_stores\([^)]+\) TO anon, authenticated, service_role;/,
    );
    expect(migrationSql).toMatch(
      /REVOKE ALL ON FUNCTION public\.create_product_hold\([^)]+\) FROM PUBLIC, anon, authenticated;/,
    );
    expect(migrationSql).toMatch(
      /GRANT EXECUTE ON FUNCTION public\.create_product_hold\([^)]+\) TO service_role;/,
    );
  });

  it("süresi dolmuş bekleyen kilitleri aktif kilit sayımından önce expired yapar", () => {
    const temizlikIndeksi = migrationSql.indexOf("UPDATE public.appointments");
    const sayimIndeksi = migrationSql.indexOf("INTO v_active_holds");

    expect(temizlikIndeksi).toBeGreaterThan(-1);
    expect(sayimIndeksi).toBeGreaterThan(temizlikIndeksi);
    expect(migrationSql).toMatch(
      /UPDATE public\.appointments\s+SET status = 'expired'\s+WHERE product_id = v_product\.id\s+AND reservation_kind = 'product_hold'\s+AND status = 'pending'\s+AND expires_at <= now\(\);/,
    );
  });

  it("düz metin token veritabanına yazılmaz, yalnız hash yazılır ve token yanıtta döner", () => {
    const insertBaslangic = migrationSql.indexOf("INSERT INTO public.appointments");
    const insertBitis = migrationSql.indexOf("IF v_store_user_id", insertBaslangic);
    const insertBlogu = migrationSql.slice(insertBaslangic, insertBitis);

    expect(insertBaslangic).toBeGreaterThan(-1);
    expect(insertBlogu).not.toContain("v_plaintext_token");
    expect(insertBlogu).toMatch(/v_token_hash,\s*\n\s*v_token_hash,/);
    expect(migrationSql).toMatch(/'token', v_plaintext_token/);
  });

  it("girdi sınırlarını ve günlük product_hold limitini korur", () => {
    expect(migrationSql).toContain("char_length(v_customer_name) NOT BETWEEN 2 AND 120");
    expect(migrationSql).toContain("char_length(v_customer_phone) NOT BETWEEN 7 AND 32");
    expect(migrationSql).toContain("char_length(v_customer_notes) > 240");
    expect(migrationSql).toMatch(
      /WHERE customer_phone = v_customer_phone\s+AND reservation_kind = 'product_hold'\s+AND created_at > now\(\) - interval '24 hours';/,
    );
    expect(migrationSql).toContain("FOR UPDATE OF p");
    expect(migrationSql).toContain("INSERT INTO public.notification_inbox");
  });
});

describe("GET /api/kesfet/yakin oran sınırı", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    h.getClientIp.mockReturnValue("203.0.113.7");
    h.fingerprintClient.mockReturnValue("parmak-izi-abc");
    h.getSupabaseAdmin.mockReturnValue({ rpc: h.adminRpc });
    h.supabaseRpc.mockResolvedValue({ data: [], error: null });
    mockExploreProducts();
  });

  it("kota aşıldığında 429 ve Retry-After döner, vitrin sorgusu çalışmaz", async () => {
    h.adminRpc.mockResolvedValue({
      data: [{ allowed: false, retry_after_seconds: 42 }],
      error: null,
    });

    const response = await yakinGet(
      new NextRequest("http://localhost/api/kesfet/yakin?lat=41.0082&lng=28.9784"),
    );

    expect(response.status).toBe(429);
    expect(response.headers.get("Retry-After")).toBe("42");
    expect(h.adminRpc).toHaveBeenCalledWith("consume_assistant_request", {
      p_client_key: "kesfet_yakin:ip:parmak-izi-abc",
      p_max_requests: 60,
      p_window_seconds: 60,
    });
    expect(h.supabaseRpc).not.toHaveBeenCalled();
  });

  it("kota izin verdiğinde vitrin listesini 200 ile döner", async () => {
    h.adminRpc.mockResolvedValue({ data: [{ allowed: true }], error: null });

    const response = await yakinGet(
      new NextRequest("http://localhost/api/kesfet/yakin?lat=41.0082&lng=28.9784"),
    );
    const body = (await response.json()) as { vitrinler: unknown[] };

    expect(response.status).toBe(200);
    expect(body.vitrinler).toEqual([]);
    expect(h.adminRpc).toHaveBeenCalledTimes(1);
  });

  it("geçersiz koordinatta 400 döner ve kota sayacı hiç çağrılmaz", async () => {
    const response = await yakinGet(
      new NextRequest("http://localhost/api/kesfet/yakin?lat=999&lng=28.9784"),
    );

    expect(response.status).toBe(400);
    expect(h.adminRpc).not.toHaveBeenCalled();
  });

  it("üretimde admin istemcisi kurulamazsa 503 döner", async () => {
    process.env.VERCEL_ENV = "production";
    h.getSupabaseAdmin.mockImplementation(() => {
      throw new Error("SUPABASE_URL is missing");
    });

    const response = await yakinGet(
      new NextRequest("http://localhost/api/kesfet/yakin?lat=41.0082&lng=28.9784"),
    );

    expect(response.status).toBe(503);
    expect(h.supabaseRpc).not.toHaveBeenCalled();
  });

  it("üretim dışında admin istemcisi yoksa oran sınırını atlar ve listeyi döner", async () => {
    h.getSupabaseAdmin.mockImplementation(() => {
      throw new Error("SUPABASE_URL is missing");
    });

    const response = await yakinGet(
      new NextRequest("http://localhost/api/kesfet/yakin?lat=41.0082&lng=28.9784"),
    );

    expect(response.status).toBe(200);
    expect(h.adminRpc).not.toHaveBeenCalled();
  });

  it("üretimde sayaç hatası 503 döner", async () => {
    process.env.VERCEL_ENV = "production";
    h.adminRpc.mockResolvedValue({ data: null, error: { message: "rpc down" } });

    const response = await yakinGet(
      new NextRequest("http://localhost/api/kesfet/yakin?lat=41.0082&lng=28.9784"),
    );

    expect(response.status).toBe(503);
  });
});

describe("GET /api/appointments süresi dolmuş kilit temizliği", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    h.cookieGet.mockReturnValue({ value: "gecerli-cerez" });
    h.verifyOwnerSession.mockImplementation((cerez: unknown) =>
      cerez ? { storeId: "store-1" } : null,
    );
  });

  it("sahip doğrulandıktan sonra pending product_hold kayıtlarını expired yapar", async () => {
    const admin = createAppointmentsAdmin({ rows: [] });
    h.getSupabaseAdmin.mockReturnValue({ from: admin.from });

    const response = await appointmentsGet(
      new NextRequest("http://localhost/api/appointments?slug=ornek-magaza"),
    );

    expect(response.status).toBe(200);
    expect(admin.update).toHaveBeenCalledWith({ status: "expired" });

    const eqArgumanlari = admin.updateCalls
      .filter((cagri) => cagri.method === "eq")
      .map((cagri) => cagri.args);
    expect(eqArgumanlari).toContainEqual(["store_slug", "ornek-magaza"]);
    expect(eqArgumanlari).toContainEqual(["reservation_kind", "product_hold"]);
    expect(eqArgumanlari).toContainEqual(["status", "pending"]);

    const lteCagrisi = admin.updateCalls.find((cagri) => cagri.method === "lte");
    expect(lteCagrisi?.args[0]).toBe("expires_at");
    expect(typeof lteCagrisi?.args[1]).toBe("string");
  });

  it("temizlik hatası randevu listesini düşürmez", async () => {
    const admin = createAppointmentsAdmin({
      updateError: { message: "cleanup failed" },
      rows: [{ id: "randevu-1" }],
    });
    h.getSupabaseAdmin.mockReturnValue({ from: admin.from });

    const response = await appointmentsGet(
      new NextRequest("http://localhost/api/appointments?slug=ornek-magaza"),
    );
    const body = (await response.json()) as { tamam: boolean; randevular: unknown[] };

    expect(response.status).toBe(200);
    expect(body.tamam).toBe(true);
    expect(body.randevular).toEqual([{ id: "randevu-1" }]);
  });

  it("sahip çerezi yoksa 401 döner ve temizlik çalışmaz", async () => {
    h.cookieGet.mockReturnValue(undefined);
    const admin = createAppointmentsAdmin();
    h.getSupabaseAdmin.mockReturnValue({ from: admin.from });

    const response = await appointmentsGet(
      new NextRequest("http://localhost/api/appointments?slug=ornek-magaza"),
    );

    expect(response.status).toBe(401);
    expect(admin.update).not.toHaveBeenCalled();
  });
});

describe("GET /sitemap.xml görsel etiketleri", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("görsel için yalnız image:loc yazar; caption ve geo_location üretmez", async () => {
    mockSitemapTables({
      stores: [
        {
          id: "store-1",
          slug: "ornek-magaza",
          name: "Örnek Mağaza",
          updated_at: "2026-11-21T10:00:00.000Z",
          is_demo: false,
          district_name: "Kadıköy",
          province_name: "İstanbul",
        },
      ],
      products: [
        {
          store_id: "store-1",
          slug: "keten-gomlek",
          name: "Keten Gömlek",
          description: 'Yazlık & "rahat" <keten>',
          image_urls: ["https://cdn.vixrex.test/keten.jpg"],
          source_type: "manual",
          fatura_kanit: null,
          updated_at: "2026-11-21T11:00:00.000Z",
        },
      ],
      store_articles: [],
    });

    const response = await sitemapGet();
    const xml = await response.text();

    expect(response.status).toBe(200);
    expect(xml).toContain(
      "<image:loc>https://cdn.vixrex.test/keten.jpg</image:loc>",
    );
    expect(xml).not.toContain("<image:caption>");
    expect(xml).not.toContain("<image:geo_location>");
  });

  it("eski mocklarda açıklama/il/ilçe yoksa görsel etiketi sade kalır", async () => {
    mockSitemapTables({
      stores: [
        {
          id: "store-1",
          slug: "ornek-magaza",
          name: "Örnek Mağaza",
          updated_at: "2026-11-21T10:00:00.000Z",
          is_demo: false,
        },
      ],
      products: [
        {
          store_id: "store-1",
          slug: "baslik-urun",
          name: "Başlık Ürün",
          image_urls: ["https://cdn.vixrex.test/baslik.jpg"],
          source_type: "manual",
          fatura_kanit: null,
          updated_at: "2026-11-21T11:00:00.000Z",
        },
      ],
      store_articles: [],
    });

    const response = await sitemapGet();
    const xml = await response.text();

    expect(response.status).toBe(200);
    expect(xml).toContain(
      "<image:loc>https://cdn.vixrex.test/baslik.jpg</image:loc>",
    );
    expect(xml).not.toContain("<image:caption>");
    expect(xml).not.toContain("<image:geo_location>");
  });

  it("caption etiketi hiç yazılmaz, uzun açıklama XML'e sızmaz", async () => {
    const uzunAciklama = "A".repeat(250);
    mockSitemapTables({
      stores: [
        {
          id: "store-1",
          slug: "ornek-magaza",
          name: "Örnek Mağaza",
          updated_at: "2026-11-21T10:00:00.000Z",
          is_demo: false,
        },
      ],
      products: [
        {
          store_id: "store-1",
          slug: "uzun-aciklama",
          name: "Uzun Açıklama",
          description: uzunAciklama,
          image_urls: ["https://cdn.vixrex.test/uzun.jpg"],
          source_type: "manual",
          fatura_kanit: null,
          updated_at: "2026-11-21T11:00:00.000Z",
        },
      ],
      store_articles: [],
    });

    const response = await sitemapGet();
    const xml = await response.text();

    expect(xml).not.toContain("<image:caption>");
    expect(xml).not.toContain("A".repeat(200));
  });

  it("telif izni olmayan fatura görselini yine gizler, ürün adresi kalır", async () => {
    mockSitemapTables({
      stores: [
        {
          id: "store-1",
          slug: "ornek-magaza",
          name: "Örnek Mağaza",
          updated_at: "2026-11-21T10:00:00.000Z",
          is_demo: false,
          district_name: "Kadıköy",
          province_name: "İstanbul",
        },
      ],
      products: [
        {
          store_id: "store-1",
          slug: "telifli-urun",
          name: "Telifli Ürün",
          description: "Açıklama",
          image_urls: ["https://cdn.vixrex.test/telifli.jpg"],
          source_type: "invoice",
          fatura_kanit: null,
          updated_at: "2026-11-21T11:00:00.000Z",
        },
      ],
      store_articles: [],
    });

    const response = await sitemapGet();
    const xml = await response.text();

    expect(response.status).toBe(200);
    expect(xml).toContain(
      "<loc>https://vixrex.test/v/ornek-magaza/urun/telifli-urun</loc>",
    );
    expect(xml).not.toContain("<image:image>");
    expect(xml).not.toContain("<image:caption>");
    expect(xml).not.toContain("<image:geo_location>");
    expect(xml).not.toContain("telifli.jpg");
  });
});
