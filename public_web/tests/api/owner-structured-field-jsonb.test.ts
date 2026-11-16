import { beforeEach, describe, expect, it, vi } from "vitest";
import { signOwnerSession } from "@/lib/ownerSession";

const mocks = vi.hoisted(() => ({
  cookie: vi.fn(),
  rpc: vi.fn(),
  admin: vi.fn(),
}));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({ get: mocks.cookie })),
}));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.admin }));

import { POST } from "@/app/api/owner-structured-field/route";

const storeId = "22222222-2222-4222-8222-222222222222";
const slug = "olcum-vitrini";
const sessionToken = "cd".repeat(32);

function istek(govde: Record<string, unknown>) {
  return new Request("http://localhost/api/owner-structured-field", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(govde),
  });
}

beforeEach(() => {
  vi.clearAllMocks();
  vi.stubEnv("OWNER_SESSION_SECRET", "owner-structured-field-test-secret-20261116");
  mocks.cookie.mockReturnValue({ value: signOwnerSession(storeId, slug, sessionToken) });
  mocks.admin.mockReturnValue({ rpc: mocks.rpc });
  mocks.rpc.mockResolvedValue({ data: { draft_version: 3 }, error: null });
  vi.spyOn(console, "error").mockImplementation(() => {});
});

describe("/api/owner-structured-field JSONB yazımı", () => {
  it("galeri dizisini metne çevirmeden RPC'ye geçirir", async () => {
    const galeri = [{ id: "g1", imageUrl: "https://ornek.com/a.jpg", title: "Atölye" }];
    const yanit = await POST(
      istek({ slug, kolon: "gallery_items", deger: galeri }) as never
    );
    expect(yanit.status).toBe(200);
    expect(mocks.rpc).toHaveBeenCalledTimes(1);
    const parametre = mocks.rpc.mock.calls[0][1] as Record<string, unknown>;
    expect(parametre.p_key).toBe("gallery_items");
    expect(Array.isArray(parametre.p_value)).toBe(true);
    expect(parametre.p_value).toEqual(galeri);
  });

  it("SSS dizisini metne çevirmeden RPC'ye geçirir", async () => {
    const sss = [{ id: "s1", question: "Soru?", answer: "Cevap." }];
    const yanit = await POST(
      istek({ slug, kolon: "faq_items", deger: sss }) as never
    );
    expect(yanit.status).toBe(200);
    const parametre = mocks.rpc.mock.calls[0][1] as Record<string, unknown>;
    expect(Array.isArray(parametre.p_value)).toBe(true);
    expect(parametre.p_value).toEqual(sss);
  });

  it("null değeri aynen geçirir", async () => {
    const yanit = await POST(
      istek({ slug, kolon: "gallery_items", deger: null }) as never
    );
    expect(yanit.status).toBe(200);
    const parametre = mocks.rpc.mock.calls[0][1] as Record<string, unknown>;
    expect(parametre.p_value).toBeNull();
  });

  it("izin dışı kolonu reddeder", async () => {
    const yanit = await POST(
      istek({ slug, kolon: "name", deger: ["x"] }) as never
    );
    expect(yanit.status).toBe(403);
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
});
