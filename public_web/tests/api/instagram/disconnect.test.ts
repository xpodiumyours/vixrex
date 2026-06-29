import { describe, it, expect, vi, beforeEach } from "vitest";
import { NextRequest } from "next/server";
import { POST } from "@/app/api/instagram/disconnect/route";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import { revalidateTag } from "next/cache";

const mockResult: { data: unknown; error: null } = { data: null, error: null };
const mockBuilder = {
  from: vi.fn().mockReturnThis(),
  select: vi.fn().mockReturnThis(),
  eq: vi.fn().mockReturnThis(),
  delete: vi.fn().mockReturnThis(),
  update: vi.fn().mockReturnThis(),
  maybeSingle: vi.fn().mockImplementation(() => Promise.resolve(mockResult)),
  then: vi.fn().mockImplementation((resolve) => resolve(mockResult)),
  storage: {
    from: vi.fn().mockReturnThis(),
    list: vi.fn().mockResolvedValue({ data: [] as { name: string }[], error: null }),
    remove: vi.fn().mockResolvedValue({ data: [], error: null }),
  },
};

vi.mock("@/lib/supabaseAdmin", () => {
  return { getSupabaseAdmin: () => mockBuilder };
});

vi.mock("@/lib/instagramServer", () => ({
  verifyStoreEditToken: vi.fn((slug) => Promise.resolve({ slug, name: "My Store", products: [] })),
}));

vi.mock("next/cache", () => ({
  revalidateTag: vi.fn(),
  revalidatePath: vi.fn(),
}));

describe("POST /api/instagram/disconnect", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.INSTAGRAM_STATE_SECRET = "test_state_secret_1234567890123456";
    process.env.INSTAGRAM_TOKEN_ENCRYPTION_KEY = Buffer.from("12345678901234567890123456789012").toString("base64");
  });

  it("handles Mod A (Default): disconnects connection, marks imports as retained, deletes token", async () => {
    const mockStore = { slug: "test-store", name: "Test Store", products: [{ slug: "p1", source: "instagram" }] };
    vi.mocked(verifyStoreEditToken).mockResolvedValue(mockStore);

    vi.spyOn(mockBuilder, "maybeSingle").mockResolvedValueOnce({
      data: { id: "conn-1" },
      error: null,
    });

    const req = new NextRequest("http://localhost/api/instagram/disconnect", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123", mode: "A" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(200);

    const json = await res.json();
    expect(json.disconnected).toBe(true);

    expect(mockBuilder.from).toHaveBeenCalledWith("store_instagram_tokens");
    expect(mockBuilder.delete).toHaveBeenCalled();

    expect(mockBuilder.from).toHaveBeenCalledWith("store_instagram_imports");
    expect(mockBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        status: "retained",
      })
    );

    expect(mockBuilder.from).toHaveBeenCalledWith("store_instagram_connections");
    expect(mockBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        status: "disconnected",
      })
    );
  });

  it("handles Mod B: disconnects connection, cleans up tokens, imports, products, and storage", async () => {
    const mockStore = {
      slug: "test-store",
      name: "Test Store",
      products: [
        { slug: "p1", source: "instagram" },
        { slug: "p2", source: "manual" },
      ],
    };
    vi.mocked(verifyStoreEditToken).mockResolvedValue(mockStore);

    vi.spyOn(mockBuilder, "maybeSingle").mockResolvedValueOnce({
      data: { id: "conn-1" },
      error: null,
    });

    vi.spyOn(mockBuilder.storage, "list").mockResolvedValue({
      data: [{ name: "img1.jpg" }, { name: "img2.jpg" }],
      error: null,
    });

    const req = new NextRequest("http://localhost/api/instagram/disconnect", {
      method: "POST",
      body: JSON.stringify({ storeSlug: "test-store", editToken: "token-123", mode: "B" }),
    });

    const res = await POST(req);
    expect(res.status).toBe(200);

    expect(mockBuilder.from).toHaveBeenCalledWith("store_instagram_tokens");

    expect(mockBuilder.from).toHaveBeenCalledWith("stores");
    expect(mockBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        products: [{ slug: "p2", source: "manual" }],
      })
    );

    expect(mockBuilder.from).toHaveBeenCalledWith("store_instagram_imports");

    expect(mockBuilder.storage.from).toHaveBeenCalledWith("shelf-images");
    expect(mockBuilder.storage.remove).toHaveBeenCalledWith([
      "test-store/instagram/img1.jpg",
      "test-store/instagram/img2.jpg",
    ]);

    expect(revalidateTag).toHaveBeenCalledWith("store-test-store", "max");
    expect(revalidateTag).toHaveBeenCalledWith("products-test-store", "max");
    expect(revalidateTag).toHaveBeenCalledWith("sitemap", "max");
  });
});
