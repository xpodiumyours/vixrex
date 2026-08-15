import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";

const mockRpc = vi.fn();
vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: () => ({ rpc: mockRpc }),
}));

const mockVerifyRecaptchaToken = vi.fn();
vi.mock("@/lib/recaptchaServer", () => ({
  verifyRecaptchaToken: (...args: unknown[]) => mockVerifyRecaptchaToken(...args),
}));

import { GET, POST } from "@/app/api/rent-demo/route";

function postRequest(fields: Record<string, string>) {
  const form = new FormData();
  for (const [key, value] of Object.entries(fields)) form.set(key, value);
  return new NextRequest("http://localhost/api/rent-demo", {
    method: "POST",
    body: form,
  });
}

describe("GET /api/rent-demo — GÜVENLİK: artık veritabanına dokunmaz", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("slug'lı isteği /rent-demo?slug=x'e 303 ile yönlendirir, RPC çağırmaz", async () => {
    const request = new NextRequest(
      "http://localhost/api/rent-demo?slug=kiralik-butik"
    );
    const response = await GET(request);

    expect(response.status).toBe(303);
    expect(response.headers.get("location")).toBe(
      "http://localhost/rent-demo?slug=kiralik-butik"
    );
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("slug'sız isteği de /rent-demo'ya yönlendirir, kırılmaz", async () => {
    const request = new NextRequest("http://localhost/api/rent-demo");
    const response = await GET(request);

    expect(response.status).toBe(303);
    expect(response.headers.get("location")).toBe("http://localhost/rent-demo");
    expect(mockRpc).not.toHaveBeenCalled();
  });
});

describe("POST /api/rent-demo — reCAPTCHA olmadan RPC çağrılmaz", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("recaptchaToken eksikse hata sayfası döner, RPC çağrılmaz", async () => {
    const response = await POST(postRequest({ slug: "kiralik-butik" }));

    expect(response.status).toBe(400);
    expect(mockVerifyRecaptchaToken).not.toHaveBeenCalled();
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("slug eksikse hata sayfası döner, RPC çağrılmaz", async () => {
    const response = await POST(postRequest({ recaptchaToken: "tok" }));

    expect(response.status).toBe(400);
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("reCAPTCHA reddederse hata sayfası döner, RPC çağrılmaz", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({
      success: false,
      error: "Score too low",
    });

    const response = await POST(
      postRequest({ slug: "kiralik-butik", recaptchaToken: "tok" })
    );

    expect(response.status).toBe(400);
    expect(mockVerifyRecaptchaToken).toHaveBeenCalledWith(
      "tok",
      "rent_demo",
      { minScore: 0.5 }
    );
    expect(mockRpc).not.toHaveBeenCalled();
  });
});

describe("POST /api/rent-demo — başarılı akış TEK RPC çağırır", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
  });

  it("start_demo_trial'ı HMAC'lenmiş client key ile çağırır, owner-session'a 303 döner", async () => {
    mockRpc.mockResolvedValue({
      data: { slug: "kiralik-butik-ab12cd34", code: "ocode123" },
      error: null,
    });

    const response = await POST(
      postRequest({ slug: "kiralik-butik", recaptchaToken: "tok" })
    );

    expect(mockRpc).toHaveBeenCalledTimes(1);
    expect(mockRpc).toHaveBeenCalledWith("start_demo_trial", {
      p_source_slug: "kiralik-butik",
      p_client_key: expect.any(String),
    });

    expect(response.status).toBe(303);
    const location = response.headers.get("location")!;
    expect(location).toContain("/api/owner-session?");
    expect(location).toContain("slug=kiralik-butik-ab12cd34");
    expect(location).toContain("ocode=ocode123");
  });

  it("RATE_LIMITED hatasında anlamlı mesaj döner, redirect ETMEZ", async () => {
    mockRpc.mockResolvedValue({
      data: null,
      error: { message: "RATE_LIMITED" },
    });

    const response = await POST(
      postRequest({ slug: "kiralik-butik", recaptchaToken: "tok" })
    );

    expect(response.status).toBe(400);
    expect(response.headers.get("location")).toBeNull();
    const html = await response.text();
    expect(html).toContain("Çok fazla deneme");
  });

  it("SOURCE_NOT_FOUND hatasında anlamlı mesaj döner", async () => {
    mockRpc.mockResolvedValue({
      data: null,
      error: { message: "SOURCE_NOT_FOUND" },
    });

    const response = await POST(
      postRequest({ slug: "olmayan-demo", recaptchaToken: "tok" })
    );

    const html = await response.text();
    expect(html).toContain("kiralık örnek olarak mevcut değil");
  });
});
