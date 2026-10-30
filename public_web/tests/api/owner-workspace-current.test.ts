import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { OWNER_SESSION_COOKIE, signOwnerSession } from "@/lib/ownerSession";

const mocks = vi.hoisted(() => ({
  cookie: vi.fn(),
  rpc: vi.fn(),
  admin: vi.fn(),
  from: vi.fn(),
  select: vi.fn(),
  eq: vi.fn(),
  maybeSingle: vi.fn(),
}));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({ get: mocks.cookie })),
}));
vi.mock("@/lib/supabase", () => ({ supabase: { rpc: mocks.rpc } }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.admin }));

import { GET } from "@/app/api/owner-workspace/current/route";

const storeId = "11111111-1111-4111-8111-111111111111";
const slug = "misafir-vitrini";
const sessionToken = "ab".repeat(32);

function draft(overrides: Record<string, unknown> = {}) {
  return {
    store_id: storeId,
    slug,
    draft_data: { name: "Çalışma taslağı", is_published: false },
    draft_version: 4,
    base_live_version: 2,
    ...overrides,
  };
}

function liveStore() {
  return {
    id: storeId,
    slug,
    name: "Canlı mağaza",
    is_published: true,
    kategori: "Giyim & Moda",
    business_type: "Butik",
    updated_at: "2026-10-24T00:00:00Z",
    products: [],
    product_categories: [],
    edit_token: "sunucuda-kalmasi-gereken-deger",
  };
}

beforeEach(() => {
  vi.clearAllMocks();
  vi.stubEnv("OWNER_SESSION_SECRET", "owner-workspace-runtime-test-value-20261024");
  mocks.cookie.mockReturnValue({ value: signOwnerSession(storeId, slug, sessionToken) });
  mocks.rpc.mockResolvedValue({ data: draft(), error: null });
  mocks.admin.mockReturnValue({ from: mocks.from });
  mocks.from.mockReturnValue({ select: mocks.select });
  mocks.select.mockReturnValue({ eq: mocks.eq });
  mocks.eq.mockReturnValue({ eq: mocks.eq, maybeSingle: mocks.maybeSingle });
  mocks.maybeSingle.mockResolvedValue({ data: liveStore(), error: null });
  vi.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllEnvs();
});

describe("/api/owner-workspace/current sahiplik ve canlı veri davranışı", () => {
  it("çerez olmadan mağaza veya yönetici sorgusu yapmaz", async () => {
    mocks.cookie.mockReturnValue(undefined);
    const response = await GET();
    expect(response.status).toBe(404);
    expect(await response.json()).toEqual({ tamam: false, sebep: "NO_OWNER_SESSION" });
    expect(mocks.cookie).toHaveBeenCalledWith(OWNER_SESSION_COOKIE);
    expect(mocks.rpc).not.toHaveBeenCalled();
    expect(mocks.admin).not.toHaveBeenCalled();
  });

  it("imzası bozulmuş çerezi DB ve yönetici erişiminden önce reddeder", async () => {
    const token = signOwnerSession(storeId, slug, sessionToken);
    mocks.cookie.mockReturnValue({ value: token.slice(0, -5) + "aaaaa" });
    const response = await GET();
    expect(response.status).toBe(401);
    expect(await response.json()).toEqual({ tamam: false, sebep: "INVALID_OWNER_SESSION" });
    expect(mocks.rpc).not.toHaveBeenCalled();
    expect(mocks.admin).not.toHaveBeenCalled();
  });

  it("HMAC geçerli olsa da DB tarafından reddedilen oturuma yönetici erişimi vermez", async () => {
    mocks.rpc.mockResolvedValue({ data: null, error: { message: "INVALID_SESSION_TOKEN" } });
    const response = await GET();
    expect(response.status).toBe(401);
    expect(await response.json()).toEqual({ tamam: false, sebep: "INVALID_OWNER_SESSION" });
    expect(mocks.admin).not.toHaveBeenCalled();
  });

  it.each([
    [{ slug: "baska-vitrin" }, "SLUG_MISMATCH"],
    [{ store_id: "22222222-2222-4222-8222-222222222222" }, "STORE_MISMATCH"],
    [{ store_id: undefined }, "STORE_MISMATCH"],
  ])("DB ve çerez kapsamı uyuşmazsa mağaza okumaz: %j", async (overrides, reason) => {
    mocks.rpc.mockResolvedValue({ data: draft(overrides), error: null });
    const response = await GET();
    expect(response.status).toBe(409);
    expect(await response.json()).toEqual({ tamam: false, sebep: reason });
    expect(mocks.admin).not.toHaveBeenCalled();
  });

  it("taslak yayında değilken canlı yayını ve aynı taslağı ayrı döndürür", async () => {
    const response = await GET();
    const body = await response.json();
    expect(response.status).toBe(200);
    expect(body.store).toMatchObject({ id: storeId, slug, name: "Canlı mağaza", is_published: true });
    expect(body.working_draft.draft_data).toEqual({ name: "Çalışma taslağı", is_published: false });
    expect(body.working_draft).toMatchObject({ draft_version: 4, base_live_version: 2 });
    expect(mocks.rpc).toHaveBeenCalledWith("get_working_draft_for_session", { p_session_token: sessionToken });
    expect(mocks.rpc.mock.invocationCallOrder[0]).toBeLessThan(mocks.admin.mock.invocationCallOrder[0]);
    expect(mocks.eq.mock.calls).toEqual([["id", storeId], ["slug", slug]]);
    expect(response.headers.get("cache-control")).toBe("private, no-store");
    expect(JSON.stringify(body)).not.toContain(sessionToken);
    expect(JSON.stringify(body)).not.toContain("sunucuda-kalmasi-gereken-deger");
  });

  it("görünmez fatura taslağının fiyatını, stokunu ve zengin ürün alanlarını korur", async () => {
    const product = {
      id: "product-draft", slug: "fatura-urun", name: "Fatura ürünü", is_visible: false,
      price_amount: 149.9, stock_quantity: 12, brand: "Örnek", barcode: "8690000000001",
      metadata: { invoice: { source: "invoice-line-1" }, attributes: [{ key: "size", value: "L" }] },
      variants: [{ id: "large", size: "L", stock: 12 }],
      image_urls: ["https://example.com/product.webp"],
      product_categories: { name: "Giyim", product_template_key: "clothing" },
    };
    const categories = [{ id: "category-1", name: "Giyim", product_template_key: "clothing" }];
    mocks.maybeSingle.mockResolvedValue({
      data: { ...liveStore(), products: [product], product_categories: categories }, error: null,
    });
    const response = await GET();
    const body = await response.json();
    expect(body.store.products).toEqual([product]);
    expect(body.store.product_categories).toEqual(categories);
    expect(body.store.business_type).toBe("Butik");
    const selected = mocks.select.mock.calls[0][0] as string;
    for (const field of ["stock_quantity", "brand", "barcode", "metadata", "variants", "product_template_key"]) {
      expect(selected).toContain(field);
    }
    expect(mocks.eq).not.toHaveBeenCalledWith("is_visible", true);
  });

  it("taslak okuma hatasını yeni mağaza yok sonucu olarak döndürmez", async () => {
    mocks.rpc.mockResolvedValue({ data: null, error: { message: "temporary failure" } });
    const response = await GET();
    expect(response.status).toBe(409);
    expect(await response.json()).toEqual({ tamam: false, sebep: "DRAFT_UNAVAILABLE" });
    expect(mocks.admin).not.toHaveBeenCalled();
  });

  it("katalog sorgu hatasını boş ürünlerle sahte başarıya çevirmeden kapatır", async () => {
    mocks.maybeSingle.mockResolvedValue({ data: null, error: { message: "products relation unavailable" } });
    const response = await GET();
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({ tamam: false, sebep: "WORKSPACE_UNAVAILABLE" });
  });

  it("mağaza silinmişse yükleme hatasından ayrı sonuç döndürür", async () => {
    mocks.maybeSingle.mockResolvedValue({ data: null, error: null });
    const response = await GET();
    expect(response.status).toBe(404);
    expect(await response.json()).toEqual({ tamam: false, sebep: "STORE_NOT_FOUND" });
  });

  it("yönetici yapılandırma hatasını iç ayrıntıları göstermeden kapatır", async () => {
    mocks.admin.mockImplementation(() => { throw new Error("private server configuration"); });
    const response = await GET();
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({ tamam: false, sebep: "WORKSPACE_UNAVAILABLE" });
  });
});
