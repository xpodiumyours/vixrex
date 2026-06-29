import { NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import {
  loadStoreProducts,
  markInstagramConnectionDisconnected,
  persistRetainedProducts,
  removeInstagramStorageFiles,
  revalidateInstagramCleanup,
} from "@/lib/instagramCleanup";
import { normalizeStoreAuth } from "@/lib/instagramRouteUtils";
import {
  instagramErrorStatus,
  instagramJson,
  instagramOptions,
} from "@/lib/instagramApi";

export const runtime = "nodejs";

interface DisconnectBody {
  storeSlug?: string;
  editToken?: string;
  mode?: "A" | "B";
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as DisconnectBody;
    const { storeSlug, editToken } = normalizeStoreAuth(body);
    const mode = body.mode || "A";
    const store = await verifyStoreEditToken(storeSlug, editToken);
    const admin = getSupabaseAdmin();

    const { data: connection, error: connectionError } = await admin
      .from("store_instagram_connections")
      .select("id")
      .eq("store_slug", store.slug)
      .maybeSingle();

    if (connectionError) throw connectionError;

    if (connection?.id) {
      if (mode === "B") {
        // Mode B: Disconnect and clean up everything
        // 1. Delete tokens
        await admin.from("store_instagram_tokens").delete().eq("connection_id", connection.id);

        // 2. Filter out products with source = 'instagram'
        const products = await loadStoreProducts(admin, {
          storeSlug: store.slug,
          products: store.products,
          allowStoreFetchFallback: true,
        });

        if (products) {
          await persistRetainedProducts(admin, {
            storeSlug: store.slug,
            products,
          });
        }

        // 3. Delete imports
        await admin.from("store_instagram_imports").delete().eq("connection_id", connection.id);

        // 4. Delete files from Storage under /{storeSlug}/instagram/
        await removeInstagramStorageFiles(admin, store.slug, "Mod B disconnect");

        // 5. Update connection status
        await markInstagramConnectionDisconnected(admin, connection.id);

        // 6. Trigger revalidation
        revalidateInstagramCleanup(store.slug);
      } else {
        // Mode A: Only disconnect, retain products
        // 1. Delete tokens
        await admin.from("store_instagram_tokens").delete().eq("connection_id", connection.id);

        // 2. Mark import records as "retained"
        await admin
          .from("store_instagram_imports")
          .update({
            status: "retained",
            updated_at: new Date().toISOString(),
          })
          .eq("connection_id", connection.id);

        // 3. Update connection status to disconnected
        await markInstagramConnectionDisconnected(admin, connection.id);
      }
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
