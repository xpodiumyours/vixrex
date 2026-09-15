import { beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";

const mocks = vi.hoisted(() => ({ current: {} as Record<string, unknown>, create: vi.fn(), update: vi.fn() }));
vi.mock("next/headers", () => ({ cookies: async () => ({ get: () => ({ value: "test" }) }) }));
vi.mock("@/lib/ownerSession", () => ({ OWNER_SESSION_COOKIE: "owner", verifyOwnerSession: () => ({ storeId: "store" }) }));
vi.mock("@/lib/productCoreServer", () => ({ createRichCoreProduct: mocks.create, updateRichCoreProduct: mocks.update }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: () => ({ from: (table: string) => {
  const chain = { select: () => chain, eq: () => chain, single: async () => ({ data: { id: "store", edit_token: "test" } }), maybeSingle: async () => ({ data: table === "products" ? mocks.current : null }) };
  return chain;
} }) }));
import { POST, PATCH } from "@/app/api/products/route";

const oldImage = "https://cdn.example/old.jpg";
function request(method: string, data: Record<string, unknown>) {
  return new NextRequest("http://localhost/api/products", { method, headers: { "Content-Type": "application/json" }, body: JSON.stringify({ slug: "shop", productId: "product", name: "Ürün", ...data }) });
}
describe("ürün fotoğraf yayın durumu", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.current = { name: "Ürün", image_urls: [oldImage], image_publish_minimum: 0, is_visible: true, metadata: {}, variants: [] };
    mocks.create.mockResolvedValue({ id: "product", slug: "urun" });
    mocks.update.mockResolvedValue(undefined);
  });
  it("yeni görselsiz ürünü taslak olarak kaydeder", async () => {
    const response = await POST(request("POST", { imageUrls: [] }));
    expect(response.status).toBe(200);
    expect(await response.json()).toMatchObject({ tamam: true, taslak: true });
    expect(mocks.create).toHaveBeenCalledWith(expect.objectContaining({ imageUrls: [] }));
  });
  it("eski tek fotoğraflı ürünü görünür tutar", async () => {
    const response = await PATCH(request("PATCH", { imageUrls: [oldImage] }));
    expect(response.status).toBe(200);
    expect(mocks.update).toHaveBeenCalledWith(expect.objectContaining({ isVisible: true }));
  });
  it("yeni tek fotoğraflı ürünü gizli tutar", async () => {
    mocks.current.image_publish_minimum = 3;
    mocks.current.is_visible = false;
    const response = await PATCH(request("PATCH", { imageUrls: [oldImage] }));
    expect(await response.json()).toMatchObject({ taslak: true });
    expect(mocks.update).toHaveBeenCalledWith(expect.objectContaining({ isVisible: false }));
  });
  it("fotoğrafları tamamlanan taslağı görünür yapar", async () => {
    mocks.current.image_publish_minimum = 3;
    mocks.current.is_visible = false;
    const images = [oldImage, "https://storage.example/storage/v1/object/public/shelf-images/shop/products/p/2.jpg", "https://storage.example/storage/v1/object/public/shelf-images/shop/products/p/3.jpg"];
    const response = await PATCH(request("PATCH", { imageUrls: images }));
    expect(response.status).toBe(200);
    expect(mocks.update).toHaveBeenCalledWith(expect.objectContaining({ isVisible: true }));
  });
  it("bilerek gizlenmiş tamamlanmış ürünü açmaz", async () => {
    mocks.current.is_visible = false;
    const response = await PATCH(request("PATCH", {}));
    expect(response.status).toBe(200);
    expect(mocks.update).toHaveBeenCalledWith(expect.objectContaining({ isVisible: false }));
  });
});
