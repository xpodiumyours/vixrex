import { NextRequest, NextResponse } from "next/server";

const VERIFY_URL = "https://www.google.com/recaptcha/api/siteverify";
const MIN_SCORE = 0.3;
const ALLOWED_ORIGINS = new Set([
  "https://app.vixrex.app",
  "https://vixrex-public.vercel.app",
]);

interface GoogleRecaptchaResponse {
  success?: boolean;
  score?: number;
  action?: string;
  "error-codes"?: string[];
}

function getCorsHeaders(request: NextRequest): Record<string, string> {
  const origin = request.headers.get("origin");
  if (!origin) return {};

  let isLocalhost = false;
  try {
    const url = new URL(origin);
    isLocalhost = url.hostname === "localhost" || url.hostname === "127.0.0.1";
  } catch {
    return {};
  }

  if (
    origin !== request.nextUrl.origin &&
    !ALLOWED_ORIGINS.has(origin) &&
    !isLocalhost
  ) {
    return {};
  }

  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    Vary: "Origin",
  };
}

function jsonResponse(
  request: NextRequest,
  body: Record<string, unknown>,
  status = 200,
) {
  return NextResponse.json(body, {
    status,
    headers: getCorsHeaders(request),
  });
}

export function OPTIONS(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(request);
  if (origin && !headers["Access-Control-Allow-Origin"]) {
    return new NextResponse(null, { status: 403 });
  }
  return new NextResponse(null, { status: 204, headers });
}

export async function POST(request: NextRequest) {
  const secretKey = process.env.RECAPTCHA_SECRET_KEY?.trim();
  if (!secretKey) {
    return jsonResponse(
      request,
      { success: false, error: "reCAPTCHA secret key not configured" },
      500,
    );
  }

  try {
    const body: unknown = await request.json();
    if (!body || typeof body !== "object") {
      return jsonResponse(
        request,
        { success: false, error: "Invalid request body" },
        400,
      );
    }

    const { token, action } = body as Record<string, unknown>;

    if (
      typeof token !== "string" ||
      token.trim().length === 0 ||
      typeof action !== "string" ||
      action.trim().length === 0
    ) {
      return jsonResponse(
        request,
        { success: false, error: "Token and action are required" },
        400,
      );
    }

    const params = new URLSearchParams({
      secret: secretKey,
      response: token.trim(),
    });

    const response = await fetch(VERIFY_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params,
    });

    if (!response.ok) {
      throw new Error(`Google verification request failed: ${response.status}`);
    }

    const data = (await response.json()) as GoogleRecaptchaResponse;

    if (!data.success) {
      return jsonResponse(
        request,
        {
          success: false,
          error: "reCAPTCHA verification failed",
          errorCodes: data["error-codes"],
        },
        403,
      );
    }

    if (data.action !== action.trim()) {
      return jsonResponse(
        request,
        { success: false, error: "Action mismatch" },
        403,
      );
    }

    if (typeof data.score !== "number" || data.score < MIN_SCORE) {
      return jsonResponse(
        request,
        {
          success: false,
          error: "Score too low",
          score: data.score,
        },
        403,
      );
    }

    return jsonResponse(request, {
      success: true,
      score: data.score,
      action: data.action,
    });
  } catch (error) {
    console.error("[reCAPTCHA] Verify error:", error);
    return jsonResponse(
      request,
      { success: false, error: "Internal server error" },
      500,
    );
  }
}
