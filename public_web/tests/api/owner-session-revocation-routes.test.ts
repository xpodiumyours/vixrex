import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const m = vi.hoisted(() => ({
  cookie: vi.fn(() => ({ value: "signed-owner-cookie" })),
  owner: vi.fn(() => ({
    storeId: "11111111-1111-4111-8111-111111111111",
    slug: "esnaf",
    sessionToken: "a".repeat(64),
  })),
  active: vi.fn(async () => false),
  admin: vi.fn(() => ({ from: vi.fn(), rpc: vi.fn() })),
  edit: vi.fn(async () => { throw new Error("INVALID_EDIT_TOKEN"); }),
}));

vi.mock("next/headers", () => ({ cookies: async () => ({ get: m.cookie }) }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: m.owner,
}));
vi.mock("@/lib/ownerSessionValidity", () => ({
  ownerSessionStillActive: m.active,
}));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: m.admin }));
vi.mock("@/lib/instagramServer", () => ({ verifyStoreEditToken: m.edit }));

import { GET, POST, PATCH, DELETE } from "@/app/api/products/route";
import { POST as batch } from "@/app/api/products/batch/route";
import { POST as invoice } from "@/app/api/fatura-oku/route";

function productRequest(method: "GET" | "POST" | "PATCH" | "DELETE") {
  const id = "11111111-1111-4111-8111-111111111111";
  if (method === "GET")
    return new NextRequest(`http://localhost/api/products?slug=esnaf&productId=${id}`);
  return new NextRequest("http://localhost/api/products", {
    method,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug: "esnaf", name: "Ürün", productId: id }),
  });
}

function invoiceRequest() {
  const form = new FormData();
  form.set("slug", "esnaf");
  form.set("dosya", new File([new Uint8Array([137,80,78,71,13,10,26,10,0,0,0,13])], "fatura.png", {type:"image/png"}));
  return new NextRequest("http://localhost/api/fatura-oku", {method:"POST", body:form});
}

describe("#611: iptal edilmiş fakat çerezi geçerli görünen oturum", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    m.active.mockResolvedValue(false);
  });

  it.each([
    ["GET", GET],
    ["POST", POST],
    ["PATCH", PATCH],
    ["DELETE", DELETE],
  ] as const)("ürün %s işleminde 401 döner ve mağaza/ürün sorgulamaz", async (method, handler) => {
    const response = await handler(productRequest(method));
    expect(response.status).toBe(401);
    expect(m.active).toHaveBeenCalledOnce();
    expect(m.admin.mock.results[0]?.value.from).not.toHaveBeenCalled();
  });

  it("toplu ürün yazma işleminde 401 döner ve hiçbir kart işlemez", async () => {
    const response = await batch(new NextRequest("http://localhost/api/products/batch", {
      method:"POST", headers:{"Content-Type":"application/json"},
      body:JSON.stringify({slug:"esnaf",products:[{name:"Ürün"}]}),
    }));
    expect(response.status).toBe(401);
    expect(m.active).toHaveBeenCalledOnce();
    expect(m.admin.mock.results[0]?.value.from).not.toHaveBeenCalled();
  });

  it("fatura okuma isteğinde 401 döner ve ücretli iş başlatmaz", async () => {
    const response = await invoice(invoiceRequest());
    expect(response.status).toBe(401);
    expect(m.active).toHaveBeenCalledOnce();
    expect(m.admin.mock.results[0]?.value.rpc).not.toHaveBeenCalled();
  });
});
