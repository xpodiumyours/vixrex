import { NextRequest } from "next/server";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  buildInstagramProductDescription,
  buildInstagramProductName,
  getProductUrlSlug,
  safeParseJson,
  slugifyTR,
  type ProductItem,
} from "@/lib/products";
import { sanitizeInstagramMedia } from "@/lib/instagram";
import { getConnectedInstagramAccess, revalidateProductTargets } from "@/lib/instagramServer";
import {
  instagramErrorStatus,
  instagramJson,
  instagramOptions,
} from "@/lib/instagramApi";

export const runtime = "nodejs";

interface ImportBody {
  storeSlug?: string;
  editToken?: string;
  mediaId?: string;
  price?: string;
  category?: string;
  stockStatus?: string;
}

interface InstagramMediaResponse extends Record<string, unknown> {
  error?: {
    message?: string;
  };
}

const maxInstagramImageBytes = 6 * 1024 * 1024;
const instagramImageExtensions = new Map([
  ["image/jpeg", "jpg"],
  ["image/png", "png"],
  ["image/webp", "webp"],
]);

async function readImageWithLimit(response: Response) {
  const contentLength = Number(response.headers.get("content-length") || "0");
  if (contentLength > maxInstagramImageBytes) {
    throw new Error("INSTAGRAM_MEDIA_TOO_LARGE");
  }

  if (!response.body) {
    const buffer = Buffer.from(await response.arrayBuffer());
    if (buffer.length > maxInstagramImageBytes) {
      throw new Error("INSTAGRAM_MEDIA_TOO_LARGE");
    }
    return buffer;
  }

  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let totalBytes = 0;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    totalBytes += value.byteLength;
    if (totalBytes > maxInstagramImageBytes) {
      await reader.cancel();
      throw new Error("INSTAGRAM_MEDIA_TOO_LARGE");
    }
    chunks.push(value);
  }

  return Buffer.concat(chunks, totalBytes);
}

function makeUniqueSlug(baseSlug: string, products: ProductItem[], mediaId: string) {
  const base = baseSlug || `instagram-${slugifyTR(mediaId) || "urun"}`;
  const usedSlugs = new Set(
    products
      .filter((product) => product.sourceMediaId !== mediaId)
      .map((product, index) => getProductUrlSlug(product, index))
  );

  if (!usedSlugs.has(base)) return base;

  for (let i = 2; i < 100; i += 1) {
    const candidate = `${base}-${i}`;
    if (!usedSlugs.has(candidate)) return candidate;
  }

  return `${base}-${Date.now()}`;
}

async function uploadInstagramMedia(args: {
  mediaUrl: string;
  storeSlug: string;
  mediaId: string;
  admin: SupabaseClient;
}) {
  if (!args.mediaUrl) return "";

  const response = await fetch(args.mediaUrl);
  if (!response.ok) throw new Error("INSTAGRAM_MEDIA_DOWNLOAD_FAILED");

  const contentType = (response.headers.get("content-type") || "")
    .split(";", 1)[0]
    .trim()
    .toLowerCase();
  const extension = instagramImageExtensions.get(contentType);
  if (!extension) throw new Error("INSTAGRAM_MEDIA_TYPE_UNSUPPORTED");

  const objectPath = `${args.storeSlug}/instagram/${args.mediaId}-${Date.now()}.${extension}`;
  const buffer = await readImageWithLimit(response);

  const { error } = await args.admin.storage
    .from("shelf-images")
    .upload(objectPath, buffer, {
      contentType,
      upsert: false,
    });

  if (error) throw error;

  const { data } = args.admin.storage.from("shelf-images").getPublicUrl(objectPath);
  return data.publicUrl;
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as ImportBody;
    const storeSlug = body.storeSlug?.trim() || "";
    const editToken = body.editToken?.trim() || "";
    const mediaId = body.mediaId?.trim() || "";

    if (!mediaId) {
      return instagramJson(
        req,
        { message: "INSTAGRAM_MEDIA_ID_REQUIRED" },
        { status: 400 },
      );
    }

    const { admin, store, connection, accessToken } = await getConnectedInstagramAccess(storeSlug, editToken);
    const mediaUrl = new URL(`${process.env.INSTAGRAM_GRAPH_BASE_URL || "https://graph.instagram.com"}/${mediaId}`);
    mediaUrl.searchParams.set("fields", "id,caption,media_type,media_url,permalink,timestamp");
    mediaUrl.searchParams.set("access_token", accessToken);

    const mediaResponse = await fetch(mediaUrl);
    const mediaJson = (await mediaResponse.json()) as InstagramMediaResponse;
    if (!mediaResponse.ok) {
      throw new Error(mediaJson.error?.message || "INSTAGRAM_MEDIA_FETCH_FAILED");
    }

    const media = sanitizeInstagramMedia(mediaJson);
    if (!media.id) throw new Error("INSTAGRAM_MEDIA_INVALID");
    if (media.media_type !== "IMAGE" || !media.media_url) {
      throw new Error("INSTAGRAM_MEDIA_TYPE_UNSUPPORTED");
    }

    const products = safeParseJson<ProductItem>(store.products);
    const existingIndex = products.findIndex(
      (product) => product.source === "instagram" && product.sourceMediaId === media.id
    );
    const existingProduct = existingIndex >= 0 ? products[existingIndex] : null;
    const productName =
      existingProduct?.name ||
      buildInstagramProductName(media.caption || "", "Instagram ürünü");
    const baseSlug = existingProduct?.slug || slugifyTR(productName);
    const productSlug = makeUniqueSlug(baseSlug, products, media.id);
    const imagePath =
      existingProduct?.imagePath ||
      (await uploadInstagramMedia({
        mediaUrl: media.media_url || "",
        storeSlug: store.slug,
        mediaId: media.id,
        admin,
      }));

    const product: ProductItem = {
      id: existingProduct?.id || `ig-${media.id}`,
      slug: productSlug,
      name: productName,
      price: body.price?.trim() || existingProduct?.price || "",
      description:
        existingProduct?.description ||
        buildInstagramProductDescription({
          caption: media.caption || "",
          storeName: store.name,
          productName,
        }),
      imagePath,
      category: body.category?.trim() || existingProduct?.category || "Instagram Koleksiyonu",
      stockStatus: body.stockStatus?.trim() || existingProduct?.stockStatus || "Mevcut",
      source: "instagram",
      sourceMediaId: media.id,
      sourcePermalink: media.permalink || existingProduct?.sourcePermalink || "",
      importedAt: existingProduct?.importedAt || new Date().toISOString(),
    };

    const nextProducts = [...products];
    const isNewProduct = existingIndex < 0;
    if (isNewProduct) {
      nextProducts.unshift(product);
    } else {
      nextProducts[existingIndex] = product;
    }

    const { error: updateError } = await admin
      .from("stores")
      .update({
        products: nextProducts,
        updated_at: new Date().toISOString(),
      })
      .eq("slug", store.slug);

    if (updateError) throw updateError;

    const { error: importLogError } = await admin
      .from("store_instagram_imports")
      .upsert(
      {
        store_slug: store.slug,
        connection_id: connection.id,
        source_media_id: media.id,
        source_permalink: media.permalink || null,
        product_slug: productSlug,
        status: isNewProduct ? "imported" : "updated",
        imported_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      { onConflict: "store_slug,source_media_id" },
    );
    if (importLogError) throw importLogError;

    await admin
      .from("store_instagram_connections")
      .update({ last_sync_at: new Date().toISOString() })
      .eq("id", connection.id);

    revalidateProductTargets(store.slug, productSlug, isNewProduct);

    return instagramJson(req, {
      product,
      revalidated: {
        tags: [
          `store-${store.slug}`,
          `products-${store.slug}`,
          `product-${store.slug}-${productSlug}`,
          ...(isNewProduct ? ["sitemap"] : []),
        ],
        paths: [`/v/${store.slug}/urun/${productSlug}`],
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "INSTAGRAM_IMPORT_FAILED";
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
