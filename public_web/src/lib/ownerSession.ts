// Sahip önizleme oturumu çerezi (implementation_plan.md §5.2, Commit 4).
//
// Tek kullanımlık kod, giriş rotasında tüketilir; burada kod tekrar saklanmaz.
// Çereze, yalnız ilgili vitrini (slug) ve sınırlı süreyi (TTL) bağlayan
// HMAC-SHA256 imzalı bir değer yazılır. Sayfa her istekte imzayı ve slug
// eşleşmesini doğrular; başka bir vitrinin çerezi burada reddedilir.
//
// Yalnızca sunucu tarafında kullanılır. Gizli anahtar tarayıcıya sızmaz.

import { createHmac, timingSafeEqual } from "node:crypto";

export const OWNER_SESSION_COOKIE = "vixrex_owner_session";
export const OWNER_SESSION_TTL_MS = 15 * 60 * 1000;
export const OWNER_SESSION_MAX_AGE_SECONDS = OWNER_SESSION_TTL_MS / 1000;
const OWNER_SESSION_SECRET_MIN_LENGTH = 32;

export interface OwnerSession {
  storeId: string;
  slug: string;
}

interface OwnerSessionPayload extends OwnerSession {
  exp: number;
}

function getSecret(): string {
  return (process.env.OWNER_SESSION_SECRET || "").trim();
}

export function assertOwnerSessionConfigured(): void {
  if (getSecret().length < OWNER_SESSION_SECRET_MIN_LENGTH) {
    throw new Error(
      "OWNER_SESSION_SECRET must be at least 32 characters"
    );
  }
}

function encodePayload(payload: OwnerSessionPayload): string {
  return Buffer.from(JSON.stringify(payload), "utf8").toString("base64url");
}

function signPayload(payload: string, secret: string): Buffer {
  return createHmac("sha256", secret).update(payload).digest();
}

export function signOwnerSession(storeId: string, slug: string): string {
  assertOwnerSessionConfigured();
  const secret = getSecret();

  const payload = encodePayload({
    storeId,
    slug,
    exp: Date.now() + OWNER_SESSION_TTL_MS,
  });
  const signature = signPayload(payload, secret).toString("base64url");

  return `${payload}.${signature}`;
}

export function verifyOwnerSession(
  token: string | undefined | null,
  slug: string
): OwnerSession | null {
  if (!token) return null;

  const secret = getSecret();
  if (secret.length < OWNER_SESSION_SECRET_MIN_LENGTH) return null;

  const separatorIndex = token.indexOf(".");
  if (separatorIndex <= 0 || separatorIndex === token.length - 1) return null;

  const payload = token.slice(0, separatorIndex);
  const provided = token.slice(separatorIndex + 1);

  const providedBytes = Buffer.from(provided, "base64url");
  const expectedBytes = signPayload(payload, secret);

  if (
    providedBytes.length !== expectedBytes.length ||
    !timingSafeEqual(providedBytes, expectedBytes)
  ) {
    return null;
  }

  let parsed: OwnerSessionPayload;
  try {
    parsed = JSON.parse(
      Buffer.from(payload, "base64url").toString("utf8")
    ) as OwnerSessionPayload;
  } catch {
    return null;
  }

  if (
    typeof parsed.storeId !== "string" ||
    typeof parsed.slug !== "string" ||
    typeof parsed.exp !== "number"
  ) {
    return null;
  }

  if (parsed.slug !== slug) return null;
  if (parsed.exp <= Date.now()) return null;

  return { storeId: parsed.storeId, slug: parsed.slug };
}
