import { readFileSync } from "fs";
import { resolve } from "path";
import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const { mockCreateClient, mockGetUser, mockRpc } = vi.hoisted(() => ({
  mockCreateClient: vi.fn(),
  mockGetUser: vi.fn(),
  mockRpc: vi.fn(),
}));

vi.mock("@supabase/supabase-js", () => ({
  createClient: mockCreateClient,
}));

import { POST } from "@/app/api/rent-demo/hesap/route";

const routePath = resolve(
  __dirname,
  "../src/app/api/rent-demo/hesap/route.ts"
);

describe("hesaba bağlı vitrin kiralama sözleşmesi", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "https://example.supabase.co");
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY", "anon-key");
    mockCreateClient.mockReturnValue({
      auth: { getUser: mockGetUser },
      rpc: mockRpc,
    });
  });

  it("kanonik kiralama RPC'sini kullanıcı oturumuyla çağırır", () => {
    const routeSource = readFileSync(routePath, "utf8");

    expect(routeSource).toContain('"rent_demo_canonical"');
    expect(routeSource).not.toContain('"rent_demo_for_account"');
    expect(routeSource).not.toContain("getSupabaseAdmin");
  });

  it("jeton yokken 401 döner ve RPC'ye gitmez", async () => {
    const response = await POST(
      new NextRequest("http://localhost/api/rent-demo/hesap", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ slug: "kiralik-vitrin" }),
      })
    );

    expect(response.status).toBe(401);
    expect(mockRpc).not.toHaveBeenCalled();
    expect(mockCreateClient).not.toHaveBeenCalled();
  });

  it("başarılı yanıtta düzenleme anahtarını tarayıcıya taşımaz", async () => {
    mockGetUser.mockResolvedValue({
      data: { user: { id: "user-1" } },
      error: null,
    });
    mockRpc
      .mockResolvedValueOnce({
        data: {
          ok: true,
          reason: "RENTED",
          slug: "yeni-vitrin",
          edit_token: "gizli-duzenleme-anahtari",
        },
        error: null,
      })
      .mockResolvedValueOnce({
        data: { code: "tek-kullanimlik-kod" },
        error: null,
      });

    const response = await POST(
      new NextRequest("http://localhost/api/rent-demo/hesap", {
        method: "POST",
        headers: {
          authorization: "Bearer user-token",
          "content-type": "application/json",
        },
        body: JSON.stringify({ slug: "kiralik-vitrin" }),
      })
    );

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      tamam: true,
      slug: "yeni-vitrin",
      yonlendir:
        "/api/owner-session?slug=yeni-vitrin&ocode=tek-kullanimlik-kod",
    });
    expect(mockRpc).toHaveBeenNthCalledWith(1, "rent_demo_canonical", {
      p_source_slug: "kiralik-vitrin",
      p_flow_type: "kiralama",
    });
    expect(mockRpc).toHaveBeenNthCalledWith(2, "create_owner_session", {
      p_slug: "yeni-vitrin",
      p_edit_token: "gizli-duzenleme-anahtari",
    });
  });
});
