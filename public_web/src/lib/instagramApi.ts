import { NextRequest, NextResponse } from "next/server";

function getAllowedOrigins() {
  const configured = [
    process.env.NEXT_PUBLIC_APP_URL,
    ...(process.env.INSTAGRAM_ALLOWED_ORIGINS || "").split(","),
  ]
    .map((origin) => origin?.trim())
    .filter((origin): origin is string => Boolean(origin));

  if (configured.length === 0) {
    configured.push("https://app.vitrinx.app");
  }

  return new Set(configured);
}

function isAllowedOrigin(origin: string) {
  if (getAllowedOrigins().has(origin)) return true;
  if (process.env.NODE_ENV === "production") return false;

  try {
    const url = new URL(origin);
    return (
      (url.hostname === "localhost" || url.hostname === "127.0.0.1") &&
      (url.protocol === "http:" || url.protocol === "https:")
    );
  } catch {
    return false;
  }
}

function applyCors(req: NextRequest, response: NextResponse) {
  const origin = req.headers.get("origin");
  if (origin && isAllowedOrigin(origin)) {
    response.headers.set("Access-Control-Allow-Origin", origin);
    response.headers.set("Vary", "Origin");
  }

  response.headers.set("Access-Control-Allow-Methods", "POST,OPTIONS");
  response.headers.set("Access-Control-Allow-Headers", "Content-Type");
  response.headers.set("Access-Control-Max-Age", "86400");
  response.headers.set("Cache-Control", "no-store");
  return response;
}

export function instagramJson(
  req: NextRequest,
  body: unknown,
  init?: ResponseInit,
) {
  return applyCors(req, NextResponse.json(body, init));
}

export function instagramOptions(req: NextRequest) {
  const origin = req.headers.get("origin");
  if (origin && !isAllowedOrigin(origin)) {
    return NextResponse.json({ message: "ORIGIN_NOT_ALLOWED" }, { status: 403 });
  }

  return applyCors(req, new NextResponse(null, { status: 204 }));
}

export function instagramErrorStatus(message: string) {
  if (message.includes("AUTH")) return 401;
  if (message.includes("NOT_CONNECTED") || message.includes("TOKEN_EXPIRED")) {
    return 409;
  }
  if (
    message.includes("REQUIRED") ||
    message.includes("INVALID") ||
    message.includes("UNSUPPORTED") ||
    message.includes("TOO_LARGE")
  ) {
    return 422;
  }
  return 500;
}
