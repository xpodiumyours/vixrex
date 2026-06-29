import { describe, it, expect, vi, beforeEach } from "vitest";
import { NextRequest } from "next/server";
import { GET } from "@/app/api/instagram/callback/route";
import { decodeInstagramState } from "@/lib/instagram";
import { exchangeForLongLivedInstagramToken } from "@/lib/instagramServer";
import {
  createSupabaseMockBuilder,
  type QueryResult,
} from "../../helpers/createSupabaseMockBuilder";

type MaybeSingleResult<T> = QueryResult<T>;
const mockBuilder = createSupabaseMockBuilder();

vi.mock("@/lib/supabaseAdmin", () => {
  return { getSupabaseAdmin: () => mockBuilder };
});

vi.mock("@/lib/instagram", () => ({
  decodeInstagramState: vi.fn(),
  encryptSecret: vi.fn((token) => `encrypted_${token}`),
}));

vi.mock("@/lib/instagramServer", () => ({
  exchangeForLongLivedInstagramToken: vi.fn(),
}));

describe("GET /api/instagram/callback", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.INSTAGRAM_CLIENT_ID = "test_client_id";
    process.env.INSTAGRAM_CLIENT_SECRET = "test_client_secret";
  });

  it("redirects with status=error if code or state is missing", async () => {
    const req = new NextRequest("http://localhost/api/instagram/callback");
    const res = await GET(req);
    expect(res.status).toBe(307);
    const redirectUrl = res.headers.get("location");
    expect(redirectUrl).toContain("instagram=error");
  });

  it("handles token exchange success and updates connection status to connected", async () => {
    const statePayload = { storeSlug: "test-store", nonce: "test-nonce", returnTo: "/v/test-store", createdAt: Date.now() };
    vi.mocked(decodeInstagramState).mockReturnValue(statePayload);

    // Mock finding connection
    vi.spyOn(mockBuilder, "maybeSingle").mockResolvedValueOnce({
      data: { id: "connection-uuid", store_slug: "test-store", state_nonce: "test-nonce", status: "pending" },
      error: null,
    } as MaybeSingleResult<{
      id: string;
      store_slug: string;
      state_nonce: string;
      status: string;
    }>);

    // Mock fetch for token exchange and profile API
    const mockTokenExchange = {
      ok: true,
      json: async () => ({ access_token: "short_lived_token", user_id: "ig_user_123" }),
    } as Response;
    const mockProfileInfo = {
      ok: true,
      json: async () => ({ id: "ig_user_123", username: "test_ig_user", account_type: "PERSONAL" }),
    } as Response;

    const fetchSpy = vi.spyOn(global, "fetch");
    fetchSpy
      .mockResolvedValueOnce(mockTokenExchange)
      .mockResolvedValueOnce(mockProfileInfo);

    vi.mocked(exchangeForLongLivedInstagramToken).mockResolvedValue({
      access_token: "long_lived_token",
      token_type: "bearer",
      expires_in: 5184000,
    });

    const req = new NextRequest("http://localhost/api/instagram/callback?code=test_code&state=test_state");
    const res = await GET(req);

    expect(res.status).toBe(307);
    const redirectUrl = res.headers.get("location");
    expect(redirectUrl).toContain("/v/test-store");
    expect(redirectUrl).toContain("instagram=connected");

    expect(mockBuilder.from).toHaveBeenCalledWith("store_instagram_tokens");
    expect(mockBuilder.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        connection_id: "connection-uuid",
        access_token_ciphertext: "encrypted_long_lived_token",
      }),
      { onConflict: "connection_id" }
    );

    expect(mockBuilder.from).toHaveBeenCalledWith("store_instagram_connections");
    expect(mockBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        status: "connected",
        instagram_user_id: "ig_user_123",
        username: "test_ig_user",
        account_type: "PERSONAL",
      })
    );
  });
});
