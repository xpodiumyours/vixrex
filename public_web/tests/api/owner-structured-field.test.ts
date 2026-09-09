import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  cookieGet: vi.fn(),
  verifyOwnerSession: vi.fn(),
  getSupabaseAdmin: vi.fn(),
  rpc: vi.fn(),
}));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({ get: mocks.cookieGet })),
}));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwnerSession,
}));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.getSupabaseAdmin }));

import { POST } from "@/app/api/owner-structured-field/route";

function request(body: Record<string, unknown>) {
  return new NextRequest("http://localhost/api/owner-structured-field", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

describe("owner-structured-field gerçek handler davranışı", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.cookieGet.mockReturnValue({ value: "signed-owner-cookie" });
    mocks.verifyOwnerSession.mockReturnValue({
      storeId: "store-1",
      slug: "deneme-vitrin",
      sessionToken: "c".repeat(64),
    });
    mocks.rpc.mockResolvedValue({ data: null, error: null });
    mocks.getSupabaseAdmin.mockReturnValue({ rpc: mocks.rpc });
  });

  it("izin listesinde olmayan JSONB kolonu reddeder", async () => {
    const response = await POST(request({
      slug: "deneme-vitrin",
      kolon: "draft_data",
      deger: {},
    }));

    expect(response.status).toBe(403);
    expect(mocks.rpc).not.toHaveBeenCalled();
  });

  it("yetkisiz istekte yapılandırılmış alan yazmaz", async () => {
    mocks.verifyOwnerSession.mockReturnValue(null);

    const response = await POST(request({
      slug: "deneme-vitrin",
      kolon: "faq_items",
      deger: [],
    }));

    expect(response.status).toBe(401);
    expect(mocks.rpc).not.toHaveBeenCalled();
  });

  it("JSON olmayan skaler değeri reddeder", async () => {
    const response = await POST(request({
      slug: "deneme-vitrin",
      kolon: "faq_items",
      deger: "yanlış-tip",
    }));

    expect(response.status).toBe(400);
    expect(mocks.rpc).not.toHaveBeenCalled();
  });

  it("izinli JSONB alanını gerçek RPC gövdesiyle kaydeder", async () => {
    const faq = [{ soru: "Açık mısınız?", cevap: "Evet" }];
    const response = await POST(request({
      slug: "deneme-vitrin",
      kolon: "faq_items",
      deger: faq,
    }));
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(mocks.rpc).toHaveBeenCalledWith("update_working_draft_field", {
      p_session_token: "c".repeat(64),
      p_key: "faq_items",
      p_value: JSON.stringify(faq),
    });
    expect(body).toEqual({ tamam: true, kolon: "faq_items" });
  });
});
