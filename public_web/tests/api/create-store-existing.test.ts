import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  createClient: vi.fn(),
  getUser: vi.fn(),
  rpc: vi.fn(),
}));

vi.mock("@supabase/supabase-js", () => ({ createClient: mocks.createClient }));

import { POST } from "@/app/api/create-store/route";

describe("mevcut vitrini olan hesap için create-store", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-test-key";
    mocks.getUser.mockResolvedValue({
      data: { user: { id: "user-1" } },
      error: null,
    });
    mocks.rpc.mockResolvedValue({
      data: { ok: false, reason: "ALREADY_OWNS_STORE" },
      error: null,
    });

    const mevcutVitrinSorgusu = {
      select: vi.fn(),
      eq: vi.fn(),
      limit: vi.fn(),
      maybeSingle: vi.fn().mockResolvedValue({
        data: { slug: "mevcut-vitrin" },
        error: null,
      }),
    };
    mevcutVitrinSorgusu.select.mockReturnValue(mevcutVitrinSorgusu);
    mevcutVitrinSorgusu.eq.mockReturnValue(mevcutVitrinSorgusu);
    mevcutVitrinSorgusu.limit.mockReturnValue(mevcutVitrinSorgusu);

    mocks.createClient.mockReturnValue({
      auth: { getUser: mocks.getUser },
      from: vi.fn().mockReturnValue(mevcutVitrinSorgusu),
      rpc: mocks.rpc,
    });
  });

  it("yeni kayıt açmadan 409 ve mevcut slug değerini döndürür", async () => {
    const response = await POST(
      new NextRequest("http://localhost/api/create-store", {
        method: "POST",
        headers: {
          authorization: "Bearer user-access-token",
          "content-type": "application/json",
        },
        body: JSON.stringify({ name: "Yeni Vitrin" }),
      }),
    );

    expect(response.status).toBe(409);
    await expect(response.json()).resolves.toMatchObject({
      slug: "mevcut-vitrin",
    });
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
});
