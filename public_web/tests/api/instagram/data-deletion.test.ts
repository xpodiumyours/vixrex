import { describe, it, expect, vi, beforeEach } from "vitest";
import { NextRequest } from "next/server";
import { POST } from "@/app/api/meta/data-deletion/route";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import crypto from "crypto";
import { revalidateTag } from "next/cache";

const mockResult = { data: null, error: null };
const mockBuilder = {
  from: vi.fn().mockReturnThis(),
  select: vi.fn().mockReturnThis(),
  eq: vi.fn().mockReturnThis(),
  delete: vi.fn().mockReturnThis(),
  update: vi.fn().mockReturnThis(),
  maybeSingle: vi.fn().mockImplementation(() => Promise.resolve(mockResult)),
  insert: vi.fn().mockImplementation(() => Promise.resolve(mockResult)),
  then: vi.fn().mockImplementation((resolve) => resolve(mockResult)),
  storage: {
    from: vi.fn().mockReturnThis(),
    list: vi.fn().mockResolvedValue({ data: [], error: null }),
    remove: vi.fn().mockResolvedValue({ data: [], error: null }),
  },
};

vi.mock("@/lib/supabaseAdmin", () => {
  return { getSupabaseAdmin: () => mockBuilder };
});

vi.mock("next/cache", () => ({
  revalidateTag: vi.fn(),
}));

function createSignedRequest(payload: object, secret: string) {
  const encodedPayload = Buffer.from(JSON.stringify(payload)).toString("base64url");
  const expectedSig = crypto
    .createHmac("sha256", secret)
    .update(encodedPayload)
    .digest("base64url");
  return `${expectedSig}.${encodedPayload}`;
}

describe("POST /api/meta/data-deletion", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.INSTAGRAM_CLIENT_SECRET = "my_app_secret";
  });

  it("returns 400 if signed_request is missing", async () => {
    const req = new NextRequest("http://localhost/api/meta/data-deletion", {
      method: "POST",
      body: JSON.stringify({}),
    });

    const res = await POST(req);
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.error).toBe("Missing signed_request");
  });

  it("verifies the signed request, processes Mod B cleanup, and returns confirmation code", async () => {
    const payload = {
      user_id: "meta_user_123",
      algorithm: "HMAC-SHA256",
    };
    const signedRequest = createSignedRequest(payload, "my_app_secret");

    // Mock eq sequence for connections select and imports select, then return this for later queries
    vi.spyOn(mockBuilder, "eq")
      .mockResolvedValueOnce({
        data: [{ id: "conn-123", store_slug: "user-store" }],
        error: null,
      } as any) // connections select eq
      .mockResolvedValueOnce({
        data: [{ product_slug: "p1" }],
        error: null,
      } as any) // imports select eq
      .mockImplementation(() => mockBuilder);

    // Mock finding store products
    vi.spyOn(mockBuilder, "maybeSingle").mockResolvedValueOnce({
      data: {
        products: [
          { slug: "p1", source: "instagram" },
          { slug: "p2", source: "manual" },
        ],
      },
      error: null,
    } as any);

    // Mock storage files listing
    vi.spyOn(mockBuilder.storage, "list").mockResolvedValue({
      data: [{ name: "img.jpg" }],
      error: null,
    } as any);

    const req = new NextRequest("http://localhost/api/meta/data-deletion", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ signed_request: signedRequest }),
    });

    const res = await POST(req);
    expect(res.status).toBe(200);

    const json = await res.json();
    expect(json.confirmation_code).toBeDefined();
    expect(json.url).toContain(json.confirmation_code);

    expect(mockBuilder.from).toHaveBeenCalledWith("store_instagram_tokens");

    expect(mockBuilder.from).toHaveBeenCalledWith("stores");
    expect(mockBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        products: [{ slug: "p2", source: "manual" }],
      })
    );

    expect(mockBuilder.from).toHaveBeenCalledWith("store_instagram_imports");

    expect(mockBuilder.storage.from).toHaveBeenCalledWith("shelf-images");
    expect(mockBuilder.storage.remove).toHaveBeenCalledWith(["user-store/instagram/img.jpg"]);

    expect(mockBuilder.from).toHaveBeenCalledWith("store_instagram_connections");
    expect(mockBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        status: "disconnected",
      })
    );

    expect(mockBuilder.from).toHaveBeenCalledWith("meta_data_deletion_requests");
    expect(mockBuilder.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        provider_user_id: "meta_user_123",
        store_slug: "user-store",
        status: "completed",
      })
    );

    expect(revalidateTag).toHaveBeenCalledWith("store-user-store", "max");
    expect(revalidateTag).toHaveBeenCalledWith("products-user-store", "max");
    expect(revalidateTag).toHaveBeenCalledWith("sitemap", "max");
  });

  it("returns 400 for invalid/malformed signature", async () => {
    const payload = {
      user_id: "meta_user_123",
      algorithm: "HMAC-SHA256",
    };
    const signedRequest = createSignedRequest(payload, "wrong_secret");

    const req = new NextRequest("http://localhost/api/meta/data-deletion", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ signed_request: signedRequest }),
    });

    const res = await POST(req);
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.error).toBe("Signature verification failed");
  });

  it("generates different confirmation codes for subsequent calls", async () => {
    const payload = {
      user_id: "meta_user_123",
      algorithm: "HMAC-SHA256",
    };
    const signedRequest = createSignedRequest(payload, "my_app_secret");

    vi.spyOn(mockBuilder, "eq")
      .mockResolvedValueOnce({
        data: [{ id: "conn-123", store_slug: "user-store" }],
        error: null,
      } as any) // req 1 connections select
      .mockResolvedValueOnce({
        data: [{ product_slug: "p1" }],
        error: null,
      } as any) // req 1 imports select
      .mockImplementationOnce(() => mockBuilder) // req 1 stores select
      .mockImplementationOnce(() => mockBuilder) // req 1 stores update
      .mockImplementationOnce(() => mockBuilder) // req 1 imports delete
      .mockImplementationOnce(() => mockBuilder) // req 1 tokens delete
      .mockImplementationOnce(() => mockBuilder) // req 1 connections status update
      .mockResolvedValueOnce({
        data: [{ id: "conn-123", store_slug: "user-store" }],
        error: null,
      } as any) // req 2 connections select
      .mockResolvedValueOnce({
        data: [{ product_slug: "p1" }],
        error: null,
      } as any) // req 2 imports select
      .mockImplementation(() => mockBuilder); // all other calls

    const req1 = new NextRequest("http://localhost/api/meta/data-deletion", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ signed_request: signedRequest }),
    });
    const res1 = await POST(req1);
    const json1 = await res1.json();

    const req2 = new NextRequest("http://localhost/api/meta/data-deletion", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ signed_request: signedRequest }),
    });
    const res2 = await POST(req2);
    const json2 = await res2.json();

    expect(json1.confirmation_code).toBeDefined();
    expect(json2.confirmation_code).toBeDefined();
    expect(json1.confirmation_code).not.toBe(json2.confirmation_code);
  });
});
