import { beforeAll, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";

const { mockKullaniciRpc, mockGetUser } = vi.hoisted(() => ({
  mockKullaniciRpc: vi.fn(),
  mockGetUser: vi.fn(),
}));

vi.mock("@supabase/supabase-js", () => ({
  createClient: vi.fn(() => ({
    auth: { getUser: mockGetUser },
    rpc: mockKullaniciRpc,
  })),
}));

import { GET } from "@/app/api/owner-dashboard/summary/route";

beforeAll(() => {
  process.env.NEXT_PUBLIC_SUPABASE_URL ||= "http://localhost:54321";
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||= "test-anon-key";
});

function istek(jeton?: string) {
  const headers: Record<string, string> = {};
  if (jeton) headers.authorization = `Bearer ${jeton}`;
  return new NextRequest("http://localhost/api/owner-dashboard/summary", {
    headers,
  });
}

function oturumAcik() {
  mockGetUser.mockResolvedValue({
    data: { user: { id: "u1", is_anonymous: false } },
    error: null,
  });
}

describe("pano özeti", () => {
  it("jeton yokken 401 döner ve hiçbir RPC çağrılmaz", async () => {
    mockKullaniciRpc.mockClear();

    const yanit = await GET(istek());

    expect(yanit.status).toBe(401);
    expect(mockKullaniciRpc).not.toHaveBeenCalled();
  });

  it("vitrini olmayan kullanıcıya 404 döner", async () => {
    mockKullaniciRpc.mockReset();
    oturumAcik();
    mockKullaniciRpc.mockResolvedValue({
      data: { has_store: false },
      error: null,
    });

    const yanit = await GET(istek("jeton"));

    expect(yanit.status).toBe(404);
  });

  it("premium durumunu döner, düzenleme anahtarını sızdırmaz ve sayaç alanı taşımaz", async () => {
    mockKullaniciRpc.mockReset();
    oturumAcik();
    mockKullaniciRpc.mockImplementation((ad: string) => {
      if (ad === "bootstrap_owner_state") {
        return Promise.resolve({
          data: { has_store: true, slug: "deneme", edit_token: "gizli-anahtar" },
          error: null,
        });
      }
      return Promise.resolve({
        data: { is_premium: true, premium_expires_at: "2027-01-01T00:00:00Z" },
        error: null,
      });
    });

    const yanit = await GET(istek("jeton"));
    const govde = await yanit.json();

    expect(yanit.status).toBe(200);
    expect(govde.premiumAktif).toBe(true);
    expect(govde.slug).toBe("deneme");
    expect(JSON.stringify(govde)).not.toContain("gizli-anahtar");
    expect(Object.hasOwn(govde, "olcer")).toBe(false);
    expect(Object.hasOwn(govde, "bugunkuZiyaret")).toBe(false);
    expect(mockKullaniciRpc.mock.calls.map(([ad]) => ad)).toEqual([
      "bootstrap_owner_state",
      "get_store_premium_status",
    ]);
  });

  it("premium sorgusu patlarsa 500 döner", async () => {
    mockKullaniciRpc.mockReset();
    oturumAcik();
    mockKullaniciRpc.mockImplementation((ad: string) => {
      if (ad === "bootstrap_owner_state") {
        return Promise.resolve({
          data: { has_store: true, slug: "deneme", edit_token: "gizli-anahtar" },
          error: null,
        });
      }
      return Promise.resolve({ data: null, error: { message: "boom" } });
    });

    const yanit = await GET(istek("jeton"));

    expect(yanit.status).toBe(500);
  });
});
