// @vitest-environment jsdom

import React from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { VitrinimEditor } from "@/components/owner/VitrinimEditor";

vi.mock("next/image", () => ({ default: () => <span data-testid="next-image" /> }));
vi.mock("next/link", () => ({
  default: ({ href, children }: { href: string; children: React.ReactNode }) => <a href={href}>{children}</a>,
}));
vi.mock("@/components/owner/VitrinPaylasimKarti", () => ({
  VitrinPaylasimKarti: () => <div data-testid="paylasim-karti" />,
}));

const store = {
  slug: "demo-vitrin",
  name: "Eski Dükkan",
  is_published: false,
  products: [],
  product_categories: [],
};

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  vi.unstubAllGlobals();
});

describe("Vitrin düzenleme gerçek etkileşim", () => {
  it("işletme adını blur ile owner-draft API'sine kaydeder", async () => {
    const fetchMock = vi.fn(async (_input: RequestInfo | URL, _init?: RequestInit) => ({
      ok: true,
      json: async () => ({}),
    } as Response));
    vi.stubGlobal("fetch", fetchMock);
    const user = userEvent.setup();

    render(
      <VitrinimEditor
        store={store}
        initialDraft={{ name: "Eski Dükkan" }}
        onRefresh={vi.fn(async () => {})}
      />,
    );

    const input = screen.getByLabelText(/İşletme \/ Vixrex Adı/i) as HTMLInputElement;
    await waitFor(() => expect(input.value).toBe("Eski Dükkan"));
    await user.clear(input);
    await user.type(input, "Yeni Dükkan");
    await user.tab();

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1));
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("/api/owner-draft");
    expect(init?.method).toBe("POST");
    expect(JSON.parse(String(init?.body))).toEqual({
      slug: "demo-vitrin",
      anahtar: "isletmeAdi",
      deger: "Yeni Dükkan",
      clientId: null,
    });
    expect(screen.getByRole("status").textContent).toContain("Değişiklik kaydedildi.");
  });

  it("owner-draft hatasını kullanıcıya görünür gösterir", async () => {
    const fetchMock = vi.fn(async (_input: RequestInfo | URL, _init?: RequestInit) => ({
      ok: false,
      json: async () => ({ hata: "Taslak kaydedilemedi." }),
    } as Response));
    vi.stubGlobal("fetch", fetchMock);
    const user = userEvent.setup();

    render(
      <VitrinimEditor
        store={store}
        initialDraft={{ name: "Eski Dükkan" }}
        onRefresh={vi.fn(async () => {})}
      />,
    );

    const input = screen.getByLabelText(/İşletme \/ Vixrex Adı/i);
    await user.clear(input);
    await user.type(input, "Hatalı Kayıt");
    await user.tab();

    await waitFor(() => expect(screen.getByRole("status").textContent).toContain("Taslak kaydedilemedi."));
  });
});
