import { describe, it, expect, vi, beforeEach } from "vitest";
import { NextRequest } from "next/server";
import { POST } from "@/app/api/instagram/import/route";
import { getConnectedInstagramAccess } from "@/lib/instagramServer";
import { sanitizeInstagramMedia } from "@/lib/instagram";

const mockResult = { data: null, error: null };
type ConnectedInstagramAccess = Awaited<
  ReturnType<typeof getConnectedInstagramAccess>
>;
const mockBuilder = {
  from: vi.fn().mockReturnThis(),
  select: vi.fn().mockReturnThis(),
  eq: vi.fn().mockReturnThis(),
  update: vi.fn().mockReturnThis(),
  upsert: vi.fn().mockImplementation(() => Promise.resolve(mockResult)),
  then: vi.fn().mockImplementation((resolve) => resolve(mockResult)),
  storage: {
    from: vi.fn().mockReturnThis(),
    upload: vi.fn().mockResolvedValue({ error: null }),
    getPublicUrl: vi.fn().mockReturnValue({ data: { publicUrl: "http://storage/img.jpg" } }),
  },
};

vi.mock("@/lib/supabaseAdmin", () => {
  return { getSupabaseAdmin: () => mockBuilder };
});

vi.mock("@/lib/instagramServer", () => ({
  getConnectedInstagramAccess: vi.fn(),
  revalidateProductTargets: vi.fn(),
}));

vi.mock("@/lib/instagram", () => ({
  sanitizeInstagramMedia: vi.fn(),
}));

describe("POST /api/instagram/import", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns 400 if mediaId is missing", async () => {
    const req = new NextRequest("http://localhost/api/instagram/import", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123", mediaId: "" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.message).toBe("INSTAGRAM_MEDIA_ID_REQUIRED");
  });

  it("rejects non-IMAGE media types (422)", async () => {
    vi.mocked(getConnectedInstagramAccess).mockResolvedValue({
      admin: mockBuilder,
      store: { slug: "test-store", products: [] },
      connection: { id: "conn-1" },
      accessToken: "llt-1",
    } as ConnectedInstagramAccess);

    vi.mocked(sanitizeInstagramMedia).mockReturnValue({
      id: "media-1",
      media_type: "VIDEO",
      media_url: "url1",
    });

    const mockMediaDetails = {
      ok: true,
      json: async () => ({ id: "media-1", media_type: "VIDEO" }),
    } as Response;
    vi.spyOn(global, "fetch").mockResolvedValue(mockMediaDetails);

    const req = new NextRequest("http://localhost/api/instagram/import", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123", mediaId: "media-1" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(422);
    const json = await res.json();
    expect(json.message).toBe("INSTAGRAM_MEDIA_TYPE_UNSUPPORTED");
  });

  it("rejects images larger than 6MB (422)", async () => {
    vi.mocked(getConnectedInstagramAccess).mockResolvedValue({
      admin: mockBuilder,
      store: { slug: "test-store", products: [] },
      connection: { id: "conn-1" },
      accessToken: "llt-1",
    } as ConnectedInstagramAccess);

    vi.mocked(sanitizeInstagramMedia).mockReturnValue({
      id: "media-1",
      media_type: "IMAGE",
      media_url: "url1",
    });

    const mockMediaDetails = {
      ok: true,
      json: async () => ({ id: "media-1", media_type: "IMAGE", media_url: "http://example.com/big.jpg" }),
    } as Response;

    const mockImageResponse = {
      ok: true,
      headers: new Headers({ "content-length": String(7 * 1024 * 1024), "content-type": "image/jpeg" }),
    } as Response;

    vi.spyOn(global, "fetch")
      .mockResolvedValueOnce(mockMediaDetails)
      .mockResolvedValueOnce(mockImageResponse);

    const req = new NextRequest("http://localhost/api/instagram/import", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123", mediaId: "media-1" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(422);
    const json = await res.json();
    expect(json.message).toBe("INSTAGRAM_MEDIA_TOO_LARGE");
  });

  it("successfully imports an image product and saves it in store products array", async () => {
    vi.mocked(getConnectedInstagramAccess).mockResolvedValue({
      admin: mockBuilder,
      store: { slug: "test-store", name: "My Store", products: [] },
      connection: { id: "conn-1" },
      accessToken: "llt-1",
    } as ConnectedInstagramAccess);

    vi.mocked(sanitizeInstagramMedia).mockReturnValue({
      id: "media-1",
      media_type: "IMAGE",
      media_url: "http://example.com/img.jpg",
      caption: "Cool Product Description #tag",
    });

    const mockMediaDetails = {
      ok: true,
      json: async () => ({ id: "media-1", media_type: "IMAGE", media_url: "http://example.com/img.jpg" }),
    } as Response;

    const mockImageResponse = {
      ok: true,
      headers: new Headers({ "content-length": "1000", "content-type": "image/jpeg" }),
      body: {
        getReader: () => {
          let count = 0;
          return {
            read: async () => {
              if (count > 0) return { done: true, value: undefined };
              count++;
              return { done: false, value: new Uint8Array([1, 2, 3]) };
            },
          };
        },
      },
    } as unknown as Response;

    vi.spyOn(global, "fetch")
      .mockResolvedValueOnce(mockMediaDetails)
      .mockResolvedValueOnce(mockImageResponse);

    const req = new NextRequest("http://localhost/api/instagram/import", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123", mediaId: "media-1", price: "250" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(200);

    const json = await res.json();
    expect(json.product.price).toBe("250");
    expect(json.product.imagePath).toBe("http://storage/img.jpg");
    expect(json.product.source).toBe("instagram");

    expect(mockBuilder.from).toHaveBeenCalledWith("stores");
    expect(mockBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        products: expect.any(Array),
      })
    );

    expect(mockBuilder.from).toHaveBeenCalledWith("store_instagram_imports");
    expect(mockBuilder.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        store_slug: "test-store",
        connection_id: "conn-1",
        source_media_id: "media-1",
      }),
      { onConflict: "store_slug,source_media_id" }
    );
  });
});
