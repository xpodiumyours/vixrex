import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";

const mockRevalidateTag = vi.fn();
const mockRevalidatePath = vi.fn();
const mockFetch = vi.fn();

vi.mock("next/cache", () => ({
  revalidateTag: (...args: unknown[]) => mockRevalidateTag(...args),
  revalidatePath: (...args: unknown[]) => mockRevalidatePath(...args),
}));

vi.stubGlobal("fetch", mockFetch);

import { POST } from "@/app/api/revalidate/route";

/**
 * `/api/revalidate` kimlik doğrulama kontrolu (2026-11-26 güncellemesi).
 *
 * Güncel davranış:
 *   1) Mobil uygulama → kullanıcının doğrulanmış Supabase oturum token'i
 *      (`Authorization: Bearer <access_token>`) ile yetkilidir; token Supabase
 *      Auth (`/auth/v1/user`) üzerinden doğrulanır (fail-closed).
 *   2) Sunucu içi tetikleyiciler (Supabase webhook / operasyon) → `x-revalidate-secret`
 *      başlığı `REVALIDATION_SECRET` ortam değişkeniyle eşleşirse geçer.
 *
 * Ortamda `REVALIDATION_SECRET` yoksa veya başlık eşleşmiyorsa 401 döner (fail-closed).
 * Mobil derlemeye (APK/AAB, Flutter dart-define) hiçbir zaman sır değildir.
 */

describe("POST /api/revalidate — güvenlik", () => {
  const ANAHTAR = "test-internal-trigger";

  function istek(govde: unknown, headers: Record<string, string> = {}) {
    return new NextRequest("http://localhost/api/revalidate", {
      method: "POST",
      headers,
      body: JSON.stringify(govde),
    });
  }

  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubGlobal("fetch", mockFetch);
    process.env.SUPABASE_URL = "https://test.supabase.co";
    process.env.SUPABASE_PUBLISHABLE_KEY = "test-anon-key";
    delete process.env.REVALIDATION_SECRET;
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    delete process.env.REVALIDATION_SECRET;
  });

  it("geçerli Supabase oturum token'ı ile yetkilendirme geçerli → tag düşürülür", async () => {
    mockFetch.mockResolvedValue({ ok: true, status: 200 });
    const res = await POST(
      istek({ tags: ["store-x", "products-x"] }, { authorization: "Bearer gecerli-token" })
    );

    expect(res.status).toBe(200);
    expect(mockFetch).toHaveBeenCalledWith(
      "https://test.supabase.co/auth/v1/user",
      expect.objectContaining({
        headers: expect.objectContaining({ Authorization: "Bearer gecerli-token" }),
      })
    );
    expect(mockRevalidateTag).toHaveBeenCalledTimes(2);
    expect(mockRevalidateTag).toHaveBeenCalledWith("store-x", { expire: 0 });
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });

  it("geçersiz Supabase oturum token'ı → 401 döner, önbellek düşürülmez", async () => {
    mockFetch.mockResolvedValue({ ok: false, status: 401 });
    const res = await POST(
      istek({ tags: ["store-x"] }, { authorization: "Bearer yanlis-token" })
    );

    expect(res.status).toBe(401);
    expect(mockRevalidateTag).not.toHaveBeenCalled();
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });

  it("bearer yoksa ve sunucu içi secret eşleşmiyorsa → fail-closed 401 döner", async () => {
    process.env.REVALIDATION_SECRET = ANAHTAR;
    const res = await POST(istek({ tags: ["store-x"] }, { "x-revalidate-secret": "yanlis-deger" }));

    expect(res.status).toBe(401);
    expect(mockRevalidateTag).not.toHaveBeenCalled();
  });

  it("sunucu içi x-revalidate-secret ile yetkilendirme geçerli → revalidation çalışır", async () => {
    process.env.REVALIDATION_SECRET = ANAHTAR;
    const res = await POST(
      istek({ tags: ["store-x"] }, { "x-revalidate-secret": ANAHTAR })
    );

    expect(res.status).toBe(200);
    expect(mockRevalidateTag).toHaveBeenCalledWith("store-x", { expire: 0 });
  });

  it("ne bearer ne de geçerli internal trigger yoksa → fail-closed 401 döner", async () => {
    const res = await POST(istek({ tags: ["store-x"] }, {}));

    expect(res.status).toBe(401);
    expect(mockRevalidateTag).not.toHaveBeenCalled();
  });

  it("ne tag ne path varsa 400 döner", async () => {
    mockFetch.mockResolvedValue({ ok: true, status: 200 });
    const res = await POST(
      istek({}, { authorization: "Bearer gecerli-token" })
    );

    expect(res.status).toBe(400);
    expect(mockRevalidateTag).not.toHaveBeenCalled();
  });

  it("path istekleri revalidatePath ile karşılanır", async () => {
    mockFetch.mockResolvedValue({ ok: true, status: 200 });
    const res = await POST(
      istek({ paths: ["/v/x", "/v/x/urun/y"] }, { authorization: "Bearer gecerli-token" })
    );

    expect(res.status).toBe(200);
    expect(mockRevalidatePath).toHaveBeenCalledTimes(2);
    expect(mockRevalidatePath).toHaveBeenCalledWith("/v/x", "page");
  });
});

describe("REVALIDATION — derleme kablosu", () => {
  const oku = (goreli: string) =>
    readFileSync(resolve(__dirname, "..", "..", goreli), "utf8");

  it("APK/AAB derlemesinde REVALIDATION_SECRET / dart-define bulunmaz", () => {
    const kaynak = oku(".github/workflows/android-apk.yml");
    expect(kaynak).not.toContain("REVALIDATION_SECRET");
    expect(kaynak).not.toContain("--dart-define=REVALIDATION_SECRET");
  });

  it("Flutter web derlemesi (vercel-build.sh) REVALIDATION_SECRET tanımı içermez", () => {
    const kaynak = oku("vercel-build.sh");
    expect(kaynak).not.toContain("REVALIDATION_SECRET");
  });

  it("Flutter tarafı sunucu sırrı yerine kullanıcı oturumu tokeni kullanır", () => {
    const kaynak = oku("lib/services/seo_service.dart");
    expect(kaynak).not.toContain("String.fromEnvironment('REVALIDATION_SECRET')");
    expect(kaynak).toContain("'Authorization': 'Bearer $token'");
  });
});
