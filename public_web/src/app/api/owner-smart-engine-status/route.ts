import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import {
  smartEngineBlogServerEnabled,
  smartEngineStorefrontServerEnabled,
} from "@/lib/smartEngineFlagsServer";

export const dynamic = "force-dynamic";

type SmartEngineDomain = "storefront" | "blog";

export async function GET(request: NextRequest) {
  const slug = request.nextUrl.searchParams.get("slug")?.trim() ?? "";
  const domainRaw = request.nextUrl.searchParams.get("domain")?.trim() ?? "storefront";
  const domain: SmartEngineDomain | null =
    domainRaw === "storefront" || domainRaw === "blog" ? domainRaw : null;

  if (!slug || !domain) {
    return NextResponse.json({ enabled: false }, { status: 400 });
  }

  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);
  if (!ownerSession) {
    return NextResponse.json({ enabled: false }, { status: 401 });
  }

  const enabled =
    domain === "blog"
      ? await smartEngineBlogServerEnabled()
      : await smartEngineStorefrontServerEnabled();

  return NextResponse.json(
    { enabled, domain },
    { headers: { "Cache-Control": "no-store" } }
  );
}
