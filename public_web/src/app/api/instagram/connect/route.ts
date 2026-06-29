import { NextRequest } from "next/server";
import crypto from "crypto";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { encodeInstagramState, getInstagramScopes, sha256 } from "@/lib/instagram";
import {
  getPublicSiteOrigin,
  normalizeStoreAuth,
  trimOrEmpty,
} from "@/lib/instagramRouteUtils";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import {
  instagramErrorStatus,
  instagramJson,
  instagramOptions,
} from "@/lib/instagramApi";

export const runtime = "nodejs";

function requiredEnv(name: string, fallback?: string) {
  const value = process.env[name] || fallback;
  if (!value) throw new Error(`${name} is missing`);
  return value;
}

function safeReturnTo(value: string | null, storeSlug: string) {
  if (value && value.startsWith("/")) return value;
  return `/v/${storeSlug}`;
}

async function createAuthorizationUrl(args: {
  req: NextRequest;
  storeSlug: string;
  editToken: string;
  returnTo: string;
}) {
  const { req, storeSlug, editToken, returnTo } = args;
  const store = await verifyStoreEditToken(storeSlug, editToken);
  const admin = getSupabaseAdmin();
  const nonce = crypto.randomUUID();
  const scopes = getInstagramScopes();
  const redirectUri =
    process.env.INSTAGRAM_REDIRECT_URI ||
    `${getPublicSiteOrigin(req)}/api/instagram/callback`;

  const state = encodeInstagramState({
    storeSlug: store.slug,
    nonce,
    returnTo,
    createdAt: Date.now(),
  });

  const { error } = await admin.from("store_instagram_connections").upsert(
    {
      store_slug: store.slug,
      user_id: store.user_id || null,
      status: "pending",
      state_nonce: nonce,
      edit_token_hash: sha256(editToken),
      scopes,
    },
    { onConflict: "store_slug" }
  );

  if (error) throw error;

  const authUrl = new URL(
    requiredEnv("INSTAGRAM_AUTHORIZATION_URL", "https://www.instagram.com/oauth/authorize")
  );
  authUrl.searchParams.set("client_id", requiredEnv("INSTAGRAM_CLIENT_ID"));
  authUrl.searchParams.set("redirect_uri", redirectUri);
  authUrl.searchParams.set("response_type", "code");
  authUrl.searchParams.set("scope", scopes.join(","));
  authUrl.searchParams.set("state", state);

  return authUrl;
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as {
      storeSlug?: string;
      editToken?: string;
      returnTo?: string;
    };
    const { storeSlug, editToken } = normalizeStoreAuth(body);
    const returnTo = safeReturnTo(trimOrEmpty(body.returnTo) || null, storeSlug);
    const authUrl = await createAuthorizationUrl({
      req,
      storeSlug,
      editToken,
      returnTo,
    });

    return instagramJson(req, { authorizationUrl: authUrl.toString() });
  } catch (error) {
    const message = error instanceof Error ? error.message : "INSTAGRAM_CONNECT_FAILED";
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
