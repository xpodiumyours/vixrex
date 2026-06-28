import { describe, it, expect, vi, beforeEach } from "vitest";
import { NextRequest } from "next/server";
import { POST } from "@/app/api/instagram/connect/route";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { verifyStoreEditToken } from "@/lib/instagramServer";

const mockResult = { data: null, error: null };
const mockBuilder = {
  from: vi.fn().mockReturnThis(),
  select: vi.fn().mockReturnThis(),
  eq: vi.fn().mockReturnThis(),
  upsert: vi.fn().mockImplementation(() => Promise.resolve(mockResult)),
  maybeSingle: vi.fn().mockImplementation(() => Promise.resolve(mockResult)),
  then: vi.fn().mockImplementation((resolve) => resolve(mockResult)),
};

vi.mock("@/lib/supabaseAdmin", () => {
  return { getSupabaseAdmin: () => mockBuilder };
});

vi.mock("@/lib/instagramServer", () => ({
  verifyStoreEditToken: vi.fn((slug, token) => {
    if (!slug || !token) {
      throw new Error("STORE_AUTH_REQUIRED");
    }
    return Promise.resolve({ slug, user_id: "test-user-id" });
  }),
}));

describe("POST /api/instagram/connect", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.INSTAGRAM_CLIENT_ID = "test_client_id";
    process.env.NEXT_PUBLIC_SITE_URL = "http://localhost:3000";
    process.env.INSTAGRAM_STATE_SECRET = "test_state_secret_1234567890123456";
    process.env.INSTAGRAM_TOKEN_ENCRYPTION_KEY = Buffer.from("12345678901234567890123456789012").toString("base64");
  });

  it("returns 401 if storeSlug or editToken is missing", async () => {
    const req = new NextRequest("http://localhost/api/instagram/connect", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "", editToken: "" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(401);
    const json = await res.json();
    expect(json.message).toBe("STORE_AUTH_REQUIRED");
  });

  it("returns authorization URL and saves state_nonce on valid credentials", async () => {
    const req = new NextRequest("http://localhost/api/instagram/connect", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "test-token-12345678901234567890" }),
      headers: {
        origin: "http://localhost:3000",
      },
    });

    const res = await POST(req);
    expect(res.status).toBe(200);

    const json = await res.json();
    expect(json.authorizationUrl).toContain("instagram.com/oauth/authorize");
    expect(json.authorizationUrl).toContain("client_id=test_client_id");

    expect(mockBuilder.from).toHaveBeenCalledWith("store_instagram_connections");
    expect(mockBuilder.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        store_slug: "test-store",
        user_id: "test-user-id",
        status: "pending",
        state_nonce: expect.any(String),
      }),
      { onConflict: "store_slug" }
    );
  });
});
