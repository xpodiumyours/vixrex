import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  cookieGet: vi.fn(),
  verifyOwnerSession: vi.fn(),
  createClient: vi.fn(),
  rpc: vi.fn(),
  revalidatePath: vi.fn(),
}));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({ get: mocks.cookieGet })),
}));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwnerSession,
}));
vi.mock("@supabase/supabase-js", () => ({ createClient: mocks.createClient }));
vi.mock("next/cache", () => ({ revalidatePath: mocks.revalidatePath }));

import { POST } from "@/app/api/owner-discard/route";

function request(body: Record<string, unknown>) {
  return new NextRequest("http://localhost/api/owner-discard", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

describe("owner-discard gerçek handler davranışı", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-test-key";

    mocks.cookieGet.mockReturnValue({ value: "signed-owner-cookie" });
    mocks.verifyOwnerSession.mockReturnValue({
      storeId: "store-1",
      slug: "deneme-vitrin",
      sessionToken: "d".repeat(64),
    });
    mocks.rpc.mockResolvedValue({ data: { discarded: true }, error: null });
    mocks.createClient.mockReturnValue({ rpc: mocks.rpc });
  });

  it("yetkisiz istekte taslağı silmez", async () => {
    mocks.verifyOwnerSession.mockReturnValue(null);

    const response = await POST(request({ slug: "deneme-vitrin" }));

    expect(response.status).toBe(401);
    expect(mocks.rpc).not.toHaveBeenCalled();
    expect(mocks.revalidatePath).not.toHaveBeenCalled();
  });

  it("RPC oturum hatasını 401 olarak taşır", async () => {
    mocks.rpc.mockResolvedValue({
      data: null,
      error: { message: "INVALID_SESSION_TOKEN" },
    });

    const response = await POST(request({ slug: "deneme-vitrin" }));

    expect(response.status).toBe(401);
    expect(mocks.revalidatePath).not.toHaveBeenCalled();
  });

  it("başarılı vazgeçmede yalnız discard RPC'sini çağırır ve yolu tazeler", async () => {
    const response = await POST(request({ slug: "deneme-vitrin" }));
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(mocks.rpc).toHaveBeenCalledTimes(1);
    expect(mocks.rpc).toHaveBeenCalledWith("discard_working_draft", {
      p_session_token: "d".repeat(64),
    });
    expect(mocks.revalidatePath).toHaveBeenCalledWith("/v/deneme-vitrin");
    expect(body).toEqual({ tamam: true, silindi: true });
  });
});
