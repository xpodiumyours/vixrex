import { NextRequest, NextResponse } from "next/server";
import { decodeInstagramState, encryptSecret } from "@/lib/instagram";
import { buildInstagramGraphUrl, getPublicSiteOrigin } from "@/lib/instagramRouteUtils";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { exchangeForLongLivedInstagramToken } from "@/lib/instagramServer";

export const runtime = "nodejs";

interface OAuthTokenResponse {
  access_token?: string;
  user_id?: number | string;
  token_type?: string;
  expires_in?: number;
  error_message?: string;
  error?: {
    message?: string;
  };
}

interface InstagramProfileResponse {
  id?: string;
  username?: string;
  account_type?: string;
}

function callbackRedirect(req: NextRequest, returnTo: string, status: string) {
  const url = new URL(returnTo || "/", getPublicSiteOrigin(req));
  url.searchParams.set("instagram", status);
  return NextResponse.redirect(url);
}

export async function GET(req: NextRequest) {
  const code = req.nextUrl.searchParams.get("code") || "";
  const state = req.nextUrl.searchParams.get("state") || "";

  try {
    if (!code || !state) throw new Error("INSTAGRAM_CALLBACK_MISSING_CODE");

    const payload = decodeInstagramState(state);
    const admin = getSupabaseAdmin();
    const redirectUri =
      process.env.INSTAGRAM_REDIRECT_URI ||
      `${getPublicSiteOrigin(req)}/api/instagram/callback`;

    const { data: connection, error: connectionError } = await admin
      .from("store_instagram_connections")
      .select("id,store_slug,state_nonce,status")
      .eq("store_slug", payload.storeSlug)
      .eq("state_nonce", payload.nonce)
      .eq("status", "pending")
      .maybeSingle();

    if (connectionError || !connection) {
      throw new Error("INSTAGRAM_PENDING_CONNECTION_NOT_FOUND");
    }

    const tokenBody = new URLSearchParams({
      client_id: process.env.INSTAGRAM_CLIENT_ID || "",
      client_secret: process.env.INSTAGRAM_CLIENT_SECRET || "",
      grant_type: "authorization_code",
      redirect_uri: redirectUri,
      code,
    });

    if (!process.env.INSTAGRAM_CLIENT_ID || !process.env.INSTAGRAM_CLIENT_SECRET) {
      throw new Error("INSTAGRAM_CLIENT_ENV_MISSING");
    }

    const tokenResponse = await fetch(
      process.env.INSTAGRAM_TOKEN_URL || "https://api.instagram.com/oauth/access_token",
      {
        method: "POST",
        body: tokenBody,
      }
    );
    const tokenJson = (await tokenResponse.json()) as OAuthTokenResponse;

    if (!tokenResponse.ok || !tokenJson.access_token) {
      throw new Error(
        tokenJson.error?.message ||
          tokenJson.error_message ||
          "INSTAGRAM_TOKEN_EXCHANGE_FAILED"
      );
    }

    const longLivedToken = await exchangeForLongLivedInstagramToken(
      tokenJson.access_token,
    );
    const accessToken = longLivedToken.access_token!;
    const profileUrl = buildInstagramGraphUrl("/me");
    profileUrl.searchParams.set("fields", "id,username,account_type");
    profileUrl.searchParams.set("access_token", accessToken);
    const profileResponse = await fetch(profileUrl, { cache: "no-store" });
    const profileJson = profileResponse.ok
      ? ((await profileResponse.json()) as InstagramProfileResponse)
      : {};

    const expiresAt = longLivedToken.expires_in
      ? new Date(Date.now() + longLivedToken.expires_in * 1000).toISOString()
      : null;

    const connectionId = String(connection.id);
    const { error: tokenSaveError } = await admin.from("store_instagram_tokens").upsert(
      {
        connection_id: connectionId,
        access_token_ciphertext: encryptSecret(accessToken),
        token_type: longLivedToken.token_type || "bearer",
        expires_at: expiresAt,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "connection_id" }
    );

    if (tokenSaveError) throw tokenSaveError;

    const { error: connectionSaveError } = await admin
      .from("store_instagram_connections")
      .update({
        status: "connected",
        instagram_user_id: String(profileJson.id || tokenJson.user_id || ""),
        username: profileJson.username || null,
        account_type: profileJson.account_type || null,
        connected_at: new Date().toISOString(),
        expires_at: expiresAt,
        state_nonce: null,
      })
      .eq("id", connectionId);

    if (connectionSaveError) throw connectionSaveError;

    return callbackRedirect(req, payload.returnTo, "connected");
  } catch (error) {
    const message = error instanceof Error ? error.message : "INSTAGRAM_CALLBACK_FAILED";
    console.error("[instagram/callback]", message);
    return callbackRedirect(req, "/", "error");
  }
}
