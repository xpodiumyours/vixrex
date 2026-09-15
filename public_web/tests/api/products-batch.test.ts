import { beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";

const mocks = vi.hoisted(() => ({ session: vi.fn(), rpc: vi.fn(), single: vi.fn() }));
vi.mock("next/headers", () => ({ cookies: async () => ({ get: () => ({ value: "test" }) }) }));
vi.mock("@/lib/ownerSession", () => ({ OWNER_SESSION_COOKIE: "owner", verifyOwnerSession: mocks.session }));
vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: () => ({
    from: () => ({ select: () => ({ eq: () => ({ single: mocks.single }) }) }),
    rpc: mocks.rpc,
  }),
}));
import { POST } from "@/app/api/products/batch/route";

function request(products: unknown) {
  return new NextRequest("http://localhost/api/products/batch", {
    method: "POST", body: JSON.stringify({ slug: "magaza", products }),
    headers: { "Content-Type": "application/json" },
  });
}

describe("toplu ürün kayıt sınırı", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.session.mockReturnValue({ storeId: "store-1" });
    mocks.single.mockResolvedValue({ data: { id: "store-1", edit_token: "test-token" } });
    mocks.rpc.mockResolvedValue({ data: { success: true, total: 3, inserted: 2, errors: 1, error_details: [{ index: 2, error: "PRODUCT_INVALID" }] } });
  });

  it("hatalı satırı aynı sırada RPC'ye geçirip diğer ürünlerin sonucunu korur", async () => {
    const response = await POST(request([
      { name: "Bir", brand: " Marka ", barcode: "00123", sku: "S-1", stock_quantity: 10, category_name: "Servis", image_urls: [] },
      null,
      { name: "Üç", image_urls: ["https://cdn.example/tek.jpg"] },
    ]));
    expect(response.status).toBe(200);
    const args = mocks.rpc.mock.calls[0][1];
    expect(Array.isArray(args.p_products)).toBe(true);
    expect(args.p_products[0]).toMatchObject({ brand: "Marka", barcode: "00123", sku: "S-1", stock_quantity: 10, category_name: "Servis", image_urls: [] });
    expect(args.p_products[1]).toBeNull();
    expect(args.p_products[2].image_urls).toHaveLength(1);
    expect(await response.json()).toMatchObject({ toplam: 3, eklenen: 2, hatali: 1, hataDetaylari: [{ index: 2, error: "PRODUCT_INVALID" }] });
  });

  it("yetkisiz isteği kayıt çağrısından önce reddeder", async () => {
    mocks.session.mockReturnValue(null);
    expect((await POST(request([{ name: "Bir" }]))).status).toBe(401);
    expect(mocks.rpc).not.toHaveBeenCalled();
  });

  it("100 üründen fazlasını yazmaz", async () => {
    expect((await POST(request(Array.from({ length: 101 }, () => ({ name: "Bir" }))))).status).toBe(422);
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
});
