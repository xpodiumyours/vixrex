import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

// /api/fatura-islem — esnaf ekranı kapatıp aynı işten devam eder.
// Yalnız bu vitrine ait kayıt döner; satırlar + bağlı ürün kimlikleri gelir.

const mocks = vi.hoisted(() => ({
  get: vi.fn(() => "owner-cookie"),
  admin: vi.fn(),
  verifyOwner: vi.fn((): { storeId: string; slug: string } | null => ({ storeId: "store-1", slug: "deneme" })),
}));

vi.mock("next/headers", () => ({ cookies: vi.fn(async () => ({ get: mocks.get })) }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.admin }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwner,
}));
vi.mock("@/lib/instagramServer", () => ({ verifyStoreEditToken: vi.fn() }));

import { GET as islemAc } from "@/app/api/fatura-islem/route";

const IS = {
  id: "is-1",
  store_id: "store-1",
  status: "inceleme",
  supplier_name: "Glisa",
  supplier_site: "glisa.com",
  document_adet: 8,
  document_total: 3960,
  supplier_trace: { belgeNo: "2026/123" },
  updated_at: "2026-09-30",
};

const SATIRLAR = [
  {
    line_index: 0,
    model: "16747",
    product_name: "Interlok Takım",
    barcode: "",
    variant_name: "",
    size_text: "",
    qty: 8,
    unit_price: 450,
    line_total: 3600,
    confidence: 0.8,
    outcome: "kanitli",
    raw_line: "16747 8 450",
  },
];

function adminMock() {
  return {
    from: vi.fn((tablo: string) => {
      if (tablo === "invoice_jobs") {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              maybeSingle: vi.fn(async () => ({ data: IS, error: null })),
            })),
          })),
        };
      }
      if (tablo === "invoice_job_lines") {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              order: vi.fn(async () => ({ data: SATIRLAR, error: null })),
            })),
          })),
        };
      }
      if (tablo === "invoice_product_links") {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(async () => ({ data: [{ line_index: 0, product_id: "urun-1" }], error: null })),
          })),
        };
      }
      throw new Error(`beklenmeyen tablo: ${tablo}`);
    }),
  };
}

function istek(slug: string, islem: string) {
  return new NextRequest(`http://localhost/api/fatura-islem?slug=${slug}&islem=${islem}`, { method: "GET" });
}

describe("/api/fatura-islem — geri acma", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.get.mockReturnValue("owner-cookie");
    mocks.verifyOwner.mockReturnValue({ storeId: "store-1", slug: "deneme" });
    mocks.admin.mockImplementation(adminMock);
  });

  it("oturum yoksa 401 doner", async () => {
    mocks.verifyOwner.mockReturnValue(null);
    const cevap = await islemAc(istek("deneme", "is-1"));
    expect(cevap.status).toBe(401);
  });

  it("vitrin ve islem zorunludur", async () => {
    const cevap = await islemAc(istek("", ""));
    expect(cevap.status).toBe(422);
  });

  it("satirlari bagli urun kimligiyle dondurur", async () => {
    const cevap = await islemAc(istek("deneme", "is-1"));
    const govde = await cevap.json();
    expect(cevap.status).toBe(200);
    expect(govde.islemKimligi).toBe("is-1");
    expect(govde.tedarikci).toBe("Glisa");
    expect(govde.satirlar).toHaveLength(1);
    expect(govde.satirlar[0].urunId).toBe("urun-1");
    expect(govde.satirlar[0].outcome).toBe("kanitli");
  });
});
