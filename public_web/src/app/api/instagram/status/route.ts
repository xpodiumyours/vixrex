import { NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import {
  getConnectedInstagramAccess,
  verifyStoreEditToken,
} from "@/lib/instagramServer";
import {
  instagramErrorStatus,
  instagramJson,
  instagramOptions,
} from "@/lib/instagramApi";

export const runtime = "nodejs";

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as {
      storeSlug?: string;
      editToken?: string;
    };
    const storeSlug = body.storeSlug?.trim() || "";
    const editToken = body.editToken?.trim() || "";
    const store = await verifyStoreEditToken(storeSlug, editToken);
    const admin = getSupabaseAdmin();
    const { data, error } = await admin
      .from("store_instagram_connections")
      .select("status,username,account_type,expires_at")
      .eq("store_slug", store.slug)
      .maybeSingle();

    if (error) throw error;
    if (!data || data.status !== "connected") {
      return instagramJson(req, {
        connected: false,
        status: data?.status || "not_connected",
      });
    }

    const access = await getConnectedInstagramAccess(store.slug, editToken);
    return instagramJson(req, {
      connected: true,
      status: "connected",
      username: data.username || null,
      accountType: data.account_type || null,
      expiresAt: access.expiresAt || data.expires_at || null,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "INSTAGRAM_STATUS_FAILED";
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
