import { NextRequest } from "next/server";
import type { SupabaseClient } from "@supabase/supabase-js";
import dns from "node:dns";
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

const ALLOWED_INSTAGRAM_MEDIA_HOSTS = new Set([
  "graph.instagram.com",
  "cdn.instagram.com",
]);

const TRUSTED_EXACT_HOSTS = new Set([
  "graph.instagram.com",
  "cdn.instagram.com",
]);

const MAX_INSTAGRAM_MEDIA_REDIRECTS = 5;

function hostInAllowlist(host: string): boolean {
  const lower = host.toLowerCase();
  return (
    ALLOWED_INSTAGRAM_MEDIA_HOSTS.has(lower) ||
    /\.cdninstagram\.com$/i.test(lower)
  );
}

function assertInstagramMediaUrl(rawUrl: string): string {
  const trimmed = rawUrl.trim();

  if (!trimmed) {
    throw new Error("INSTAGRAM_MEDIA_URL_EMPTY");
  }

  let parsed: URL;
  try {
    parsed = new URL(trimmed);
  } catch {
    throw new Error("INSTAGRAM_MEDIA_URL_INVALID");
  }

  if (parsed.protocol !== "https:") {
    throw new Error("INSTAGRAM_MEDIA_URL_INVALID");
  }

  if (!hostInAllowlist(parsed.host)) {
    throw new Error("INSTAGRAM_MEDIA_URL_INVALID");
  }

  return trimmed;
}

// Rejects RFC1918 / loopback / link-local / reserved / IPv6 internal ranges.
// Invalid IPv4 octets are treated as unsafe and rejected.
function isInternalIp(address: string): boolean {
  const ipv4 = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(address);
  if (ipv4) {
    const [a, b, c, d] = ipv4.slice(1).map((n) => Number(n));
    if (a > 255 || b > 255 || c > 255 || d > 255) return true;
    if (a === 0) return true; // "this" network
    if (a === 10) return true; // private
    if (a === 127) return true; // loopback
    if (a === 169 && b === 254) return true; // link-local (incl. 169.254.169.254)
    if (a === 172 && b >= 16 && b <= 31) return true; // private
    if (a === 192 && b === 168) return true; // private
    if (a === 100 && b >= 64 && b <= 127) return true; // CGNAT
    if (a >= 224) return true; // multicast / reserved
    return false;
  }

  const v6 = address.toLowerCase();
  if (v6 === "::1") return true; // loopback
  if (v6 === "::") return true; // unspecified
  if (v6.startsWith("fe80")) return true; // link-local
  if (v6.startsWith("fc") || v6.startsWith("fd")) return true; // unique local
  if (v6.startsWith("::ffff:")) {
    return isInternalIp(v6.slice("::ffff:".length));
  }
  return false;
}

// Defense-in-depth: resolve the hostname and reject internal addresses so a
// DNS-rebinding style redirect to an internal IP is blocked even when the
// hostname itself passes the allowlist. Known-good exact hosts are trusted to
// avoid network lookups during normal operation.
async function assertHostResolvesPublic(hostname: string): Promise<void> {
  const lower = hostname.toLowerCase();
  if (TRUSTED_EXACT_HOSTS.has(lower)) return;

  let addresses: { address: string; family: number }[];
  try {
    addresses = await dns.promises.lookup(lower, { all: true });
  } catch {
    throw new Error("INSTAGRAM_MEDIA_URL_INTERNAL_INVALID");
  }

  for (const { address } of addresses) {
    if (isInternalIp(address)) {
      throw new Error("INSTAGRAM_MEDIA_URL_INTERNAL_INVALID");
    }
  }
}

// SSRF-safe media fetch: never follows redirects implicitly. Each 3xx hop is
// re-validated against the same allowlist + internal-IP guard before the next
// request is issued.
async function fetchAllowedMedia(mediaUrl: string): Promise<Response> {
  let currentUrl = assertInstagramMediaUrl(mediaUrl);
  const seen = new Set<string>([currentUrl]);

  for (let step = 0; step <= MAX_INSTAGRAM_MEDIA_REDIRECTS; step++) {
    const parsed = new URL(currentUrl);
    await assertHostResolvesPublic(parsed.host);

    const response = await fetch(currentUrl, { redirect: "manual" });

    if (response.status >= 300 && response.status < 400) {
      const location = response.headers.get("location");
      if (!location) throw new Error("INSTAGRAM_MEDIA_REDIRECT_INVALID");

      const nextUrl = new URL(location, currentUrl).toString();
      if (seen.has(nextUrl)) throw new Error("INSTAGRAM_MEDIA_REDIRECT_LOOP");
      seen.add(nextUrl);

      currentUrl = assertInstagramMediaUrl(nextUrl);
      continue;
    }

    if (!response.ok) throw new Error("INSTAGRAM_MEDIA_DOWNLOAD_FAILED");
    return response;
  }

  throw new Error("INSTAGRAM_MEDIA_REDIRECT_TOO_MANY");
}

async function uploadInstagramMedia(args: {
  mediaUrl: string;
  storeSlug: string;
  mediaId: string;
  admin: SupabaseClient;
}) {
  const response = await fetchAllowedMedia(args.mediaUrl);

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
    const originalMessage = error instanceof Error ? error.message : "INSTAGRAM_IMPORT_FAILED";
    const status = instagramErrorStatus(originalMessage);
    console.error("[instagram/import] error:", originalMessage);
    return instagramJson(
      req,
      { message: "INSTAGRAM_IMPORT_FAILED" },
      { status },
    );
  }
}

export function OPTIONS(req: NextRequest) {
  return instagramOptions(req);
}
