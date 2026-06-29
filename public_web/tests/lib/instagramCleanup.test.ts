import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  loadStoreProducts,
  persistRetainedProducts,
  removeInstagramStorageFiles,
  markInstagramConnectionDisconnected,
  revalidateInstagramCleanup,
} from "@/lib/instagramCleanup";
import { createSupabaseMockBuilder } from "../helpers/createSupabaseMockBuilder";

vi.mock("next/cache", () => ({
  revalidateTag: vi.fn(),
}));

import { revalidateTag } from "next/cache";

describe("loadStoreProducts", () => {
  let admin: ReturnType<typeof createSupabaseMockBuilder>;

  beforeEach(() => {
    admin = createSupabaseMockBuilder();
    vi.clearAllMocks();
  });

  it("returns inline products when already an array", async () => {
    const products = [{ name: "Product A", slug: "p-a" }];
    const result = await loadStoreProducts(admin, { storeSlug: "test", products });
    expect(result).toEqual(products);
  });

  it("returns null when products is null and fallback disabled", async () => {
    const result = await loadStoreProducts(admin, { storeSlug: "test", products: null });
    expect(result).toBeNull();
  });

  it("fetches products from DB when allowStoreFetchFallback is true", async () => {
    const dbProducts = [{ name: "DB Product", slug: "db-p" }];
    vi.spyOn(admin, "maybeSingle").mockResolvedValueOnce({
      data: { products: dbProducts },
      error: null,
    });

    const result = await loadStoreProducts(admin, {
      storeSlug: "test",
      products: null,
      allowStoreFetchFallback: true,
    });
    expect(result).toEqual(dbProducts);
  });

  it("returns null when DB has no products and fallback enabled", async () => {
    vi.spyOn(admin, "maybeSingle").mockResolvedValueOnce({
      data: null,
      error: null,
    });

    const result = await loadStoreProducts(admin, {
      storeSlug: "test",
      products: null,
      allowStoreFetchFallback: true,
    });
    expect(result).toBeNull();
  });
});

describe("persistRetainedProducts", () => {
  let admin: ReturnType<typeof createSupabaseMockBuilder>;

  beforeEach(() => {
    admin = createSupabaseMockBuilder();
    vi.clearAllMocks();
  });

  it("filters out instagram products and updates the store", async () => {
    const products = [
      { name: "IG Product", slug: "ig-p", source: "instagram" },
      { name: "Manual Product", slug: "manual-p", source: "manual" },
    ];

    await persistRetainedProducts(admin, { storeSlug: "test-store", products });

    expect(admin.from).toHaveBeenCalledWith("stores");
    expect(admin.update).toHaveBeenCalledWith(
      expect.objectContaining({
        products: [{ name: "Manual Product", slug: "manual-p", source: "manual" }],
      }),
    );
  });

  it("throws when supabase returns an error", async () => {
    vi.spyOn(admin, "eq").mockResolvedValueOnce({
      data: null,
      error: new Error("DB_ERROR"),
    });

    await expect(
      persistRetainedProducts(admin, {
        storeSlug: "test-store",
        products: [{ name: "P", slug: "p", source: "manual" }],
      }),
    ).rejects.toThrow("DB_ERROR");
  });
});

describe("removeInstagramStorageFiles", () => {
  let admin: ReturnType<typeof createSupabaseMockBuilder>;

  beforeEach(() => {
    admin = createSupabaseMockBuilder();
    vi.clearAllMocks();
  });

  it("removes files under {storeSlug}/instagram/", async () => {
    vi.spyOn(admin.storage, "list").mockResolvedValueOnce({
      data: [{ name: "img1.jpg" }, { name: "img2.jpg" }],
      error: null,
    });

    await removeInstagramStorageFiles(admin, "my-store", "test");

    expect(admin.storage.remove).toHaveBeenCalledWith([
      "my-store/instagram/img1.jpg",
      "my-store/instagram/img2.jpg",
    ]);
  });

  it("skips removal when no files exist", async () => {
    vi.spyOn(admin.storage, "list").mockResolvedValueOnce({
      data: [],
      error: null,
    });

    await removeInstagramStorageFiles(admin, "empty-store", "test");

    expect(admin.storage.remove).not.toHaveBeenCalled();
  });

  it("skips removal when list returns an error", async () => {
    vi.spyOn(admin.storage, "list").mockResolvedValueOnce({
      data: null,
      error: new Error("LIST_ERROR"),
    });

    await removeInstagramStorageFiles(admin, "err-store", "test");

    expect(admin.storage.remove).not.toHaveBeenCalled();
  });
});

describe("markInstagramConnectionDisconnected", () => {
  let admin: ReturnType<typeof createSupabaseMockBuilder>;

  beforeEach(() => {
    admin = createSupabaseMockBuilder();
    vi.clearAllMocks();
  });

  it("updates connection status to disconnected and clears nonce", async () => {
    await markInstagramConnectionDisconnected(admin, "conn-123");

    expect(admin.from).toHaveBeenCalledWith("store_instagram_connections");
    expect(admin.update).toHaveBeenCalledWith(
      expect.objectContaining({
        status: "disconnected",
        state_nonce: null,
      }),
    );
    expect(admin.eq).toHaveBeenCalledWith("id", "conn-123");
  });
});

describe("revalidateInstagramCleanup", () => {
  it("revalidates store, products, and sitemap tags", () => {
    revalidateInstagramCleanup("my-store");
    expect(revalidateTag).toHaveBeenCalledWith("store-my-store", "max");
    expect(revalidateTag).toHaveBeenCalledWith("products-my-store", "max");
    expect(revalidateTag).toHaveBeenCalledWith("sitemap", "max");
  });
});
