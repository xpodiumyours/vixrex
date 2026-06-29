import { NextRequest } from "next/server";
import { sanitizeInstagramMedia } from "@/lib/instagram";
import { buildInstagramGraphUrl, normalizeStoreAuth } from "@/lib/instagramRouteUtils";
import { getConnectedInstagramAccess } from "@/lib/instagramServer";
import {
  instagramErrorStatus,
  instagramJson,
  instagramOptions,
} from "@/lib/instagramApi";

export const runtime = "nodejs";

interface InstagramMediaListResponse {
  data?: Record<string, unknown>[];
  error?: {
    message?: string;
  };
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as {
      storeSlug?: string;
      editToken?: string;
    };
    const { storeSlug, editToken } = normalizeStoreAuth(body);
    const { accessToken } = await getConnectedInstagramAccess(storeSlug, editToken);
    const mediaUrl = buildInstagramGraphUrl("/me/media");
    mediaUrl.searchParams.set(
      "fields",
      "id,caption,media_type,media_url,thumbnail_url,permalink,timestamp",
    );
    mediaUrl.searchParams.set("access_token", accessToken);

    const response = await fetch(mediaUrl, { cache: "no-store" });
    const json = (await response.json()) as InstagramMediaListResponse;

    if (!response.ok) {
      throw new Error(json.error?.message || "INSTAGRAM_MEDIA_FETCH_FAILED");
    }

    return instagramJson(req, {
      media: (json.data || [])
        .map(sanitizeInstagramMedia)
        .filter((item) => item.id && item.media_type === "IMAGE"),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "INSTAGRAM_MEDIA_FAILED";
    return instagramJson(
      req,
      { message },
      { status: instagramErrorStatus(message) },
    );
  }
}

export function OPTIONS(req: NextRequest) {
  return instagramOptions(req);
}
