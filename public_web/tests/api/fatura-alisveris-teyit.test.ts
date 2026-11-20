import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const m = vi.hoisted(() => ({
  cookie: vi.fn(),
  verifyOwner: vi.fn(),
  active: vi.fn(),
  verifyToken: vi.fn(),
  admin: vi.fn(),
  updatePayload: vi.fn(),
  jobsData: [] as Array<{ id: string }>,
  updateError: null as { message: string } | null,
}));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({ get: m.cookie })),
}));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: m.verifyOwner,
}));
vi.mock("@/lib/ownerSessionValidity", () => ({
  ownerSessionStillActive: m.active,
}));
vi.mock("@/lib/instagramServer", () => ({
  verifyStoreEditToken: m.verifyToken,
}));
vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: m.admin,
}));

import { POST } from "@/app/api/fatura-alisveris-teyit/route";

const ID_1 = "11111111-1111-4111-8111-111111111111";
const ID_2 = "22222222-2222-4222-8222-222222222222";
const STORE_ID = "33333333-3333-4333-8333-333333333333";

function mockAdminBuilder() {
  return {
    from: vi.fn(() => ({
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          in: vi.fn(async () => ({ data: m.jobsData, error: null })),
        })),
      })),
      update: vi.fn((payload: unknown) => {
        m.updatePayload(payload);
        return {
          eq: vi.fn(() => ({
            eq: vi.fn(async () => ({ error: m.updateError })),
          })),
        };
      }),
    })),
  };
}

function makeRequest(body: unknown) {
  return new NextRequest("http://localhost/api/fatura-alisveris-teyit", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

describe("/api/fatura-alisveris-teyit", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    m.cookie.mockReturnValue({ value: "signed-owner-cookie" });
    m.verifyOwner.mockReturnValue({
      storeId: STORE_ID,
      slug: "esnaf",
      sessionToken: "a".repeat(64),
    });
    m.active.mockResolvedValue(true);
    m.verifyToken.mockRejectedValue(new Error("INVALID_EDIT_TOKEN"));
    m.jobsData = [{ id: ID_1 }, { id: ID_2 }];
    m.updateError = null;
    m.admin.mockImplementation(mockAdminBuilder);
  });

  it("aktif oturum çereziyle teyidi kaydeder", async () => {
    const res = await POST(
      makeRequest({
        slug: "esnaf",
        islemKimligi: ID_1,
        digerIslemKimligi: ID_2,
        ayni: true,
      }),
    );
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ tamam: true, ayni: true });
    expect(m.active).toHaveBeenCalledOnce();
    expect(m.updatePayload).toHaveBeenCalledWith(
      expect.objectContaining({ same_purchase_of: ID_2 }),
    );
  });

  it("iptal edilmiş oturum çereziyle 401 döner ve DB güncellemez", async () => {
    m.active.mockResolvedValueOnce(false);
    const res = await POST(
      makeRequest({
        slug: "esnaf",
        islemKimligi: ID_1,
        digerIslemKimligi: ID_2,
        ayni: false,
      }),
    );
    expect(res.status).toBe(401);
    expect(m.active).toHaveBeenCalledOnce();
    expect(m.updatePayload).not.toHaveBeenCalled();
  });

  it("iptal edilmiş çerez yanında geçerli Flutter editToken ile çalışır", async () => {
    m.active.mockResolvedValueOnce(false);
    m.verifyToken.mockResolvedValueOnce({ id: STORE_ID, slug: "esnaf" });
    const res = await POST(
      makeRequest({
        slug: "esnaf",
        islemKimligi: ID_1,
        digerIslemKimligi: ID_2,
        ayni: false,
        editToken: "valid-edit-token",
      }),
    );
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ tamam: true, ayni: false });
    expect(m.updatePayload).toHaveBeenCalledWith(
      expect.objectContaining({ same_purchase_of: null }),
    );
  });

  it("çerez ve editToken yoksa 401 döner", async () => {
    m.verifyOwner.mockReturnValueOnce(null);
    const res = await POST(
      makeRequest({
        slug: "esnaf",
        islemKimligi: ID_1,
        digerIslemKimligi: ID_2,
        ayni: true,
      }),
    );
    expect(res.status).toBe(401);
    expect(m.updatePayload).not.toHaveBeenCalled();
  });

  it("aynı işlem kimlikleri veya geçersiz UUID için 422 döner", async () => {
    const sameRes = await POST(
      makeRequest({
        slug: "esnaf",
        islemKimligi: ID_1,
        digerIslemKimligi: ID_1,
        ayni: true,
      }),
    );
    expect(sameRes.status).toBe(422);

    const badRes = await POST(
      makeRequest({
        slug: "esnaf",
        islemKimligi: "gecersiz",
        digerIslemKimligi: ID_2,
        ayni: true,
      }),
    );
    expect(badRes.status).toBe(422);
  });
});
