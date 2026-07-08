import { revalidatePath, revalidateTag } from "next/cache";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { decryptSecret, encryptSecret, sha256 } from "@/lib/instagram";

export interface EditableStoreRow {
  slug: string;
  name: string;
  user_id?: string | null;
  edit_token?: string;
  products?: unknown;
  whatsapp?: string;
  instagram?: string;
  is_published?: boolean;
}

interface InstagramConnectionRow {
  id: string;
  store_slug: string;
  status: string;
  edit_token_hash?: string | null;
  username?: string | null;
  account_type?: string | null;
  expires_at?: string | null;
}

interface InstagramTokenRow {
  connection_id: string;
  access_token_ciphertext: string;
  expires_at?: string | null;
  updated_at?: string | null;
}

interface InstagramTokenResponse {
  access_token?: string;
  token_type?: string;
  expires_in?: number;
  error?: {
    message?: string;
  };
}

function getInstagramGraphBaseUrl() {
  return process.env.INSTAGRAM_GRAPH_BASE_URL || "https://graph.instagram.com";
}

function expiresAtFromSeconds(expiresIn?: number) {
  return expiresIn
    ? new Date(Date.now() + expiresIn * 1000).toISOString()
    : null;
}

async function readInstagramTokenResponse(response: Response, fallback: string) {
  const json = (await response.json()) as InstagramTokenResponse;
  if (!response.ok || !json.access_token) {
    throw new Error(json.error?.message || fallback);
  }
  return json;
}

export async function exchangeForLongLivedInstagramToken(
  shortLivedAccessToken: string,
) {
  const clientSecret = process.env.INSTAGRAM_CLIENT_SECRET;
  if (!clientSecret) throw new Error("INSTAGRAM_CLIENT_ENV_MISSING");

  const url = new URL(`${getInstagramGraphBaseUrl()}/access_token`);
  url.searchParams.set("grant_type", "ig_exchange_token");
  url.searchParams.set("client_secret", clientSecret);
  url.searchParams.set("access_token", shortLivedAccessToken);

  return readInstagramTokenResponse(
    await fetch(url, { cache: "no-store" }),
    "INSTAGRAM_LONG_LIVED_TOKEN_FAILED",
  );
}

async function refreshLongLivedInstagramToken(accessToken: string) {
  const url = new URL(`${getInstagramGraphBaseUrl()}/refresh_access_token`);
  url.searchParams.set("grant_type", "ig_refresh_token");
  url.searchParams.set("access_token", accessToken);

  return readInstagramTokenResponse(
    await fetch(url, { cache: "no-store" }),
    "INSTAGRAM_TOKEN_REFRESH_FAILED",
  );
}

export async function verifyStoreEditToken(storeSlug: string, editToken: string) {
  const admin = getSupabaseAdmin();

  if (!storeSlug.trim() || !editToken.trim()) {
    throw new Error("STORE_AUTH_REQUIRED");
  }

  const { data, error } = await admin
    .from("stores")
    .select("slug,name,user_id,edit_token,products,whatsapp,instagram,is_published")
    .eq("slug", storeSlug)
    .eq("edit_token", editToken)
    .single();

  if (error || !data) {
    throw new Error("STORE_AUTH_FAILED");
  }

  return data as EditableStoreRow;
}

export async function getConnectedInstagramAccess(storeSlug: string, editToken: string) {
  const admin = getSupabaseAdmin();
  const store = await verifyStoreEditToken(storeSlug, editToken);
  const editTokenHash = sha256(editToken);

  const { data: connection, error: connectionError } = await admin
    .from("store_instagram_connections")
    .select("id,store_slug,status,edit_token_hash,username,account_type,expires_at")
    .eq("store_slug", store.slug)
    .eq("status", "connected")
    .maybeSingle();

  if (connectionError || !connection) {
    throw new Error("INSTAGRAM_NOT_CONNECTED");
  }

  const typedConnection = connection as InstagramConnectionRow;
  if (typedConnection.edit_token_hash && typedConnection.edit_token_hash !== editTokenHash) {
    throw new Error("STORE_AUTH_FAILED");
  }

  const { data: token, error: tokenError } = await admin
    .from("store_instagram_tokens")
    .select("connection_id,access_token_ciphertext,expires_at,updated_at")
    .eq("connection_id", typedConnection.id)
    .maybeSingle();

  if (tokenError || !token) {
    throw new Error("INSTAGRAM_TOKEN_MISSING");
  }

  const typedToken = token as InstagramTokenRow;
  let accessToken = decryptSecret(typedToken.access_token_ciphertext);
  let expiresAt = typedToken.expires_at || typedConnection.expires_at || null;
  const expiresAtMs = expiresAt ? Date.parse(expiresAt) : Number.NaN;

  if (Number.isFinite(expiresAtMs) && expiresAtMs <= Date.now()) {
    throw new Error("INSTAGRAM_TOKEN_EXPIRED");
  }

  const refreshWindowMs = 7 * 24 * 60 * 60 * 1000;
  const tokenAgeMs = typedToken.updated_at
    ? Date.now() - Date.parse(typedToken.updated_at)
    : Number.POSITIVE_INFINITY;
  const shouldRefresh =
    Number.isFinite(expiresAtMs) &&
    expiresAtMs - Date.now() <= refreshWindowMs &&
    tokenAgeMs >= 24 * 60 * 60 * 1000;

  if (shouldRefresh) {
    try {
      const refreshed = await refreshLongLivedInstagramToken(accessToken);
      accessToken = refreshed.access_token!;
      expiresAt = expiresAtFromSeconds(refreshed.expires_in);
      const now = new Date().toISOString();

      const { error: refreshSaveError } = await admin
        .from("store_instagram_tokens")
        .update({
          access_token_ciphertext: encryptSecret(accessToken),
          token_type: refreshed.token_type || "bearer",
          expires_at: expiresAt,
          updated_at: now,
        })
        .eq("connection_id", typedConnection.id);
      if (refreshSaveError) throw refreshSaveError;

      await admin
        .from("store_instagram_connections")
        .update({ expires_at: expiresAt, updated_at: now })
        .eq("id", typedConnection.id);
    } catch (error) {
      console.error("[instagram/token-refresh]", error);
      // Token refresh başarısız oldu - bağlantıyı hata durumuna geç
      await admin
        .from("store_instagram_connections")
        .update({ 
          status: "refresh_error",
          updated_at: new Date().toISOString()
        })
        .eq("id", typedConnection.id);
    }
  }

  return {
    admin,
    store,
    connection: typedConnection,
    accessToken,
    expiresAt,
  };
}

export function revalidateProductTargets(
  storeSlug: string,
  productSlug: string,
  sitemapChanged: boolean,
) {
  revalidateTag(`store-${storeSlug}`, "max");
  revalidateTag(`products-${storeSlug}`, "max");
  revalidateTag(`product-${storeSlug}-${productSlug}`, "max");
  revalidatePath(`/v/${storeSlug}/urun/${productSlug}`, "page");

  if (sitemapChanged) {
    revalidateTag("sitemap", "max");
  }
}
