import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { smartEngineStorefrontServerEnabled } from "@/lib/smartEngineFlagsServer";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const slug = request.nextUrl.searchParams.get("slug")?.trim() ?? "";
  if (!slug) {
    return NextResponse.json({ enabled: false }, { status: 400 });
  }

  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);
  if (!ownerSession) {
    return NextResponse.json({ enabled: false }, { status: 401 });
  }

  const enabled = await smartEngineStorefrontServerEnabled();
  return NextResponse.json(
    { enabled },
    { headers: { "Cache-Control": "no-store" } }
  );
}
