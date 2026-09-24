import { beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";

const { mockGet, mockCreateRichCoreProduct, mockUpdateRichCoreProduct, mockGetSupabaseAdmin, mockVerifyOwnerSession } =
  vi.hoisted(() => ({
    mockGet: vi.fn(() => ({ value: "cerez-degeri" })),
    mockCreateRichCoreProduct: vi.fn(async (_args: Record<string, unknown>) => ({
      id: "prod-1",
      slug: "prod-1",
      created: true,
    })),
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
  createRichCoreProduct: mockCreateRichCoreProduct,
  updateRichCoreProduct: mockUpdateRichCoreProduct,
}));

import { PATCH, POST } from "@/app/api/products/route";

const SLUG = "deneme-vitrin";
const PRODUCT_ID = "11111111-1111-1111-1111-111111111111";

function yonetilenGorsel(dosyaAdi: string) {
  return `https://ornekproje.supabase.co/storage/v1/object/public/shelf-images/magaza-1/products/${dosyaAdi}`;
}

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

function postRequest(body: Record<string, unknown>) {
  return new NextRequest("http://localhost/api/products", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug: SLUG, categoryId: "", brand: "Test Marka", ...body }),
  });
}

function patchRequest(body: Record<string, unknown>) {
  return new NextRequest("http://localhost/api/products", {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug: SLUG, productId: PRODUCT_ID, ...body }),
  });
}

const TAM_URUN_SATIRI = {
  name: "Mevcut Ürün",
  description: "",
  price_text: "199 TL",
  price_amount: 199,
  category_id: null,
  metadata: {},
  variants: [],
  brand: "Test Marka",
  barcode: null,
  stock_quantity: null,
  stock_status: "Mevcut",
  old_price_amount: null,
  badge_tag: null,
  fulfillment_region: null,
};

describe("/api/products fotoğraf sayısı artık kaydı engellemiyor", () => {
  beforeEach(() => {
    mockCreateRichCoreProduct.mockClear();
    mockUpdateRichCoreProduct.mockClear();
  });

  it("POST: tek fotoğrafla ürün taslak olarak kaydedilir, engel olmaz", async () => {
    mockGetSupabaseAdmin.mockReturnValue(makeAdminStub(null));
    const response = await POST(
      postRequest({ name: "Deneme Ürün", imageUrls: [yonetilenGorsel("a.jpg")] }),
    );
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload.taslak).toBe(true);
    expect(payload.eksikFotografSayisi).toBe(2);
    expect(mockCreateRichCoreProduct).toHaveBeenCalledTimes(1);
    expect(mockCreateRichCoreProduct.mock.calls[0]?.[0]?.isVisible).toBe(false);
  });

  it("POST: 3 fotoğrafla ürün doğrudan yayında kaydedilir", async () => {
    mockGetSupabaseAdmin.mockReturnValue(makeAdminStub(null));
    const response = await POST(
      postRequest({
        name: "Deneme Ürün",
        imageUrls: [yonetilenGorsel("a.jpg"), yonetilenGorsel("b.jpg"), yonetilenGorsel("c.jpg")],
      }),
    );
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload.taslak).toBe(false);
    expect(payload.eksikFotografSayisi).toBe(0);
    expect(mockCreateRichCoreProduct.mock.calls[0]?.[0]?.isVisible).toBe(true);
  });

  it("POST: 11'den fazla fotoğrafta yine engel olur", async () => {
    mockGetSupabaseAdmin.mockReturnValue(makeAdminStub(null));
    const cok = Array.from({ length: 12 }, (_, i) => yonetilenGorsel(`${i}.jpg`));
    const response = await POST(postRequest({ name: "Deneme Ürün", imageUrls: cok }));
    const payload = await response.json();

    expect(response.status).toBe(422);
    expect(payload.hata).toContain("en fazla");
    expect(mockCreateRichCoreProduct).not.toHaveBeenCalled();
  });

  it("POST: Vixrex dışı bağlantıda yine engel olur", async () => {
    mockGetSupabaseAdmin.mockReturnValue(makeAdminStub(null));
    const response = await POST(
      postRequest({ name: "Deneme Ürün", imageUrls: ["https://baska-site.com/gorsel.jpg"] }),
    );
    const payload = await response.json();

    expect(response.status).toBe(422);
    expect(payload.hata).toContain("Görsel ekle alanından");
    expect(mockCreateRichCoreProduct).not.toHaveBeenCalled();
  });

  it("PATCH: fotoğraf sayısı 3'ten 1'e düşürülünce kayıt engellenmez, ürün taslağa döner", async () => {
    mockGetSupabaseAdmin.mockReturnValue(
      makeAdminStub({
        ...TAM_URUN_SATIRI,
        image_urls: [yonetilenGorsel("a.jpg"), yonetilenGorsel("b.jpg"), yonetilenGorsel("c.jpg")],
      }),
    );
    const response = await PATCH(patchRequest({ imageUrls: [yonetilenGorsel("a.jpg")] }));
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload.taslak).toBe(true);
    expect(payload.eksikFotografSayisi).toBe(2);
    expect(mockUpdateRichCoreProduct.mock.calls[0]?.[0]?.isVisible).toBe(false);
  });

  it("PATCH: fotoğraf sayısı 1'den 3'e tamamlanınca ürün otomatik yayına döner", async () => {
    mockGetSupabaseAdmin.mockReturnValue(
      makeAdminStub({ ...TAM_URUN_SATIRI, image_urls: [yonetilenGorsel("a.jpg")] }),
    );
    const response = await PATCH(
      patchRequest({
        imageUrls: [yonetilenGorsel("a.jpg"), yonetilenGorsel("b.jpg"), yonetilenGorsel("c.jpg")],
      }),
    );
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload.taslak).toBe(false);
    expect(mockUpdateRichCoreProduct.mock.calls[0]?.[0]?.isVisible).toBe(true);
  });

  it("PATCH: fotoğraflara dokunulmadan başka alan güncellenince görünürlük yeniden hesaplanmaz", async () => {
    mockGetSupabaseAdmin.mockReturnValue(
      makeAdminStub({ ...TAM_URUN_SATIRI, image_urls: [yonetilenGorsel("a.jpg")] }),
    );
    const response = await PATCH(patchRequest({ priceText: "249 TL" }));
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload.taslak).toBe(true);
    expect(payload.eksikFotografSayisi).toBe(2);
    expect(mockUpdateRichCoreProduct.mock.calls[0]?.[0]?.isVisible).toBeUndefined();
  });
});
