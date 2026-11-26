import { NextResponse } from "next/server";

// IndexNow anahtar doğrulama ucu (Aktif Görev #6). INDEXNOW_KEY ortam
// değişkeni tanımlı değilse sistem sessizce pasif kalır (404).
export async function GET() {
  const key = (process.env.INDEXNOW_KEY || "").trim();
  if (!key) {
    return new NextResponse(null, { status: 404 });
  }
  return new NextResponse(key, {
    status: 200,
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}
