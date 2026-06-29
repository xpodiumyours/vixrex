import { NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import {
  retainManualProducts,
  safeParseJson,
  type ProductItem,
} from "@/lib/products";
import { normalizeStoreAuth } from "@/lib/instagramRouteUtils";
import {
  instagramErrorStatus,
  instagramJson,
  instagramOptions,
} from "@/lib/instagramApi";
import { revalidateTag } from "next/cache";

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
        let products = Array.isArray(store.products)
          ? safeParseJson<ProductItem>(store.products)
          : null;
        if (!products) {
          const { data: storeData } = await admin
            .from("stores")
            .select("products")
            .eq("slug", store.slug)
            .maybeSingle();
          if (Array.isArray(storeData?.products)) {
            products = safeParseJson<ProductItem>(storeData.products);
          }
        }

        if (products) {
          const nextProducts = retainManualProducts(products);
          const { error: storeUpdateError } = await admin
            .from("stores")
            .update({
              products: nextProducts,
              updated_at: new Date().toISOString(),
            })
            .eq("slug", store.slug);
          if (storeUpdateError) throw storeUpdateError;
        }

        // 3. Delete imports
        await admin.from("store_instagram_imports").delete().eq("connection_id", connection.id);

        // 4. Delete files from Storage under /{storeSlug}/instagram/
        const { data: files, error: listError } = await admin.storage
          .from("shelf-images")
          .list(`${store.slug}/instagram`, { limit: 1000 });

        if (!listError && files && files.length > 0) {
          const pathsToRemove = files.map((file) => `${store.slug}/instagram/${file.name}`);
          const { error: removeError } = await admin.storage
            .from("shelf-images")
            .remove(pathsToRemove);
          if (removeError) {
            console.error("Failed to remove storage files during Mod B disconnect:", removeError);
          }
        }

        // 5. Update connection status
        await admin
          .from("store_instagram_connections")
          .update({
            status: "disconnected",
            state_nonce: null,
            updated_at: new Date().toISOString(),
          })
          .eq("id", connection.id);

        // 6. Trigger revalidation
        revalidateTag(`store-${store.slug}`, "max");
        revalidateTag(`products-${store.slug}`, "max");
        revalidateTag("sitemap", "max");
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
        await admin
          .from("store_instagram_connections")
          .update({
            status: "disconnected",
            state_nonce: null,
            updated_at: new Date().toISOString(),
          })
          .eq("id", connection.id);
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
