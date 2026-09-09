// @vitest-environment jsdom

import React from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { OwnerProductManager } from "@/components/owner/OwnerProductManager";

vi.mock("next/image", () => ({ default: () => <span data-testid="next-image" /> }));
vi.mock("@/lib/productQueue", () => ({
  productQueueEnqueue: vi.fn(),
  productQueueCount: vi.fn(() => 0),
  productQueueFlush: vi.fn(async () => ({ flushed: 0, remaining: 0 })),
}));

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  vi.unstubAllGlobals();
});

describe("Ürün yönetimi gerçek etkileşim", () => {
  it("formdan yeni ürünü products API'sine POST eder ve başarıyı gösterir", async () => {
    const fetchMock = vi.fn(async (_input: RequestInfo | URL, _init?: RequestInit) => ({
      ok: true,
      json: async () => ({ id: "urun-1" }),
    } as Response));
    vi.stubGlobal("fetch", fetchMock);
    const onRefresh = vi.fn(async () => {});
    const user = userEvent.setup();

    render(
      <OwnerProductManager
        storeSlug="demo-vitrin"
        products={[]}
        categories={[]}
        onRefresh={onRefresh}
      />,
    );

    await user.click(screen.getByRole("button", { name: /Ürün Ekle/i }));
    await user.type(screen.getByLabelText(/Ürün adı/i), "Test Ürünü");
    await user.type(screen.getByLabelText(/^Fiyat$/i), "499 TL");
    await user.type(screen.getByLabelText(/Kısa açıklama/i), "Gerçek etkileşim testi ürünü");
    await user.click(screen.getByRole("button", { name: "Ürünü Kaydet" }));

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1));
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("/api/products");
    expect(init?.method).toBe("POST");
    expect(JSON.parse(String(init?.body))).toEqual({
      slug: "demo-vitrin",
      name: "Test Ürünü",
      description: "Gerçek etkileşim testi ürünü",
      priceText: "499 TL",
      imageUrls: [],
      categoryId: "",
      stockStatus: "Mevcut",
      oldPriceAmount: null,
      badgeTag: null,
      fulfillmentRegion: null,
    });
    await waitFor(() => expect(onRefresh).toHaveBeenCalledTimes(1));
    expect(screen.getByRole("status").textContent).toContain("Ürün kaydedildi.");
  });
});
