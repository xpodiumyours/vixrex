import { beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";

// PATCH koruma kuralı (P6): fatura taslağı sıradan düzenlemeyle — fotoğraf
// tamamlansa bile — yayına çıkmaz; yalnız /api/fatura-yayinla görünür yapar.
// Geçerli yayındaki fatura ürünü de sıradan düzenlemeyle taslağa düşmez.

const { mockGet, mockUpdateRichCoreProduct, mockGetSupabaseAdmin, mockVerifyOwnerSession } =
  vi.hoisted(() => ({
    mockGet: vi.fn(() => ({ value: "cerez-degeri" })),
    mockUpdateRichCoreProduct: vi.fn(async (_args: Record<string, unknown>) => undefined),
    mockGetSupabaseAdmin: vi.fn(),
    mockVerifyOwnerSession: vi.fn(() => ({ storeId: "store-1", slug: "deneme-vitrin" })),
  }));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({ get: mockGet })),
}));

vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mockVerifyOwnerSession,
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: mockGetSupabaseAdmin,
}));

vi.mock("@/lib/productCoreServer", () => ({
  createRichCoreProduct: vi.fn(),
  updateRichCoreProduct: mockUpdateRichCoreProduct,
}));

import { PATCH } from "@/app/api/products/route";

const SLUG = "deneme-vitrin";
const PRODUCT_ID = "11111111-1111-1111-1111-111111111111";

function yonetilenGorsel(dosyaAdi: string) {
  return `https://ornekproje.supabase.co/storage/v1/object/public/shelf-images/magaza-1/products/${dosyaAdi}`;
}

const TAM_FATURA_SATIRI = {
  name: "Fatura Ürünü",
  description: "",
  price_text: "199 TL",
  price_amount: 199,
  category_id: null,
  metadata: {},
  variants: [],
  brand: "Test Marka",
  barcode: null,
  stock_quantity: 4,
  stock_status: "Mevcut",
  old_price_amount: null,
  badge_tag: null,
  fulfillment_region: null,
  source_type: "invoice",
  is_visible: false,
};

function makeAdminStub(productRow: Record<string, unknown> | null) {
  return {
    from: vi.fn((table: string) => {
      if (table === "stores") {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              single: vi.fn(async () => ({
                data: { id: "store-1", edit_token: "tok-1", name: "Test Mağaza" },
              })),
            })),
          })),
        };
      }
      if (table === "products") {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(() => ({
                maybeSingle: vi.fn(async () => ({ data: productRow })),
              })),
            })),
          })),
        };
      }
      throw new Error(`beklenmeyen tablo: ${table}`);
    }),
  };
}

function patchRequest(body: Record<string, unknown>) {
  return new NextRequest("http://localhost/api/products", {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug: SLUG, productId: PRODUCT_ID, ...body }),
  });
}

describe("PATCH fatura taslağını sıradan düzenlemeyle yayınlamaz", () => {
  beforeEach(() => {
    mockUpdateRichCoreProduct.mockClear();
  });

  it("taslakta fotoğraf tamamlanınca bile görünürlük istenmez", async () => {
    mockGetSupabaseAdmin.mockReturnValue(
      makeAdminStub({ ...TAM_FATURA_SATIRI, image_urls: [yonetilenGorsel("a.jpg")] }),
    );
    const response = await PATCH(
      patchRequest({
        imageUrls: [yonetilenGorsel("a.jpg"), yonetilenGorsel("b.jpg"), yonetilenGorsel("c.jpg")],
      }),
    );
    const payload = await response.json();

    expect(response.status).toBe(200);
    // Görünürlük yeniden hesaplanmaz: taslak kalır, yalnız Yayınla açar.
    expect(mockUpdateRichCoreProduct.mock.calls[0]?.[0]?.isVisible).toBeUndefined();
    expect(payload.taslak).toBe(true);
  });

  it("fatura dışı üründe eski davranış korunur: fotoğraf tamamlanınca yayına döner", async () => {
    mockGetSupabaseAdmin.mockReturnValue(
      makeAdminStub({
        ...TAM_FATURA_SATIRI,
        source_type: "manual",
        image_urls: [yonetilenGorsel("a.jpg")],
      }),
    );
    const response = await PATCH(
      patchRequest({
        imageUrls: [yonetilenGorsel("a.jpg"), yonetilenGorsel("b.jpg"), yonetilenGorsel("c.jpg")],
      }),
    );

    expect(response.status).toBe(200);
    expect(mockUpdateRichCoreProduct.mock.calls[0]?.[0]?.isVisible).toBe(true);
  });

  it("yayındaki fatura ürünü sıradan düzenlemeyle taslağa düşmez", async () => {
    mockGetSupabaseAdmin.mockReturnValue(
      makeAdminStub({
        ...TAM_FATURA_SATIRI,
        is_visible: true,
        image_urls: [yonetilenGorsel("a.jpg"), yonetilenGorsel("b.jpg"), yonetilenGorsel("c.jpg")],
      }),
    );
    const response = await PATCH(patchRequest({ priceText: "249 TL" }));

    expect(response.status).toBe(200);
    expect(mockUpdateRichCoreProduct.mock.calls[0]?.[0]?.isVisible).toBeUndefined();
  });

  it("yayındaki fatura ürünü tek görselle düzenlenince gizlenmez", async () => {
    mockGetSupabaseAdmin.mockReturnValue(
      makeAdminStub({
        ...TAM_FATURA_SATIRI,
        is_visible: true,
        image_urls: [yonetilenGorsel("a.jpg")],
      }),
    );
    const response = await PATCH(patchRequest({ imageUrls: [yonetilenGorsel("b.jpg")] }));
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(mockUpdateRichCoreProduct.mock.calls[0]?.[0]?.isVisible).toBe(true);
    expect(payload.taslak).toBe(false);
  });

  it("fatura dışı ürün tek görselle düzenlenince yayında kalmaz (üç görsel kuralı korunur)", async () => {
    mockGetSupabaseAdmin.mockReturnValue(
      makeAdminStub({
        ...TAM_FATURA_SATIRI,
        source_type: "manual",
        is_visible: true,
        image_urls: [yonetilenGorsel("a.jpg"), yonetilenGorsel("b.jpg"), yonetilenGorsel("c.jpg")],
      }),
    );
    const response = await PATCH(patchRequest({ imageUrls: [yonetilenGorsel("a.jpg")] }));

    expect(response.status).toBe(200);
    expect(mockUpdateRichCoreProduct.mock.calls[0]?.[0]?.isVisible).toBe(false);
  });
});
