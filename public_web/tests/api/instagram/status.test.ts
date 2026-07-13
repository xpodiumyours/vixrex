import { describe, it, expect, vi, beforeEach } from "vitest";
import { NextRequest } from "next/server";
import { POST } from "@/app/api/instagram/status/route";
import { verifyStoreEditToken, getConnectedInstagramAccess } from "@/lib/instagramServer";

type MockQueryResult = { data: unknown; error: unknown };
type ConnectedAccess = Awaited<
  ReturnType<typeof getConnectedInstagramAccess>
>;

const mockResult: MockQueryResult = { data: null, error: null };
const mockBuilder = {
  from: vi.fn().mockReturnThis(),
  select: vi.fn().mockReturnThis(),
  eq: vi.fn().mockReturnThis(),
  maybeSingle: vi.fn().mockImplementation(() => Promise.resolve(mockResult)),
  then: vi.fn().mockImplementation((resolve) => resolve(mockResult)),
};

function createConnectedAccess(
  store: ConnectedAccess["store"],
): ConnectedAccess {
  return {
    admin: mockBuilder as unknown as ConnectedAccess["admin"],
    store,
    connection: {
      id: "conn-1",
      store_slug: store.slug,
      status: "connected",
    } as ConnectedAccess["connection"],
    accessToken: "llt-1",
    expiresAt: "2026-12-31",
  };
}

vi.mock("@/lib/supabaseAdmin", () => {
  return { getSupabaseAdmin: () => mockBuilder };
});

vi.mock("@/lib/instagramServer", () => ({
  verifyStoreEditToken: vi.fn(),
  getConnectedInstagramAccess: vi.fn(),
}));

describe("POST /api/instagram/status", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns connected: false if not connected", async () => {
    const mockStore = { slug: "test-store", name: "Test Store" };
    vi.mocked(verifyStoreEditToken).mockResolvedValue(mockStore);

    vi.spyOn(mockBuilder, "maybeSingle").mockResolvedValueOnce({
      data: { status: "disconnected" },
      error: null,
    });

    const req = new NextRequest("http://localhost/api/instagram/status", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.connected).toBe(false);
    expect(json.status).toBe("disconnected");
  });

  it("returns connected: true and details if connected", async () => {
    const mockStore = { slug: "test-store", name: "Test Store" };
    vi.mocked(verifyStoreEditToken).mockResolvedValue(mockStore);

    vi.spyOn(mockBuilder, "maybeSingle").mockResolvedValueOnce({
      data: { status: "connected", username: "tester", account_type: "PERSONAL", expires_at: "2026-12-31" },
      error: null,
    });

    vi.mocked(getConnectedInstagramAccess).mockResolvedValue(
      createConnectedAccess(mockStore),
    );

    const req = new NextRequest("http://localhost/api/instagram/status", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.connected).toBe(true);
    expect(json.status).toBe("connected");
    expect(json.username).toBe("tester");
    expect(json.accountType).toBe("PERSONAL");
    expect(json.expiresAt).toBe("2026-12-31");
  });
});
