import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  createClient: vi.fn(),
  getUser: vi.fn(),
  rpc: vi.fn(),
}));

vi.mock("@supabase/supabase-js", () => ({ createClient: mocks.createClient }));

import { POST } from "@/app/api/create-store/route";

/**
 * Vitrin oluşturma parite testi.
 *
 * Kural: Flutter referansıyla aynı zorunlu alanlar, aynı sahiplik
 * kararı ve aynı taslak sonucu üretilmeli. Next.js yalnızca temel
 * alanları gönderir; eksik alanlar RPC varsayılanlarıyla dolar.
 */
describe("vitrin olusturma parite (Flutter referansiyla)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-test-key";
    mocks.getUser.mockResolvedValue({
      data: { user: { id: "user-1", is_anonymous: false } },
      error: null,
    });
    mocks.rpc.mockResolvedValue({
      data: { ok: true, code: "OWNER_SESSION_CODE" },
      error: null,
    });

    const bosVitrinSorgusu = {
      select: vi.fn(),
      eq: vi.fn(),
      limit: vi.fn(),
      maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
    };
    bosVitrinSorgusu.select.mockReturnValue(bosVitrinSorgusu);
    bosVitrinSorgusu.eq.mockReturnValue(bosVitrinSorgusu);
    bosVitrinSorgusu.limit.mockReturnValue(bosVitrinSorgusu);

    mocks.createClient.mockReturnValue({
      auth: { getUser: mocks.getUser },
      from: vi.fn().mockReturnValue(bosVitrinSorgusu),
      rpc: mocks.rpc,
    });
  });

  it("Flutter gibi yalnizca temel alanlarla vitrin olusturur", async () => {
    const response = await POST(
      new NextRequest("http://localhost/api/create-store", {
        method: "POST",
        headers: {
          authorization: "Bearer user-access-token",
          "content-type": "application/json",
        },
        body: JSON.stringify({
          name: "Test Market",
          kategori: "MARKET",
          whatsapp: "905551234567",
          address: "Test Sokak No:1",
        }),
      }),
    );

    expect(response.status).toBe(200);
    const sonuc = await response.json();
    expect(sonuc.tamam).toBe(true);
    expect(sonuc.slug).toContain("test-market");
  });

  it("Flutter gibi sahiplik karari uygular (claim_store_for_user)", async () => {
    const response = await POST(
      new NextRequest("http://localhost/api/create-store", {
        method: "POST",
        headers: {
          authorization: "Bearer user-access-token",
          "content-type": "application/json",
        },
        body: JSON.stringify({ name: "Test Market" }),
      }),
    );

    expect(response.status).toBe(200);
    // claim_store_for_user RPC cagrildi mi?
    const rpcCalls = mocks.rpc.mock.calls.map((c) => c[0]);
    expect(rpcCalls).toContain("claim_store_for_user");
  });

  it("Flutter gibi calisma taslagi olusturur", async () => {
    const response = await POST(
      new NextRequest("http://localhost/api/create-store", {
        method: "POST",
        headers: {
          authorization: "Bearer user-access-token",
          "content-type": "application/json",
        },
        body: JSON.stringify({ name: "Test Market" }),
      }),
    );

    expect(response.status).toBe(200);
    const rpcCalls = mocks.rpc.mock.calls.map((c) => c[0]);
    expect(rpcCalls).toContain("get_or_create_working_draft");
  });

  it("Flutter gibi sahip oturumu acar ve kod doner", async () => {
    const response = await POST(
      new NextRequest("http://localhost/api/create-store", {
        method: "POST",
        headers: {
          authorization: "Bearer user-access-token",
          "content-type": "application/json",
        },
        body: JSON.stringify({ name: "Test Market" }),
      }),
    );

    expect(response.status).toBe(200);
    const sonuc = await response.json();
    expect(sonuc.yonlendir).toContain("ocode=OWNER_SESSION_CODE");
  });

  it("Flutter gibi isim zorunludur (422)", async () => {
    const response = await POST(
      new NextRequest("http://localhost/api/create-store", {
        method: "POST",
        headers: {
          authorization: "Bearer user-access-token",
          "content-type": "application/json",
        },
        body: JSON.stringify({ name: "" }),
      }),
    );

    expect(response.status).toBe(422);
  });

  it("Flutter gibi oturum zorunludur (401)", async () => {
    const response = await POST(
      new NextRequest("http://localhost/api/create-store", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ name: "Test" }),
      }),
    );

    expect(response.status).toBe(401);
  });
});