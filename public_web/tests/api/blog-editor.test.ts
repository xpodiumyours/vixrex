import { NextRequest } from "next/server";
import { describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  get: vi.fn(() => "owner-cookie"),
  admin: vi.fn(),
  verifyOwner: vi.fn(() => ({ storeId: "store-1" })),
  revalidateTag: vi.fn(),
}));
vi.mock("next/headers", () => ({ cookies: vi.fn(async () => ({ get: mocks.get })) }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.admin }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwner,
}));
vi.mock("next/cache", () => ({ revalidateTag: mocks.revalidateTag }));

import { GET as getArticle, PATCH as patchArticle } from "@/app/api/articles/route";

const ARTICLE = {
  id: "article-1",
  store_slug: "deneme-vitrin",
  slug: "istanbulda-sac-bakimi",
  title: "İstanbul'da Saç Bakımı",
  summary: "Saç bakımına dair kısa özet.",
  content: "Yazının düzenlenebilir tam içeriği.",
};

function queryMock() {
  const query = { select: vi.fn(), eq: vi.fn(), order: vi.fn(), maybeSingle: vi.fn(), update: vi.fn() };
  query.select.mockReturnValue(query);
  query.eq.mockReturnValue(query);
  query.update.mockReturnValue(query);
  query.maybeSingle.mockResolvedValue({ data: ARTICLE, error: null });
  return query;
}

function patchRequest(body: Record<string, unknown>) {
  return new NextRequest("http://localhost/api/articles", {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug: "deneme-vitrin", articleId: "article-1", ...body }),
  });
}

describe("blog editörü API sözleşmesi", () => {
  it("sahibin yazısını vitrin ve yazı slug'ına bağlı tam editör verisiyle getirir", async () => {
    const query = queryMock();
    mocks.admin.mockReturnValue({ from: vi.fn(() => query) });
    const response = await getArticle(new NextRequest(
      "http://localhost/api/articles?slug=deneme-vitrin&articleSlug=istanbulda-sac-bakimi"
    ));

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ tamam: true, yazi: ARTICLE });
    expect(query.select.mock.calls[0][0]).toContain("content");
    expect(query.eq).toHaveBeenCalledWith("store_slug", "deneme-vitrin");
    expect(query.eq).toHaveBeenCalledWith("slug", "istanbulda-sac-bakimi");
  });

  it("yayına gönderilen yazıyı moderasyon ara durumu olmadan yayınlar", async () => {
    const query = queryMock();
    mocks.admin.mockReturnValue({ from: vi.fn(() => query) });
    const response = await patchArticle(patchRequest({
      articleSlug: "istanbulda-sac-bakimi",
      status: "published",
    }));

    expect(response.status).toBe(200);
    expect(query.update).toHaveBeenCalledWith(expect.objectContaining({
      status: "published",
    }));
    expect(query.update.mock.calls[0][0].status).not.toBe("review");
    expect(query.update.mock.calls[0][0]).not.toHaveProperty("published_at");
    expect(mocks.revalidateTag).toHaveBeenCalledWith(
      "store-deneme-vitrin", { expire: 0 }
    );
    expect(mocks.revalidateTag).toHaveBeenCalledWith(
      "article-deneme-vitrin-istanbulda-sac-bakimi", { expire: 0 }
    );
  });

  it("kısmi PATCH'i korur ama boş taslağı yayınlamaz", async () => {
    const query = queryMock();
    query.maybeSingle.mockResolvedValueOnce({
      data: { ...ARTICLE, content: "" }, error: null,
    });
    mocks.admin.mockReturnValue({ from: vi.fn(() => query) });

    const response = await patchArticle(patchRequest({ status: "published" }));

    expect(response.status).toBe(422);
    expect(query.update).not.toHaveBeenCalled();
  });
});
