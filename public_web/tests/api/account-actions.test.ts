import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  createClient: vi.fn(),
  getUser: vi.fn(),
  rpc: vi.fn(),
  revalidateTag: vi.fn(),
}));

vi.mock("@supabase/supabase-js", () => ({ createClient: mocks.createClient }));
vi.mock("next/cache", () => ({ revalidateTag: mocks.revalidateTag }));

import { DELETE, PATCH } from "@/app/api/account/route";

const bearerHeaders = {
  authorization: "Bearer user-access-token",
  "content-type": "application/json",
};

function request(method: "PATCH" | "DELETE", body: Record<string, unknown>) {
  return new NextRequest("http://localhost/api/account", {
    method,
    headers: bearerHeaders,
    body: JSON.stringify(body),
  });
}

describe("hesap ve vitrin işlemleri API sözleşmesi", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-test-key";
    mocks.getUser.mockResolvedValue({
      data: { user: { id: "user-1" } },
      error: null,
    });
    mocks.rpc.mockResolvedValue({ data: null, error: null });
    mocks.createClient.mockReturnValue({
      auth: { getUser: mocks.getUser },
      rpc: mocks.rpc,
    });
  });

  it("Bearer oturumu olmadan yıkıcı işlem yapmaz", async () => {
    const response = await DELETE(new NextRequest("http://localhost/api/account", {
      method: "DELETE",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ target: "account", confirmation: "SİL" }),
    }));

    expect(response.status).toBe(401);
    expect(mocks.rpc).not.toHaveBeenCalled();
  });

  it("yayın rızasını kullanıcının kendi oturumuyla geri çeker", async () => {
    const response = await PATCH(request("PATCH", { slug: "deneme-vitrin" }));

    expect(response.status).toBe(200);
    expect(mocks.rpc).toHaveBeenCalledWith(
      "withdraw_store_publication_consent",
      { p_slug: "deneme-vitrin", p_edit_token: "" }
    );
    expect(mocks.createClient).toHaveBeenCalledWith(
      "https://example.supabase.co",
      "anon-test-key",
      expect.objectContaining({
        global: { headers: { Authorization: "Bearer user-access-token" } },
      })
    );
    for (const tag of ["store-deneme-vitrin", "products-deneme-vitrin", "kesfet", "sitemap"]) {
      expect(mocks.revalidateTag).toHaveBeenCalledWith(tag, { expire: 0 });
    }
  });

  it("SİL doğrulaması olmadan vitrin veya hesap silmez", async () => {
    const response = await DELETE(request("DELETE", {
      target: "store",
      slug: "deneme-vitrin",
      confirmation: "sil",
    }));

    expect(response.status).toBe(422);
    expect(mocks.rpc).not.toHaveBeenCalled();
  });

  it("vitrini kullanıcı sahipliğiyle kalıcı siler", async () => {
    const response = await DELETE(request("DELETE", {
      target: "store",
      slug: "deneme-vitrin",
      confirmation: " SİL ",
    }));

    expect(response.status).toBe(200);
    expect(mocks.rpc).toHaveBeenCalledWith("delete_store_with_token", {
      p_slug: "deneme-vitrin",
      p_edit_token: "",
    });
    expect(response.headers.get("set-cookie")).toContain(
      "vixrex_owner_session=;"
    );
  });

  it("hesabı ve bağlı verileri kullanıcının kendi oturumuyla siler", async () => {
    const response = await DELETE(request("DELETE", {
      target: "account",
      confirmation: "SİL",
    }));

    expect(response.status).toBe(200);
    expect(mocks.rpc).toHaveBeenCalledWith("delete_user_account");
  });
});
