import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";
import { OPTIONS, POST } from "@/app/api/verify-recaptcha/route";

function createRequest(token: string, action: string, origin?: string) {
  return new NextRequest("http://localhost/api/verify-recaptcha", {
    method: "POST",
    body: JSON.stringify({ token, action }),
    headers: origin ? { origin } : undefined,
  });
}

describe("POST /api/verify-recaptcha", () => {
  beforeEach(() => {
    process.env.RECAPTCHA_SECRET_KEY = "test-only-secret";
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    delete process.env.RECAPTCHA_SECRET_KEY;
  });

  it("accepts a matching action at the minimum score", async () => {
    const googleVerify = vi.fn().mockResolvedValue(
      new Response(
        JSON.stringify({
          success: true,
          score: 0.3,
          action: "booking_create",
        }),
        { status: 200 },
      ),
    );
    vi.stubGlobal("fetch", googleVerify);

    const response = await POST(
      createRequest("test-token", "booking_create"),
    );

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toMatchObject({
      success: true,
      score: 0.3,
      action: "booking_create",
    });
    expect(googleVerify).toHaveBeenCalledWith(
      "https://www.google.com/recaptcha/api/siteverify",
      expect.objectContaining({
        method: "POST",
        body: expect.any(URLSearchParams),
      }),
    );
  });

  it("rejects a token generated for another action", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(
        new Response(
          JSON.stringify({
            success: true,
            score: 0.9,
            action: "booking_cancel",
          }),
          { status: 200 },
        ),
      ),
    );

    const response = await POST(
      createRequest("test-token", "booking_create"),
    );

    expect(response.status).toBe(403);
    await expect(response.json()).resolves.toMatchObject({
      success: false,
      error: "Action mismatch",
    });
  });

  it("rejects missing token or action without contacting Google", async () => {
    const googleVerify = vi.fn();
    vi.stubGlobal("fetch", googleVerify);

    const response = await POST(createRequest("", ""));

    expect(response.status).toBe(400);
    expect(googleVerify).not.toHaveBeenCalled();
  });

  it("allows the Flutter Web editor origin", async () => {
    const response = OPTIONS(
      new NextRequest("http://localhost/api/verify-recaptcha", {
        method: "OPTIONS",
        headers: { origin: "https://app.vixrex.app" },
      }),
    );

    expect(response.status).toBe(204);
    expect(response.headers.get("Access-Control-Allow-Origin")).toBe(
      "https://app.vixrex.app",
    );
  });
});
