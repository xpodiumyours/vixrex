import { describe, it, expect, vi, beforeEach } from "vitest";
import { NextRequest } from "next/server";
import { POST } from "@/app/api/instagram/media/route";
import { getConnectedInstagramAccess } from "@/lib/instagramServer";

type ConnectedInstagramAccess = Awaited<
  ReturnType<typeof getConnectedInstagramAccess>
>;

vi.mock("@/lib/instagramServer", () => ({
  getConnectedInstagramAccess: vi.fn(),
}));

vi.mock("@/lib/instagram", () => ({
  sanitizeInstagramMedia: vi.fn((m) => ({
    id: m.id,
    caption: m.caption,
    media_type: m.media_type,
    media_url: m.media_url,
    permalink: m.permalink,
    timestamp: m.timestamp,
  })),
}));

describe("POST /api/instagram/media", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns expired/missing token errors as a user-friendly error", async () => {
    vi.mocked(getConnectedInstagramAccess).mockRejectedValue(new Error("INSTAGRAM_TOKEN_EXPIRED"));

    const req = new NextRequest("http://localhost/api/instagram/media", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(409); // Status mapping for TOKEN_EXPIRED is 409
    const json = await res.json();
    expect(json.message).toBe("INSTAGRAM_TOKEN_EXPIRED");
  });

  it("filters and returns only permitted media types (IMAGE)", async () => {
    vi.mocked(getConnectedInstagramAccess).mockResolvedValue({
      accessToken: "mock-access-token",
    } as ConnectedInstagramAccess);

    const mockGraphResponse = {
      ok: true,
      json: async () => ({
        data: [
          { id: "1", caption: "Photo post", media_type: "IMAGE", media_url: "url1" },
          { id: "2", caption: "Video post", media_type: "VIDEO", media_url: "url2" },
          { id: "3", caption: "Carousel post", media_type: "CAROUSEL_ALBUM", media_url: "url3" },
        ],
      }),
    } as Response;

    vi.spyOn(global, "fetch").mockResolvedValue(mockGraphResponse);

    const req = new NextRequest("http://localhost/api/instagram/media", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(200);

    const json = await res.json();
    expect(json.media).toHaveLength(1);
    expect(json.media[0].id).toBe("1");
    expect(json.media[0].media_type).toBe("IMAGE");
  });
});
