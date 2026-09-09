// @vitest-environment jsdom

import React from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { FaqEditor } from "@/app/v/[slug]/components/FaqEditor";

const refreshMock = vi.hoisted(() => vi.fn());
vi.mock("next/navigation", () => ({ useRouter: () => ({ refresh: refreshMock }) }));

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  vi.unstubAllGlobals();
});

describe("SSS yönetimi gerçek etkileşim", () => {
  it("soru-cevap çiftini structured-field API'sine kaydeder", async () => {
    const fetchMock = vi.fn(async (_input: RequestInfo | URL, _init?: RequestInit) => ({
      ok: true,
      json: async () => ({}),
    } as Response));
    vi.stubGlobal("fetch", fetchMock);
    const onClose = vi.fn();
    const user = userEvent.setup();

    render(<FaqEditor slug="demo-vitrin" items={[]} onClose={onClose} inline />);

    await user.type(screen.getByPlaceholderText("Soru yazın..."), "Kargo var mı?");
    await user.type(screen.getByPlaceholderText("Cevap yazın..."), "Evet, Türkiye geneline gönderim var.");
    await user.click(screen.getByRole("button", { name: "Kaydet" }));

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1));
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("/api/owner-structured-field");
    expect(init?.method).toBe("POST");
    const body = JSON.parse(String(init?.body));
    expect(body.slug).toBe("demo-vitrin");
    expect(body.kolon).toBe("faq_items");
    expect(body.deger).toHaveLength(1);
    expect(body.deger[0]).toMatchObject({
      question: "Kargo var mı?",
      answer: "Evet, Türkiye geneline gönderim var.",
    });
    await waitFor(() => expect(refreshMock).toHaveBeenCalledTimes(1));
    expect(onClose).toHaveBeenCalledTimes(1);
  });
});
