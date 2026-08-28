import { NextRequest, NextResponse } from "next/server";
import { verifyRecaptchaToken } from "@/lib/recaptchaServer";

// Eski vercel.app adresi listede KALIYOR: alan adı geçişinden sonra da
// bir süre erişilebilir olacak (yüklü APK'lar ve paylaşılmış eski
// bağlantılar oradan geliyor). Yenisi eklendi, eskisi çıkarılmadı.
const ALLOWED_ORIGINS = new Set([
  "https://vixrex.com",
  "https://www.vixrex.com",
  "https://app.vixrex.app",
  "https://vixrex-public.vercel.app",
]);

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
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return jsonResponse(
      request,
      { success: false, error: "Invalid request body" },
      400,
    );
  }
  if (!body || typeof body !== "object") {
    return jsonResponse(
      request,
      { success: false, error: "Invalid request body" },
      400,
    );
  }

  const { token, action } = body as Record<string, unknown>;
  if (typeof token !== "string" || typeof action !== "string") {
    return jsonResponse(
      request,
      { success: false, error: "Token and action are required" },
      400,
    );
  }

  const result = await verifyRecaptchaToken(token, action);

  if (!result.success) {
    const status = result.error === "reCAPTCHA secret key not configured"
      ? 500
      : result.error === "Internal server error"
        ? 500
        : result.error === "Token and action are required"
          ? 400
          : 403;
    return jsonResponse(request, { ...result }, status);
  }

  return jsonResponse(request, { ...result });
}
