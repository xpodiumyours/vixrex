import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";

const { mockAdminRpc, mockAdminFrom, mockAnonRpc, mockSahipYetkisi, mockRevalidateTag } = vi.hoisted(() => ({
  mockAdminRpc: vi.fn(),
  mockAdminFrom: vi.fn(),
  mockAnonRpc: vi.fn(),
  mockSahipYetkisi: vi.fn(),
  mockRevalidateTag: vi.fn(),
}));

vi.mock("next/cache", () => ({
  revalidateTag: mockRevalidateTag,
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: () => ({
    rpc: mockAdminRpc,
    from: mockAdminFrom,
  }),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: {
    rpc: mockAnonRpc,
  },
}));

vi.mock("@/lib/faturaYetki", () => ({
  sahipYetkisi: (...args: unknown[]) => mockSahipYetkisi(...args),
}));

import { GET, POST, PUT } from "@/app/api/izin-talebi/route";
import {
  normalizeSupplierPermissionPayload,
  sanitizePermissionText,
} from "@/lib/supplierPermissionRequest";

const VALID_TOKEN = "a".repeat(64);
const STORE_ID = "11111111-1111-4111-8111-111111111111";
const LINE_ID = "22222222-2222-4222-8222-222222222222";
const PRODUCT_ID = "33333333-3333-4333-8333-333333333333";

const repoRoot = resolve(__dirname, "../..");
const migrationSql = readFileSync(
  resolve(repoRoot, "supabase/migrations/20261118190000_supplier_permission_requests.sql"),
  "utf8",
);
const scopeDefaultMigrationSql = readFileSync(
  resolve(repoRoot, "supabase/migrations/20261124180000_supplier_permission_requests_scope_default.sql"),
  "utf8",
);
const pageSource = readFileSync(
  resolve(repoRoot, "public_web/src/app/izin-talebi/[token]/page.tsx"),
  "utf8",
);
const clientSource = readFileSync(
  resolve(repoRoot, "public_web/src/app/izin-talebi/[token]/IzinTalebiOnayClient.tsx"),
  "utf8",
);

beforeEach(() => {
  vi.clearAllMocks();
});

describe("Faz 2: Uretici izin talep koprusu migration sozlesmesi", () => {
  it("tablo, RLS ve anon erisim kisitini dogru tanimlar", () => {
    expect(migrationSql).toContain("create table if not exists public.supplier_permission_requests");
    expect(migrationSql).toContain("alter table public.supplier_permission_requests enable row level security");
    expect(migrationSql).toContain("revoke all on public.supplier_permission_requests from anon, authenticated, public");
  });

  it("uc RPC fonksiyonunu dogru guvenlik ve izinlerle tanimlar", () => {
    expect(migrationSql).toContain("create or replace function public.create_supplier_permission_request");
    expect(migrationSql).toContain("create or replace function public.get_supplier_permission_request");
    expect(migrationSql).toContain("create or replace function public.approve_supplier_permission_request");
    expect(migrationSql).toContain("encode(extensions.gen_random_bytes(32), 'hex')");
    expect(migrationSql).toContain("grant execute on function public.get_supplier_permission_request(text) to anon, authenticated, service_role");
    expect(migrationSql).toContain("grant execute on function public.approve_supplier_permission_request(text) to anon, authenticated, service_role");
    expect(migrationSql).toContain("usage_status = 'verified_supplier_permission'");
    expect(migrationSql).toContain("and usage_status = 'unknown'");
    expect(migrationSql).toContain("status = 'onaylandi'");
  });

  it("get_supplier_permission_request ticari sir kolonlarini asla secmez", () => {
    const fnStart = migrationSql.indexOf("create or replace function public.get_supplier_permission_request");
    const fnEnd = migrationSql.indexOf("create or replace function public.approve_supplier_permission_request");
    const getFnSql = migrationSql.slice(fnStart, fnEnd);
    for (const secretField of [
      "supplier_tax_id",
      "supplier_name",
      "unit_price",
      "line_total",
      "price_amount",
      "fatura_kanit",
      "edit_token",
      "ettn",
      "iban",
    ]) {
      expect(getFnSql).not.toContain(secretField);
    }
  });

  it("scope default ileri yonlu migration mevcut scope kolonuna varsayilan deger atar ve yetki gevsetmez", () => {
    expect(scopeDefaultMigrationSql).toContain("column_name = 'scope'");
    expect(scopeDefaultMigrationSql).toContain("alter column scope set default ''data_and_images''");
    expect(scopeDefaultMigrationSql).toContain("notify pgrst, 'reload schema'");
    expect(scopeDefaultMigrationSql.toLowerCase()).not.toContain("grant ");
    expect(scopeDefaultMigrationSql.toLowerCase()).not.toContain("revoke ");
  });
});

describe("Kural 32 sizintisizlik ve veri projeksiyonu", () => {
  it("ticari sir alanlarini ve metin ici VKN/IBAN/alis fiyatini temizler", () => {
    const dirty = {
      store_name: "Örnek Bayi",
      store_slug: "ornek-bayi",
      brand: "Tutku",
      status: "bekliyor",
      supplier_name: "Gizli Toptancı A.Ş.",
      supplier_tax_id: "1234567890",
      alici_vkn: "98765432101",
      ettn: "ETTN-12345",
      iban: "TR120001000200030004000500",
      iskonto: "%15",
      vade: "60 gün",
      unit_price: 120,
      line_total: 2400,
      product_count: 1,
      line_count: 1,
      products: [
        {
          id: PRODUCT_ID,
          name: "Erkek Fanila VKN 1234567890 alış fiyatı 99 TL",
          slug: "erkek-fanila",
          brand: "Tutku",
          model: "ELT-100",
          image_urls: ["https://cdn.example.com/fanila.jpg", "javascript:alert(1)"],
          permission_status: "bekliyor",
          unit_price: 99,
          fatura_kanit: { gizli: true },
        },
      ],
    };

    const clean = normalizeSupplierPermissionPayload(dirty);
    expect(clean).not.toBeNull();
    const serialized = JSON.stringify(clean);
    expect(serialized).not.toContain("Gizli Toptancı");
    expect(serialized).not.toContain("1234567890");
    expect(serialized).not.toContain("98765432101");
    expect(serialized).not.toContain("ETTN-12345");
    expect(serialized).not.toContain("TR120001000200030004000500");
    expect(serialized).not.toContain("iskonto");
    expect(serialized).not.toContain("unit_price");
    expect(serialized).not.toContain("fatura_kanit");
    expect(serialized).not.toContain("javascript:alert");
    expect(clean?.products[0].image_urls).toEqual(["https://cdn.example.com/fanila.jpg"]);
    expect(clean?.products[0].name).toBe("Erkek Fanila");
    expect(sanitizePermissionText("IBAN TR330006100519786457841326 ürün")).toBe("IBAN ürün");
  });
});

describe("/api/izin-talebi ucu", () => {
  it("POST: yetkisiz veya eksik/gecersiz veriyi reddeder", async () => {
    mockSahipYetkisi.mockResolvedValueOnce({ tamam: false, durum: 401, hata: "Oturum geçersiz." });
    const unauthRes = await POST(
      new NextRequest("http://localhost/api/izin-talebi", {
        method: "POST",
        body: JSON.stringify({ slug: "bayi", brand: "Tutku", lineIds: [LINE_ID] }),
      }),
    );
    expect(unauthRes.status).toBe(401);

    const noBrandRes = await POST(
      new NextRequest("http://localhost/api/izin-talebi", {
        method: "POST",
        body: JSON.stringify({ slug: "bayi", brand: "", lineIds: [LINE_ID] }),
      }),
    );
    expect(noBrandRes.status).toBe(422);

    const emptyScopeRes = await POST(
      new NextRequest("http://localhost/api/izin-talebi", {
        method: "POST",
        body: JSON.stringify({ slug: "bayi", brand: "Tutku", lineIds: [], productIds: [] }),
      }),
    );
    expect(emptyScopeRes.status).toBe(422);

    const badUuidRes = await POST(
      new NextRequest("http://localhost/api/izin-talebi", {
        method: "POST",
        body: JSON.stringify({ slug: "bayi", brand: "Tutku", lineIds: ["not-a-uuid"] }),
      }),
    );
    expect(badUuidRes.status).toBe(422);
  });

  it("POST: gecerli esnaf yetkisi ile 64 karakter hex token uretir", async () => {
    mockSahipYetkisi.mockResolvedValueOnce({ tamam: true, storeId: STORE_ID, slug: "bayi" });
    mockAdminRpc.mockResolvedValueOnce({ data: VALID_TOKEN, error: null });

    const res = await POST(
      new NextRequest("http://localhost/api/izin-talebi", {
        method: "POST",
        headers: { "x-vixrex-edit-token": "secret-edit-token-1234567890" },
        body: JSON.stringify({
          slug: "bayi",
          brand: "Tutku",
          supplierName: "Tutku İç Giyim",
          lineIds: [LINE_ID],
          productIds: [PRODUCT_ID],
        }),
      }),
    );

    expect(res.status).toBe(201);
    const body = await res.json();
    expect(body).toEqual({
      token: VALID_TOKEN,
      url: `/izin-talebi/${VALID_TOKEN}`,
    });
    expect(mockAdminRpc).toHaveBeenCalledWith("create_supplier_permission_request", {
      p_store_id: STORE_ID,
      p_edit_token: "secret-edit-token-1234567890",
      p_supplier_name: "Tutku İç Giyim",
      p_brand: "Tutku",
      p_line_ids: [LINE_ID],
      p_product_ids: [PRODUCT_ID],
    });
  });

  it.each([
    {
      rpcMessage: "DEMO_STORE_IMMUTABLE",
      expectedStatus: 403,
      expectedError: "Demo vitrinlerde üretici izin bağlantısı oluşturulamaz.",
    },
    {
      rpcMessage: "OWNER_AUTHORIZATION_REQUIRED",
      expectedStatus: 401,
      expectedError: "Vitrin düzenleme yetkisi doğrulanamadı. Lütfen yeniden giriş yapın.",
    },
    {
      rpcMessage: "EMPTY_PERMISSION_SCOPE",
      expectedStatus: 422,
      expectedError: "İzin talebi için geçerli bir fatura satırı veya ürün bulunamadı.",
    },
    {
      rpcMessage: "INVALID_BRAND",
      expectedStatus: 422,
      expectedError: "Marka bilgisi belirtilmedi.",
    },
  ])("POST: RPC $rpcMessage hatasini $expectedStatus durum koduyla acik dondurur", async ({
    rpcMessage,
    expectedStatus,
    expectedError,
  }) => {
    mockSahipYetkisi.mockResolvedValueOnce({ tamam: true, storeId: STORE_ID, slug: "bayi" });
    mockAdminRpc.mockResolvedValueOnce({ data: null, error: { code: "P0001", message: rpcMessage } });

    const res = await POST(
      new NextRequest("http://localhost/api/izin-talebi", {
        method: "POST",
        headers: { "x-vixrex-edit-token": "secret-edit-token-1234567890" },
        body: JSON.stringify({
          slug: "bayi",
          brand: "Tutku",
          lineIds: [LINE_ID],
        }),
      }),
    );

    expect(res.status).toBe(expectedStatus);
    expect(await res.json()).toEqual({ hata: expectedError });
  });

  it("POST: beklenmedik RPC hatasinda SQL detayi sizdirmadan 500 dondurur", async () => {
    const errSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    mockSahipYetkisi.mockResolvedValueOnce({ tamam: true, storeId: STORE_ID, slug: "bayi" });
    mockAdminRpc.mockResolvedValueOnce({
      data: null,
      error: { code: "23502", message: 'null value in column "scope" violates not-null constraint' },
    });

    const res = await POST(
      new NextRequest("http://localhost/api/izin-talebi", {
        method: "POST",
        headers: { "x-vixrex-edit-token": "secret-edit-token-1234567890" },
        body: JSON.stringify({
          slug: "bayi",
          brand: "Tutku",
          lineIds: [LINE_ID],
        }),
      }),
    );

    expect(res.status).toBe(500);
    const body = await res.json();
    expect(body).toEqual({ hata: "İzin talebi bağlantısı oluşturulamadı." });
    expect(JSON.stringify(body)).not.toContain("23502");
    expect(JSON.stringify(body)).not.toContain("scope");
    expect(errSpy).toHaveBeenCalledWith("[izin-talebi] rpc hatasi:", { code: "23502" });
    errSpy.mockRestore();
  });

  it("GET: gecersiz token 400, bulunamayan 404, gecerli talep Kural 32 temizlenmis veri doner", async () => {
    const badRes = await GET(new NextRequest("http://localhost/api/izin-talebi?token=short"));
    expect(badRes.status).toBe(400);

    mockAnonRpc.mockResolvedValueOnce({ data: null, error: null });
    const missingRes = await GET(
      new NextRequest(`http://localhost/api/izin-talebi?token=${VALID_TOKEN}`),
    );
    expect(missingRes.status).toBe(404);

    mockAnonRpc.mockResolvedValueOnce({
      data: {
        store_name: "Örnek Mağaza",
        store_slug: "ornek-magaza",
        brand: "Tutku",
        status: "bekliyor",
        created_at: "2026-11-18T12:00:00Z",
        expires_at: "2026-12-18T12:00:00Z",
        product_count: 1,
        line_count: 1,
        supplier_tax_id: "1234567890",
        unit_price: 45,
        products: [
          {
            id: PRODUCT_ID,
            name: "Tutku Erkek Atlet",
            slug: "tutku-erkek-atlet",
            brand: "Tutku",
            model: "0101",
            image_urls: ["https://cdn.example.com/0101.jpg"],
            permission_status: "bekliyor",
          },
        ],
      },
      error: null,
    });

    const okRes = await GET(
      new NextRequest(`http://localhost/api/izin-talebi?token=${VALID_TOKEN}`),
    );
    expect(okRes.status).toBe(200);
    const body = await okRes.json();
    expect(body.store_name).toBe("Örnek Mağaza");
    expect(body.store_slug).toBe("ornek-magaza");
    expect(body).not.toHaveProperty("supplier_tax_id");
    expect(body).not.toHaveProperty("unit_price");
    expect(body.products).toHaveLength(1);
  });

  it("PUT: suresi dolmus/reddedilmis/gecersiz token reddedilir, gecerli onay izni acar", async () => {
    const invalidRes = await PUT(
      new NextRequest("http://localhost/api/izin-talebi", {
        method: "PUT",
        body: JSON.stringify({ token: "gecersiz" }),
      }),
    );
    expect(invalidRes.status).toBe(400);

    mockAnonRpc.mockResolvedValueOnce({
      data: { success: false, error: "TOKEN_EXPIRED" },
      error: null,
    });
    const expiredRes = await PUT(
      new NextRequest("http://localhost/api/izin-talebi", {
        method: "PUT",
        body: JSON.stringify({ token: VALID_TOKEN }),
      }),
    );
    expect(expiredRes.status).toBe(410);

    mockAnonRpc.mockResolvedValueOnce({
      data: { success: false, error: "REQUEST_REJECTED" },
      error: null,
    });
    const rejectedRes = await PUT(
      new NextRequest("http://localhost/api/izin-talebi", {
        method: "PUT",
        body: JSON.stringify({ token: VALID_TOKEN }),
      }),
    );
    expect(rejectedRes.status).toBe(409);

    mockAnonRpc.mockResolvedValueOnce({
      data: { success: true, status: "onaylandi", updated_rights_count: 2 },
      error: null,
    });
    mockAdminFrom.mockImplementation((tablo: string) => ({
      select: () => ({
        eq: () => ({
          maybeSingle: async () =>
            tablo === "supplier_permission_requests"
              ? { data: { store_id: STORE_ID }, error: null }
              : { data: { slug: "ornek-magaza" }, error: null },
        }),
      }),
    }));
    const okRes = await PUT(
      new NextRequest("http://localhost/api/izin-talebi", {
        method: "PUT",
        body: JSON.stringify({ token: VALID_TOKEN }),
      }),
    );
    expect(okRes.status).toBe(200);
    expect(await okRes.json()).toEqual({
      success: true,
      status: "onaylandi",
      alreadyApproved: false,
      updatedRightsCount: 2,
    });
    expect(mockRevalidateTag).toHaveBeenCalledWith("store-ornek-magaza", { expire: 0 });
    expect(mockRevalidateTag).toHaveBeenCalledWith("products-ornek-magaza", { expire: 0 });
    expect(mockRevalidateTag).toHaveBeenCalledWith("kesfet", { expire: 0 });
  });
});

describe("UI Onay Sayfasi sozlesmesi", () => {
  it("yetkili bayi bilgisi, urun kartlari ve tek tikla onay dugmesini icerir", () => {
    expect(pageSource).toContain("fetchSupplierPermissionRequest");
    expect(pageSource).toContain("notFound()");
    expect(clientSource).toContain("Yetkili Bayime Görsel İzni Ver");
    expect(clientSource).toContain('method: "PUT"');
    expect(clientSource).toContain("/api/izin-talebi");
    expect(clientSource).toContain("Fatura Kanıtlı Yetkili Bayi");
    expect(clientSource).toContain("/v/${encodeURIComponent(data.store_slug)}");
  });
});
