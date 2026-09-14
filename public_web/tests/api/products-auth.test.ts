import { describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";

const { mockGet, mockGetSupabaseAdmin } = vi.hoisted(() => ({
  mockGet: vi.fn(() => undefined),
  mockGetSupabaseAdmin: vi.fn(),
}));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({ get: mockGet })),
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: mockGetSupabaseAdmin,
}));

vi.mock("@/lib/productCoreServer", () => ({
  createRichCoreProduct: vi.fn(),
  updateRichCoreProduct: vi.fn(),
  createCoreProduct: vi.fn(),
  updateCoreProduct: vi.fn(),
}));

import { DELETE, PATCH, POST } from "@/app/api/products/route";

const PRODUCT_ID = "11111111-1111-1111-1111-111111111111";
const SLUG = "deneme-vitrin";

function productRequest(method: "POST" | "PATCH" | "DELETE") {
  const body =
    method === "POST"
      ? { slug: SLUG, name: "Deneme ürün" }
      : { slug: SLUG, productId: PRODUCT_ID };

  return new NextRequest("http://localhost/api/products", {
    method,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

describe("/api/products sahip oturumu sözleşmesi", () => {
  it.each([
    ["POST", POST],
    ["PATCH", PATCH],
    ["DELETE", DELETE],
  ] as const)("%s isteğinde çerez yoksa 401 döner", async (method, handler) => {
    const response = await handler(productRequest(method));

    expect(response.status).toBe(401);
    await expect(response.json()).resolves.toEqual({
      hata: "Oturumun geçersiz veya süresi dolmuş.",
    });
    expect(mockGetSupabaseAdmin).not.toHaveBeenCalled();
  });
});
