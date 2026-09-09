import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  cookieGet: vi.fn(),
  verifyOwnerSession: vi.fn(),
  createClient: vi.fn(),
  draftRpc: vi.fn(),
  adminRpc: vi.fn(),
  getSupabaseAdmin: vi.fn(),
  broadcast: vi.fn(),
}));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({ get: mocks.cookieGet })),
}));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwnerSession,
}));
vi.mock("@supabase/supabase-js", () => ({ createClient: mocks.createClient }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.getSupabaseAdmin }));
vi.mock("@/lib/workingDraftBroadcast", () => ({
  broadcastTaslakGuncellendi: mocks.broadcast,
}));

import { POST } from "@/app/api/owner-draft/route";

function request(body: Record<string, unknown>) {
  return new NextRequest("http://localhost/api/owner-draft", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

describe("owner-draft gerçek handler davranışı", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-test-key";
    process.env.VERCEL_ENV = "test";

    mocks.cookieGet.mockReturnValue({ value: "signed-owner-cookie" });
    mocks.verifyOwnerSession.mockReturnValue({
      storeId: "store-1",
      slug: "deneme-vitrin",
      sessionToken: "a".repeat(64),
    });
    mocks.adminRpc.mockResolvedValue({ data: { allowed: true }, error: null });
    mocks.getSupabaseAdmin.mockReturnValue({ rpc: mocks.adminRpc });
    mocks.draftRpc.mockResolvedValue({ data: { draft_version: 7 }, error: null });
    mocks.createClient.mockReturnValue({ rpc: mocks.draftRpc });
  });

  it("yetkisiz istekte yazma RPC'sini çağırmaz", async () => {
    mocks.verifyOwnerSession.mockReturnValue(null);

    const response = await POST(request({
      slug: "deneme-vitrin",
      anahtar: "isletmeAdi",
      deger: "Aymira",
    }));

    expect(response.status).toBe(401);
    expect(mocks.adminRpc).not.toHaveBeenCalled();
    expect(mocks.draftRpc).not.toHaveBeenCalled();
    expect(mocks.broadcast).not.toHaveBeenCalled();
  });

  it("şemada olmayan alanı gerçek validateField ile reddeder", async () => {
    const response = await POST(request({
      slug: "deneme-vitrin",
      anahtar: "olmayanAlan",
      deger: "x",
    }));

    expect(response.status).toBe(422);
    expect(mocks.adminRpc).not.toHaveBeenCalled();
    expect(mocks.draftRpc).not.toHaveBeenCalled();
  });

  it("geçerli alanı gerçek RPC parametreleriyle çalışma taslağına yazar", async () => {
    const response = await POST(request({
      slug: "deneme-vitrin",
      anahtar: "isletmeAdi",
      deger: "Aymira Giyim",
      clientId: "sekme-1",
    }));
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(mocks.adminRpc).toHaveBeenCalledTimes(2);
    expect(mocks.draftRpc).toHaveBeenCalledWith("update_working_draft_field", {
      p_session_token: "a".repeat(64),
      p_key: "name",
      p_value: "Aymira Giyim",
    });
    expect(mocks.broadcast).toHaveBeenCalledWith("deneme-vitrin", "sekme-1");
    expect(body).toMatchObject({
      tamam: true,
      anahtar: "isletmeAdi",
      deger: "Aymira Giyim",
      taslakSurumu: 7,
    });
  });
});
