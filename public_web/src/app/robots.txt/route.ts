import { NextResponse } from "next/server";

export function GET() {
  const robots = `User-agent: *
Allow: /
Disallow: /v/*/randevu/*
Disallow: /api/*

Sitemap: https://vitrinx.app/sitemap.xml`;

  return new NextResponse(robots, {
    headers: {
      "Content-Type": "text/plain",
      "Cache-Control": "public, max-age=86400, s-maxage=86400",
    },
  });
}
