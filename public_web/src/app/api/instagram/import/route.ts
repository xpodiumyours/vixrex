import { NextRequest } from "next/server";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  buildInstagramProductDescription,
  buildInstagramProductName,
  type ProductItem,
} from "@/lib/products";
import { sanitizeInstagramMedia } from "@/lib/instagram";
import { getConnectedInstagramAccess, revalidateProductTargets } from "@/lib/instagramServer";
import {
  instagramErrorStatus,
  instagramJson,
  instagramOptions,
} from "@/lib/instagramApi";
import {
  createCoreProduct,
  findCoreProductByExternalId,
  updateCoreProduct,
  upsertCoreCategory,
} from "@/lib/productCoreServer";

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

  // The media id is stable. A deterministic object key makes retries and
  // concurrent imports overwrite the same object instead of leaking files.
  const objectPath = `${args.storeSlug}/instagram/${args.mediaId}.${extension}`;
  const buffer = await readImageWithLimit(response);

  const { error } = await args.admin.storage
    .from("shelf-images")
    .upload(objectPath, buffer, {
      contentType,
      upsert: true,
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
    const storeId = store.id?.trim() || "";
    if (!storeId) throw new Error("PRODUCT_CORE_STORE_ID_MISSING");

    const existingProduct = await findCoreProductByExternalId({
      admin,
      storeId,
      sourceType: "instagram",
      externalProductId: media.id,
    });
    const productName =
      existingProduct?.name ||
      buildInstagramProductName(media.caption || "", "Instagram ürünü");
    const imagePath =
      existingProduct?.image_urls?.[0] ||
      (await uploadInstagramMedia({
        mediaUrl: media.media_url || "",
        storeSlug: store.slug,
        mediaId: media.id,
        admin,
      }));

    const requestedCategory = body.category?.trim() || "";
    const existingCategoryName =
      existingProduct?.product_categories?.name?.trim() || "";
    const categoryName =
      requestedCategory || existingCategoryName || "Instagram Koleksiyonu";
    const categoryId =
      !requestedCategory && existingProduct?.category_id
        ? existingProduct.category_id
        : await upsertCoreCategory({
            admin,
            storeId,
            editToken,
            name: categoryName,
          });

    const description =
      existingProduct?.description ||
      buildInstagramProductDescription({
        caption: media.caption || "",
        storeName: store.name,
        productName,
      });
    const priceText = body.price?.trim() || existingProduct?.price_text || "";
    const stockStatus =
      body.stockStatus?.trim() || existingProduct?.stock_status || "Mevcut";

    const created = await createCoreProduct({
      admin,
      storeId,
      editToken,
      name: productName,
      description,
      priceText,
      imageUrls: imagePath ? [imagePath] : [],
      categoryId,
      sourceType: "instagram",
      externalProductId: media.id,
    });

    await updateCoreProduct({
      admin,
      productId: created.id,
      editToken,
      name: productName,
      description,
      priceText,
      imageUrls: imagePath ? [imagePath] : [],
      categoryId,
      stockStatus,
    });

    const productSlug = created.slug;
    const isNewProduct = created.created;

    const product: ProductItem = {
      id: created.id,
      slug: productSlug,
      name: productName,
      price: priceText,
      description,
      imagePath,
      imageUrls: imagePath ? [imagePath] : [],
      categoryId,
      category: categoryName,
      stockStatus,
      source: "instagram",
      sourceMediaId: media.id,
      sourcePermalink: media.permalink || "",
      importedAt: existingProduct?.created_at || new Date().toISOString(),
    };

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
