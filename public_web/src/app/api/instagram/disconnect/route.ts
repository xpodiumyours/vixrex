import { NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import {
  instagramErrorStatus,
  instagramJson,
  instagramOptions,
} from "@/lib/instagramApi";

export const runtime = "nodejs";

interface DisconnectBody {
  storeSlug?: string;
  editToken?: string;
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as DisconnectBody;
    const storeSlug = body.storeSlug?.trim() || "";
    const editToken = body.editToken?.trim() || "";
    const store = await verifyStoreEditToken(storeSlug, editToken);
    const admin = getSupabaseAdmin();

    const { data: connection, error: connectionError } = await admin
      .from("store_instagram_connections")
      .select("id")
      .eq("store_slug", store.slug)
      .maybeSingle();

    if (connectionError) throw connectionError;

    if (connection?.id) {
      await admin.from("store_instagram_tokens").delete().eq("connection_id", connection.id);
      await admin
        .from("store_instagram_connections")
        .update({
          status: "disconnected",
          state_nonce: null,
          updated_at: new Date().toISOString(),
        })
        .eq("id", connection.id);
    }

    return instagramJson(req, { disconnected: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : "INSTAGRAM_DISCONNECT_FAILED";
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
