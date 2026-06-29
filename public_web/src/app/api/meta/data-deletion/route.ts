import { NextRequest, NextResponse } from "next/server";
import crypto from "crypto";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { fromBase64Url } from "@/lib/instagram";
import {
  loadStoreProducts,
  markInstagramConnectionDisconnected,
  persistRetainedProducts,
  removeInstagramStorageFiles,
  revalidateInstagramCleanup,
} from "@/lib/instagramCleanup";

export const runtime = "nodejs";

export async function POST(req: NextRequest) {
  try {
    let signedRequest = "";
    const contentType = req.headers.get("content-type") || "";

    if (contentType.includes("form")) {
      const formData = await req.formData();
      signedRequest = (formData.get("signed_request") as string) || "";
    } else {
      const body = await req.json().catch(() => ({}));
      signedRequest = body.signed_request || "";
    }

    if (!signedRequest) {
      return NextResponse.json({ error: "Missing signed_request" }, { status: 400 });
    }

    const parts = signedRequest.split(".");
    if (parts.length !== 2) {
      return NextResponse.json({ error: "Invalid signed_request format" }, { status: 400 });
    }

    const [encodedSig, payload] = parts;
    const sig = fromBase64Url(encodedSig);
    const data = JSON.parse(fromBase64Url(payload).toString("utf8"));

    if (data.algorithm !== "HMAC-SHA256") {
      return NextResponse.json({ error: "Unsupported algorithm" }, { status: 400 });
    }

    const appSecret = process.env.INSTAGRAM_CLIENT_SECRET || "";
    if (!appSecret) {
      return NextResponse.json({ error: "Server configuration error" }, { status: 500 });
    }

    const expectedSig = crypto
      .createHmac("sha256", appSecret)
      .update(payload)
      .digest();

    if (sig.length !== expectedSig.length || !crypto.timingSafeEqual(sig, expectedSig)) {
      return NextResponse.json({ error: "Signature verification failed" }, { status: 400 });
    }

    const userId = data.user_id || data.user?.id;
    if (!userId) {
      return NextResponse.json({ error: "User ID not found in payload" }, { status: 400 });
    }

    const admin = getSupabaseAdmin();
    const confirmationCode = crypto.randomBytes(16).toString("hex");
    const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || req.nextUrl.origin;

    // Fetch active Instagram connections matching this Meta User ID
    const { data: connections, error: connError } = await admin
      .from("store_instagram_connections")
      .select("id, store_slug")
      .eq("instagram_user_id", userId);

    if (connError) throw connError;

    if (!connections || connections.length === 0) {
      // Log failed request because connection wasn't found
      await admin.from("meta_data_deletion_requests").insert({
        provider: "instagram",
        provider_user_id: userId,
        status: "failed",
        confirmation_code: confirmationCode,
        error_message: "No active connection found for this user id",
        completed_at: new Date().toISOString(),
      });

      return NextResponse.json({
        url: `${siteUrl}/data-deletion/status/${confirmationCode}`,
        confirmation_code: confirmationCode,
      });
    }

    // Process deletion for all matching connections
    for (const connection of connections) {
      // 1. Fetch imported products for this connection (as backup check)
      const { data: imports } = await admin
        .from("store_instagram_imports")
        .select("product_slug")
        .eq("connection_id", connection.id);

      const importedSlugs = imports ? imports.map((imp) => imp.product_slug) : [];

      // Fetch current store products
      const { data: store } = await admin
        .from("stores")
        .select("products")
        .eq("slug", connection.store_slug)
        .maybeSingle();

      const products = await loadStoreProducts(admin, {
        storeSlug: connection.store_slug,
        products: store?.products,
      });

      if (products) {
        // Remove products where source is 'instagram' OR matches the imported slugs
        await persistRetainedProducts(admin, {
          storeSlug: connection.store_slug,
          products,
          importedSlugs,
        });
      }

      // 2. Delete imports
      await admin
        .from("store_instagram_imports")
        .delete()
        .eq("connection_id", connection.id);

      // 3. Delete tokens
      await admin
        .from("store_instagram_tokens")
        .delete()
        .eq("connection_id", connection.id);

      // 4. Delete files from Storage under /{storeSlug}/instagram/
      await removeInstagramStorageFiles(
        admin,
        connection.store_slug,
        "Meta data-deletion",
      );

      // 5. Update connection status
      await markInstagramConnectionDisconnected(admin, connection.id);

      // 6. Trigger revalidation
      revalidateInstagramCleanup(connection.store_slug);

      // 7. Log completion
      await admin.from("meta_data_deletion_requests").insert({
        provider: "instagram",
        provider_user_id: userId,
        store_slug: connection.store_slug,
        status: "completed",
        confirmation_code: confirmationCode,
        completed_at: new Date().toISOString(),
      });
    }

    return NextResponse.json({
      url: `${siteUrl}/data-deletion/status/${confirmationCode}`,
      confirmation_code: confirmationCode,
    });
  } catch (error) {
    console.error("Meta data deletion error:", error);
    return NextResponse.json(
      { error: "Internal server error during deletion process" },
      { status: 500 }
    );
  }
}
