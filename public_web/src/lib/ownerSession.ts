// Sahip önizleme oturumu çerezi (implementation_plan.md §5.2, Commit 4 & 7).
//
// Zincir: Flutter tek kullanımlık kod → consume_owner_session
//   → 256-bit session_token (tek kez döner) → SHA-256 hash DB'ye
//   → Next.js session_token'ı HMAC imzalı HttpOnly çerez payload'ına koyar
//   → page.tsx çerezi doğrular, payload içindeki session_token alır
//   → Supabase RPC tokenı hashleyerek owner_sessions kaydıyla eşleştirir
//   → çalışma taslağını döndürür
//   → herhangi bir halka başarısızsa owner modu fail-closed kapanır.

import { createHmac, timingSafeEqual } from "node:crypto";

export const OWNER_SESSION_COOKIE = "vixrex_owner_session";
// Kayan (sliding) oturum penceresi — sabit ömür değil. Panel açıkken
// /api/owner-session-extend her birkaç dakikada bir bu süreyi yeniler;
// gerçekten terk edilirse (sekme arka planda/kapalı kalırsa) düşer.
// Supabase tarafındaki extend_owner_session ile AYNI değer olmalı
// (supabase/migrations/20260813130000_add_extend_owner_session.sql).
// Casper 2026-08-13: sabit, yenilenemeyen 15 dakika "demo ürün parçası
// gibi" bulunduğu için değiştirildi.
export const OWNER_SESSION_TTL_MS = 30 * 60 * 1000;
export const OWNER_SESSION_MAX_AGE_SECONDS = OWNER_SESSION_TTL_MS / 1000;
const OWNER_SESSION_SECRET_MIN_LENGTH = 32;

// V-07 (attack-vectors.md, 2026-08-18): .env.local'deki yerel test değeri
// (43 karakter — uzunluk kontrolünü GEÇİYOR, bu yüzden ayrı bir kontrol
// gerekiyor) attack-vectors.md'de düz metin olarak sızmıştı. Bu tam
// değerle üretime çıkılırsa saldırgan herhangi bir slug için geçerli
// sahip çerezi üretebilir. Üretimde bu değer görülürse fail-closed olunur
// (bkz. assertOwnerSessionConfigured / verifyOwnerSession).
const KNOWN_WEAK_SECRETS = new Set<string>([
  "yerel-test-gizli-anahtari-en-az-32-karakter",
]);

function isKnownWeakSecretInProduction(secret: string): boolean {
  return process.env.NODE_ENV === "production" && KNOWN_WEAK_SECRETS.has(secret);
}

// Payload: storeId, slug, sessionToken, exp
export interface OwnerSession {
  storeId: string;
  slug: string;
  sessionToken: string;
}

interface OwnerSessionPayload extends OwnerSession {
  exp: number;
}

function getSecret(): string {
  return (process.env.OWNER_SESSION_SECRET || "").trim();
}

export function assertOwnerSessionConfigured(): void {
  const secret = getSecret();
  if (secret.length < OWNER_SESSION_SECRET_MIN_LENGTH) {
    throw new Error(
      "OWNER_SESSION_SECRET must be at least 32 characters"
    );
  }
  if (isKnownWeakSecretInProduction(secret)) {
    throw new Error(
      "OWNER_SESSION_SECRET is set to a known local/test value in production — rotate it in Vercel dashboard (V-07)."
    );
  }
}

function encodePayload(payload: OwnerSessionPayload): string {
  return Buffer.from(JSON.stringify(payload), "utf8").toString("base64url");
}

function signPayload(payload: string, secret: string): Buffer {
  return createHmac("sha256", secret).update(payload).digest();
}

// sessionToken: 64 hex char (32 byte) olmalı
export function signOwnerSession(
  storeId: string,
  slug: string,
  sessionToken: string
): string {
  assertOwnerSessionConfigured();
  const secret = getSecret();

  if (!sessionToken || sessionToken.length !== 64 || !/^[0-9a-f]{64}$/i.test(sessionToken)) {
    throw new Error("sessionToken must be 64 hex characters (32 bytes)");
  }

  const payload = encodePayload({
    storeId,
    slug,
    sessionToken,
    exp: Date.now() + OWNER_SESSION_TTL_MS,
  });
  const signature = signPayload(payload, secret).toString("base64url");

  return `${payload}.${signature}`;
}

function verifyOwnerSessionToken(
  token: string | undefined | null,
  slug?: string
): OwnerSession | null {
  if (!token) return null;

  const secret = getSecret();
  if (secret.length < OWNER_SESSION_SECRET_MIN_LENGTH) return null;
  if (isKnownWeakSecretInProduction(secret)) return null;

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
    typeof parsed.sessionToken !== "string" ||
    typeof parsed.exp !== "number"
  ) {
    return null;
  }

  if (slug && parsed.slug !== slug) return null;
  if (parsed.exp <= Date.now()) return null;

  // sessionToken biçimi: 64 hex char
  if (parsed.sessionToken.length !== 64 || !/^[0-9a-f]{64}$/i.test(parsed.sessionToken)) {
    return null;
  }

  return { storeId: parsed.storeId, slug: parsed.slug, sessionToken: parsed.sessionToken };
}

export function verifyOwnerSession(
  token: string | undefined | null,
  slug: string
): OwnerSession | null {
  return verifyOwnerSessionToken(token, slug);
}

/**
 * Yalnız HttpOnly sahip çerezinden vitrin bağlamını çözmek için kullanılır.
 * İmza, süre ve session-token biçimi doğrulanmadan slug döndürmez.
 */
export function verifyOwnerSessionCookie(
  token: string | undefined | null
): OwnerSession | null {
  return verifyOwnerSessionToken(token);
}
