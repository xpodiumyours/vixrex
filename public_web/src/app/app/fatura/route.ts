import { NextResponse, type NextRequest } from "next/server";

export const dynamic = "force-dynamic";

export function GET(request: NextRequest) {
  return NextResponse.redirect(new URL("/app/urunler", request.url));
}
