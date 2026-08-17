import { describe, it, expect, vi, beforeEach } from "vitest";
import { NextRequest } from "next/server";
import dns from "node:dns";
import { POST } from "@/app/api/instagram/import/route";
import { getConnectedInstagramAccess } from "@/lib/instagramServer";
import { sanitizeInstagramMedia } from "@/lib/instagram";

vi.mock("node:dns", () => ({
  default: {
    promises: {
      lookup: vi
        .fn()
        .mockResolvedValue([{ address: "52.10.20.30", family: 4 }] as never),
    },
  },
}));

const mockResult = { data: null, error: null };
let mockMaybeSingleResult: { data: unknown; error: null | { message?: string } } =
  mockResult;
let mockCreateResult = {
  id: "11111111-1111-1111-1111-111111111111",
  slug: "cool-product-description",
  success: true,
  created: true,
};
const mockBuilder = {
  from: vi.fn().mockReturnThis(),
  select: vi.fn().mockReturnThis(),
  eq: vi.fn().mockReturnThis(),
  maybeSingle: vi.fn().mockImplementation(() =>
    Promise.resolve(mockMaybeSingleResult),
  ),
  update: vi.fn().mockReturnThis(),
  upsert: vi.fn().mockImplementation(() => Promise.resolve(mockResult)),
  rpc: vi.fn().mockImplementation((fn: string) => {
    if (fn === "upsert_store_category") {
      return Promise.resolve({
        data: { id: "22222222-2222-2222-2222-222222222222", success: true },
        error: null,
      });
    }
    if (fn === "create_store_product_v2") {
      return Promise.resolve({
        data: mockCreateResult,
        error: null,
      });
    }
    return Promise.resolve({ data: { success: true }, error: null });
  }),
  then: vi.fn().mockImplementation((resolve) => resolve(mockResult)),
  storage: {
    from: vi.fn().mockReturnThis(),
    upload: vi.fn().mockResolvedValue({ error: null }),
    getPublicUrl: vi.fn().mockReturnValue({ data: { publicUrl: "http://storage/img.jpg" } }),
  },
};

type ConnectedAccess = Awaited<
  ReturnType<typeof getConnectedInstagramAccess>
>;

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
    expiresAt: null,
  };
}

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
    vi.restoreAllMocks();
    vi.clearAllMocks();
    vi.mocked(dns.promises.lookup).mockResolvedValue([
      { address: "52.10.20.30", family: 4 },
    ] as never);
    mockMaybeSingleResult = mockResult;
    mockCreateResult = {
      id: "11111111-1111-1111-1111-111111111111",
      slug: "cool-product-description",
      success: true,
      created: true,
    };
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
    vi.mocked(getConnectedInstagramAccess).mockResolvedValue(
      createConnectedAccess({
        id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
        slug: "test-store",
        name: "Test Store",
        products: [],
      }),
    );

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
    vi.mocked(getConnectedInstagramAccess).mockResolvedValue(
      createConnectedAccess({
        id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
        slug: "test-store",
        name: "Test Store",
        products: [],
      }),
    );

    vi.mocked(sanitizeInstagramMedia).mockReturnValue({
      id: "media-1",
      media_type: "IMAGE",
      media_url: "https://cdn.instagram.com/big.jpg",
    });

    const mockMediaDetails = {
      ok: true,
      json: async () => ({ id: "media-1", media_type: "IMAGE", media_url: "https://cdn.instagram.com/big.jpg" }),
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

  it("imports an image product through relational Product CORE", async () => {
    vi.mocked(getConnectedInstagramAccess).mockResolvedValue(
      createConnectedAccess({
        id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
        slug: "test-store",
        name: "My Store",
        products: [],
      }),
    );

    vi.mocked(sanitizeInstagramMedia).mockReturnValue({
      id: "media-1",
      media_type: "IMAGE",
      media_url: "https://cdn.instagram.com/img.jpg",
      caption: "Cool Product Description #tag",
    });

    const mockMediaDetails = {
      ok: true,
      json: async () => ({ id: "media-1", media_type: "IMAGE", media_url: "https://cdn.instagram.com/img.jpg" }),
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
    const json = await res.json();
    expect(res.status, JSON.stringify(json)).toBe(200);
    expect(json.product.price).toBe("250");
    expect(json.product.imagePath).toBe("http://storage/img.jpg");
    expect(json.product.source).toBe("instagram");
    expect(json.product.id).toBe("11111111-1111-1111-1111-111111111111");
    expect(json.product.slug).toBe("cool-product-description");
    expect(mockBuilder.storage.upload).toHaveBeenCalledWith(
      "test-store/instagram/media-1.jpg",
      expect.any(Buffer),
      expect.objectContaining({
        contentType: "image/jpeg",
        upsert: true,
      }),
    );

    expect(mockBuilder.rpc).toHaveBeenCalledWith(
      "create_store_product_v2",
      expect.objectContaining({
        p_store_id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
        p_edit_token: "token-123",
        p_name: "Cool Product Description",
        p_source_type: "instagram",
        p_external_product_id: "media-1",
      }),
    );
    const createParams = mockBuilder.rpc.mock.calls.find(
      ([fn]) => fn === "create_store_product_v2",
    )?.[1];
    expect(createParams).not.toHaveProperty("p_slug");
    expect(mockBuilder.update).not.toHaveBeenCalledWith(
      expect.objectContaining({ products: expect.any(Array) }),
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

  it("updates an existing Instagram product without changing its CORE slug", async () => {
    mockMaybeSingleResult = {
      data: {
        id: "33333333-3333-3333-3333-333333333333",
        slug: "kalici-urun-urlsi",
        name: "Mevcut Ürün",
        description: "Mevcut açıklama",
        price_text: "100",
        image_urls: ["http://storage/existing.jpg"],
        category_id: "22222222-2222-2222-2222-222222222222",
        stock_status: "Mevcut",
        created_at: "2026-08-01T00:00:00.000Z",
        product_categories: { name: "Instagram Koleksiyonu" },
      },
      error: null,
    };
    mockCreateResult = {
      id: "33333333-3333-3333-3333-333333333333",
      slug: "kalici-urun-urlsi",
      success: true,
      created: false,
    };
    vi.mocked(getConnectedInstagramAccess).mockResolvedValue(
      createConnectedAccess({
        id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
        slug: "test-store",
        name: "My Store",
        products: [],
      }),
    );
    vi.mocked(sanitizeInstagramMedia).mockReturnValue({
      id: "media-1",
      media_type: "IMAGE",
      media_url: "http://example.com/img.jpg",
      caption: "Değişen Instagram metni",
    });
    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      json: async () => ({
        id: "media-1",
        media_type: "IMAGE",
        media_url: "http://example.com/img.jpg",
      }),
    } as Response);

    const req = new NextRequest("http://localhost/api/instagram/import", {
      method: "POST",
      body: JSON.stringify({
        storeSlug: "test-store",
        editToken: "token-123",
        mediaId: "media-1",
        price: "275",
      }),
    });

    const res = await POST(req);
    const json = await res.json();

    expect(res.status).toBe(200);
    expect(json.product.id).toBe("33333333-3333-3333-3333-333333333333");
    expect(json.product.slug).toBe("kalici-urun-urlsi");
    expect(json.product.price).toBe("275");
    expect(mockBuilder.storage.upload).not.toHaveBeenCalled();

    const updateParams = mockBuilder.rpc.mock.calls.find(
      ([fn]) => fn === "update_store_product",
    )?.[1];
    expect(updateParams).toMatchObject({
      p_product_id: "33333333-3333-3333-3333-333333333333",
      p_name: "Mevcut Ürün",
      p_price_text: "275",
    });
    expect(updateParams).not.toHaveProperty("p_slug");
  });

  it("rejects a media URL that redirects to an internal IP literal (SSRF)", async () => {
    vi.mocked(getConnectedInstagramAccess).mockResolvedValue(
      createConnectedAccess({
        id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
        slug: "test-store",
        name: "My Store",
        products: [],
      }),
    );

    vi.mocked(sanitizeInstagramMedia).mockReturnValue({
      id: "media-1",
      media_type: "IMAGE",
      media_url: "https://cdn.instagram.com/img.jpg",
    });

    const mockMediaDetails = {
      ok: true,
      json: async () => ({
        id: "media-1",
        media_type: "IMAGE",
        media_url: "https://cdn.instagram.com/img.jpg",
      }),
    } as Response;

    const redirectResponse = {
      status: 302,
      ok: false,
      headers: new Headers({
        location: "http://169.254.169.254/latest/meta-data",
      }),
    } as unknown as Response;

    vi.spyOn(global, "fetch")
      .mockResolvedValueOnce(mockMediaDetails)
      .mockResolvedValueOnce(redirectResponse);

    const req = new NextRequest("http://localhost/api/instagram/import", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123", mediaId: "media-1" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(422);
    const json = await res.json();
    expect(json.message).toBe("INSTAGRAM_MEDIA_URL_INVALID");
    expect(mockBuilder.storage.upload).not.toHaveBeenCalled();
  });

  it("accepts a valid Instagram CDN redirect chain", async () => {
    vi.mocked(getConnectedInstagramAccess).mockResolvedValue(
      createConnectedAccess({
        id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
        slug: "test-store",
        name: "My Store",
        products: [],
      }),
    );

    vi.mocked(sanitizeInstagramMedia).mockReturnValue({
      id: "media-1",
      media_type: "IMAGE",
      media_url: "https://cdn.instagram.com/img.jpg",
      caption: "Cool Redirect Description",
    });

    const mockMediaDetails = {
      ok: true,
      json: async () => ({
        id: "media-1",
        media_type: "IMAGE",
        media_url: "https://cdn.instagram.com/img.jpg",
      }),
    } as Response;

    const redirectResponse = {
      status: 302,
      ok: false,
      headers: new Headers({
        location: "https://scontent.cdninstagram.com/x.jpg",
      }),
    } as unknown as Response;

    const finalImageResponse = {
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
      .mockResolvedValueOnce(redirectResponse)
      .mockResolvedValueOnce(finalImageResponse);

    const req = new NextRequest("http://localhost/api/instagram/import", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123", mediaId: "media-1" }),
    });

    const res = await POST(req);
    const json = await res.json();
    expect(res.status, JSON.stringify(json)).toBe(200);
    expect(json.product.imagePath).toBe("http://storage/img.jpg");
    expect(mockBuilder.storage.upload).toHaveBeenCalledWith(
      "test-store/instagram/media-1.jpg",
      expect.any(Buffer),
      expect.objectContaining({ contentType: "image/jpeg", upsert: true }),
    );
  });

  it("rejects a CDN host that resolves to an internal IP (DNS-rebinding SSRF)", async () => {
    vi.mocked(dns.promises.lookup).mockResolvedValueOnce([
      { address: "10.0.0.5", family: 4 },
    ] as never);

    vi.mocked(getConnectedInstagramAccess).mockResolvedValue(
      createConnectedAccess({
        id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
        slug: "test-store",
        name: "My Store",
        products: [],
      }),
    );

    vi.mocked(sanitizeInstagramMedia).mockReturnValue({
      id: "media-1",
      media_type: "IMAGE",
      media_url: "https://cdn.instagram.com/img.jpg",
    });

    const mockMediaDetails = {
      ok: true,
      json: async () => ({
        id: "media-1",
        media_type: "IMAGE",
        media_url: "https://cdn.instagram.com/img.jpg",
      }),
    } as Response;

    const redirectResponse = {
      status: 302,
      ok: false,
      headers: new Headers({
        location: "https://scontent.cdninstagram.com/x.jpg",
      }),
    } as unknown as Response;

    vi.spyOn(global, "fetch")
      .mockResolvedValueOnce(mockMediaDetails)
      .mockResolvedValueOnce(redirectResponse);

    const req = new NextRequest("http://localhost/api/instagram/import", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123", mediaId: "media-1" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(422);
    const json = await res.json();
    expect(json.message).toBe("INSTAGRAM_MEDIA_URL_INTERNAL_INVALID");
    expect(mockBuilder.storage.upload).not.toHaveBeenCalled();
  });
});
