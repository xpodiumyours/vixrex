import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

// /api/fatura-izin — hazır kart üzerinden firma izin talebi.
// Talep ile firma onayı ayrıdır; aynı işe tekrar talep yağmaz.

const mocks = vi.hoisted(() => ({
  get: vi.fn(() => "owner-cookie"),
  admin: vi.fn(),
  verifyOwner: vi.fn((): { storeId: string } | null => ({ storeId: "store-1" })),
  mevcut: null as { id: string } | null,
}));

vi.mock("next/headers", () => ({ cookies: vi.fn(async () => ({ get: mocks.get })) }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.admin }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwner,
}));

import { GET as talepleriOku, POST as talepYaz, PATCH as talepGuncelle } from "@/app/api/fatura-izin/route";

function adminMock() {
  return {
    from: vi.fn((tablo: string) => {
      if (tablo !== "invoice_permission_requests") throw new Error(`beklenmeyen tablo: ${tablo}`);
      return {
        select: vi.fn(() => {
          const z = {
            eq: vi.fn(() => z),
            order: vi.fn(() => ({
              limit: vi.fn(async () => ({ data: [], error: null })),
            })),
            limit: vi.fn(() => ({
              maybeSingle: vi.fn(async () => ({ data: mocks.mevcut, error: null })),
            })),
          };
          return z;
        }),
        insert: vi.fn(() => ({
          select: vi.fn(() => ({
            single: vi.fn(async () => ({ data: { id: "talep-1" }, error: null })),
          })),
        })),
        update: vi.fn(() => ({
          eq: vi.fn(() => ({
            eq: vi.fn(async () => ({ error: null })),
          })),
        })),
      };
    }),
  };
}

function jsonIstegi(yol: string, govde: unknown, yontem = "POST") {
  return new NextRequest(`http://localhost${yol}`, {
    method: yontem,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(govde),
  });
}

describe("/api/fatura-izin — izin talebi", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.get.mockReturnValue("owner-cookie");
    mocks.verifyOwner.mockReturnValue({ storeId: "store-1" });
    mocks.admin.mockImplementation(adminMock);
    mocks.mevcut = null;
  });

  it("oturumsuz talep 401 doner", async () => {
    mocks.verifyOwner.mockReturnValue(null);
    const cevap = await talepYaz(jsonIstegi("/api/fatura-izin", { slug: "deneme", firma: "Isilay" }));
    expect(cevap.status).toBe(401);
  });

  it("firma yazilmadan talep acilmaz", async () => {
    const cevap = await talepYaz(jsonIstegi("/api/fatura-izin", { slug: "deneme", firma: "" }));
    expect(cevap.status).toBe(422);
  });

  it("yeni talep kaydedilir", async () => {
    const cevap = await talepYaz(
      jsonIstegi("/api/fatura-izin", { slug: "deneme", firma: "Isilay", sorumlu: "vixrex" }),
    );
    const govde = await cevap.json();
    expect(cevap.status).toBe(200);
    expect(govde.id).toBe("talep-1");
  });

  it("ayni ise ikinci talep acilmaz, mevcut doner", async () => {
    mocks.mevcut = { id: "talep-9" };
    const cevap = await talepYaz(
      jsonIstegi("/api/fatura-izin", {
        slug: "deneme",
        firma: "Isilay",
        sorumlu: "esnaf",
        islemKimligi: "is-1",
      }),
    );
    const govde = await cevap.json();
    expect(govde.mevcut).toBe(true);
    expect(govde.id).toBe("talep-9");
  });

  it("durum guncellenir", async () => {
    const cevap = await talepGuncelle(
      jsonIstegi("/api/fatura-izin", { slug: "deneme", id: "talep-1", durum: "gonderildi" }, "PATCH"),
    );
    expect((await cevap.json()).tamam).toBe(true);
  });

  it("liste okunur", async () => {
    const cevap = await talepleriOku(
      new NextRequest("http://localhost/api/fatura-izin?slug=deneme", { method: "GET" }),
    );
    expect((await cevap.json()).talepler).toEqual([]);
  });
});
