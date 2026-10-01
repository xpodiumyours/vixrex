import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

// /api/fatura-yayinla — Bilgileri onayla ile Yayınla iki ayrı eylemdir.
// Bu uç taslağı sunucuda tekrar okuyup görünür yapar; kapı kapalıysa ürün
// taslak kalır ve somut sebep döner.

const mocks = vi.hoisted(() => ({
  get: vi.fn(() => "owner-cookie"),
  admin: vi.fn(),
  verifyOwner: vi.fn((): { storeId: string; slug: string } | null => ({ storeId: "store-1", slug: "deneme-vitrin" })),
  verifyToken: vi.fn(),
  publish: vi.fn(
    async (_args: Record<string, unknown>): Promise<{ success: boolean; id?: string; hata?: string }> => ({
      success: true,
      id: "urun-1",
    }),
  ),
}));
vi.mock("next/headers", () => ({ cookies: vi.fn(async () => ({ get: mocks.get })) }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.admin }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwner,
}));
vi.mock("@/lib/instagramServer", () => ({ verifyStoreEditToken: mocks.verifyToken }));
vi.mock("@/lib/productCoreServer", () => ({ publishInvoiceProduct: mocks.publish }));

import { POST as faturaYayinla } from "@/app/api/fatura-yayinla/route";

const STORE = { id: "store-1", edit_token: "token-1" };

const FOTOGRAFLAR = [
  "https://tedarikci.example.com/1.jpg",
  "https://tedarikci.example.com/2.jpg",
  "https://tedarikci.example.com/3.jpg",
];

const TASLAK_FATURA_URUNU = {
  id: "urun-1",
  source_type: "invoice",
  is_visible: false,
  price_amount: 199,
  image_urls: FOTOGRAFLAR,
  stock_quantity: 2,
  fatura_kanit: { kartDurumu: "kanitli", stokOnaylandi: true },
};

let urunSatiri: Record<string, unknown> | null = TASLAK_FATURA_URUNU;

function adminMock() {
  return {
    from: vi.fn((tablo: string) => {
      if (tablo === "stores") {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              single: vi.fn(async () => ({ data: STORE, error: null })),
            })),
          })),
        };
      }
      if (tablo === "products") {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(() => ({
                maybeSingle: vi.fn(async () => ({ data: urunSatiri, error: null })),
              })),
            })),
          })),
        };
      }
      throw new Error(`beklenmeyen tablo: ${tablo}`);
    }),
  };
}

function istek(govde: unknown) {
  return new NextRequest("http://localhost/api/fatura-yayinla", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(govde),
  });
}

describe("/api/fatura-yayinla — ayrı Yayınla kapısı", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.get.mockReturnValue("owner-cookie");
    mocks.verifyOwner.mockReturnValue({ storeId: "store-1", slug: "deneme-vitrin" });
    mocks.admin.mockImplementation(adminMock);
    mocks.publish.mockResolvedValue({ success: true, id: "urun-1" });
    urunSatiri = { ...TASLAK_FATURA_URUNU };
  });

  it("hazır taslak çerez oturumuyla yayınlanır", async () => {
    const cevap = await faturaYayinla(istek({ slug: "deneme-vitrin", productIds: ["urun-1"] }));
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.yayinda).toBe(1);
    expect(govde.taslak).toBe(0);
    expect(mocks.publish).toHaveBeenCalledTimes(1);
    expect(mocks.publish.mock.calls[0][0]).toMatchObject({
      productId: "urun-1",
      editToken: "token-1",
    });
  });

  it("Flutter edit_token yoluyla da aynı kapıdan yayınlanır", async () => {
    mocks.verifyOwner.mockReturnValue(null);
    mocks.verifyToken.mockResolvedValue({ id: "store-1", slug: "deneme-vitrin" });

    const cevap = await faturaYayinla(
      istek({ slug: "deneme-vitrin", productIds: ["urun-1"], editToken: "token-1" }),
    );
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.yayinda).toBe(1);
    expect(mocks.publish.mock.calls[0][0]).toMatchObject({ editToken: "token-1" });
  });

  it("ne çerez ne jeton varsa 401 döner", async () => {
    mocks.verifyOwner.mockReturnValue(null);

    const cevap = await faturaYayinla(istek({ slug: "deneme-vitrin", productIds: ["urun-1"] }));

    expect(cevap.status).toBe(401);
    expect(mocks.publish).not.toHaveBeenCalled();
  });

  it("fatura dışı ürün bu uçtan yayınlanmaz", async () => {
    urunSatiri = { ...TASLAK_FATURA_URUNU, source_type: "manual" };

    const cevap = await faturaYayinla(istek({ slug: "deneme-vitrin", productIds: ["urun-1"] }));
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(0);
    expect(govde.taslak).toBe(1);
    expect(govde.satirlar[0].sebep).toContain("fatura akışı");
    expect(mocks.publish).not.toHaveBeenCalled();
  });

  it("zaten yayındaki ürün için güncel kaynak ve izin yeniden doğrulanır", async () => {
    urunSatiri = { ...TASLAK_FATURA_URUNU, is_visible: true };

    const cevap = await faturaYayinla(istek({ slug: "deneme-vitrin", productIds: ["urun-1"] }));
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(1);
    expect(mocks.publish).toHaveBeenCalledOnce();
  });

  it("başka vitrinin ürünü yayınlanmaz", async () => {
    urunSatiri = null;

    const cevap = await faturaYayinla(istek({ slug: "deneme-vitrin", productIds: ["urun-1"] }));
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(0);
    expect(govde.satirlar[0].sebep).toContain("vitrine ait");
    expect(mocks.publish).not.toHaveBeenCalled();
  });

  it("publish RPC kapıyı kapatırsa taslak kalır ve sebep yazar", async () => {
    mocks.publish.mockResolvedValue({ success: false, hata: "Satış fiyatı girilmedi." });

    const cevap = await faturaYayinla(istek({ slug: "deneme-vitrin", productIds: ["urun-1"] }));
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(0);
    expect(govde.taslak).toBe(1);
    expect(govde.satirlar[0].sebep).toContain("Satış fiyatı");
  });

  it("ürün listesi boşsa 422 döner", async () => {
    const cevap = await faturaYayinla(istek({ slug: "deneme-vitrin", productIds: [] }));

    expect(cevap.status).toBe(422);
    expect(mocks.publish).not.toHaveBeenCalled();
  });
  it("yayındaki üründe güncel firma reddi başarılı yayın diye dönmez", async () => {
    urunSatiri = { ...TASLAK_FATURA_URUNU, is_visible: true };
    mocks.publish.mockResolvedValueOnce({ success: false, hata: "Firma içerik kullanımını reddetti." });
    const body = await (await faturaYayinla(istek({ slug: "deneme-vitrin", productIds: ["urun-1"] }))).json();
    expect(mocks.publish).toHaveBeenCalledOnce();
    expect(body.yayinda).toBe(0);
    expect(body.satirlar[0].sebep).toContain("reddetti");
  });

});
