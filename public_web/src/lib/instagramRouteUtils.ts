import type { NextRequest } from "next/server";

const defaultInstagramGraphBaseUrl = "https://graph.instagram.com";

export interface StoreAuthBody {
  storeSlug?: string;
  editToken?: string;
}

export function trimToEmpty(value: string | null | undefined) {
  return value?.trim() || "";
}

export function normalizeStoreAuth(body: StoreAuthBody) {
  return {
    storeSlug: trimToEmpty(body.storeSlug),
    editToken: trimToEmpty(body.editToken),
  };
}

export function getPublicSiteOrigin(req: Pick<NextRequest, "nextUrl">) {
  return process.env.NEXT_PUBLIC_SITE_URL || req.nextUrl.origin;
}

export function buildInstagramGraphUrl(pathname: string) {
  const normalizedBase = (
    process.env.INSTAGRAM_GRAPH_BASE_URL || defaultInstagramGraphBaseUrl
  ).replace(/\/+$/, "");

  return new URL(pathname.replace(/^\/+/, ""), `${normalizedBase}/`);
}
