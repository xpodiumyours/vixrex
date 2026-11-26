import { NextResponse } from "next/server";
import { readValidIndexNowKey } from "@/lib/indexnow";

export async function GET() {
  const key = readValidIndexNowKey();
  if (!key) {
    return new NextResponse(null, { status: 404 });
  }
  return new NextResponse(key, {
    status: 200,
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}
