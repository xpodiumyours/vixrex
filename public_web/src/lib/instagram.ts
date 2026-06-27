import crypto from "crypto";

export interface InstagramStatePayload {
  storeSlug: string;
  nonce: string;
  returnTo: string;
  createdAt: number;
}

export interface InstagramMediaItem {
  id: string;
  caption?: string;
  media_type?: string;
  media_url?: string;
  thumbnail_url?: string;
  permalink?: string;
  timestamp?: string;
}

const defaultInstagramScopes = ["instagram_business_basic"];

export function getInstagramScopes() {
  const configured = process.env.INSTAGRAM_SCOPES?.trim();
  const scopes = (configured ? configured.split(",") : defaultInstagramScopes)
    .map((scope) => scope.trim())
    .filter(Boolean);

  const legacyScopes = scopes.filter((scope) =>
    ["user_profile", "user_media", "instagram_graph_user_profile"].includes(scope),
  );
  if (legacyScopes.length > 0) {
    throw new Error(`INSTAGRAM_SCOPES_UNSUPPORTED:${legacyScopes.join(",")}`);
  }

  return [...new Set(scopes)];
}

function base64Url(input: string | Buffer) {
  return Buffer.from(input)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function fromBase64Url(input: string) {
  const padded = input.padEnd(input.length + ((4 - (input.length % 4)) % 4), "=");
  return Buffer.from(padded.replace(/-/g, "+").replace(/_/g, "/"), "base64");
}

function getStateSecret() {
  const secret = process.env.INSTAGRAM_STATE_SECRET;
  if (!secret) throw new Error("INSTAGRAM_STATE_SECRET is missing");
  return secret;
}

export function sha256(value: string) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

export function encodeInstagramState(payload: InstagramStatePayload) {
  const encoded = base64Url(JSON.stringify(payload));
  const signature = crypto
    .createHmac("sha256", getStateSecret())
    .update(encoded)
    .digest("hex");

  return `${encoded}.${signature}`;
}

export function decodeInstagramState(state: string) {
  const [encoded, signature] = state.split(".");
  if (!encoded || !signature) throw new Error("Invalid Instagram state");

  const expectedSignature = crypto
    .createHmac("sha256", getStateSecret())
    .update(encoded)
    .digest("hex");

  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature))) {
    throw new Error("Invalid Instagram state signature");
  }

  const payload = JSON.parse(fromBase64Url(encoded).toString("utf8")) as InstagramStatePayload;
  if (!payload.storeSlug || !payload.nonce || !payload.createdAt) {
    throw new Error("Invalid Instagram state payload");
  }

  if (Date.now() - payload.createdAt > 15 * 60 * 1000) {
    throw new Error("Instagram state expired");
  }

  return payload;
}

function getEncryptionKey() {
  const raw = process.env.INSTAGRAM_TOKEN_ENCRYPTION_KEY || "";
  if (!raw) throw new Error("INSTAGRAM_TOKEN_ENCRYPTION_KEY is missing");

  const base64Key = Buffer.from(raw, "base64");
  if (base64Key.length === 32) return base64Key;

  if (/^[a-f0-9]{64}$/i.test(raw)) {
    return Buffer.from(raw, "hex");
  }

  const utf8Key = Buffer.from(raw, "utf8");
  if (utf8Key.length === 32) return utf8Key;

  throw new Error("INSTAGRAM_TOKEN_ENCRYPTION_KEY must be 32 bytes");
}

export function encryptSecret(value: string) {
  const key = getEncryptionKey();
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv("aes-256-gcm", key, iv);
  const encrypted = Buffer.concat([cipher.update(value, "utf8"), cipher.final()]);
  const authTag = cipher.getAuthTag();

  return [
    "v1",
    base64Url(iv),
    base64Url(authTag),
    base64Url(encrypted),
  ].join(":");
}

export function decryptSecret(value: string) {
  const [version, ivRaw, tagRaw, encryptedRaw] = value.split(":");
  if (version !== "v1" || !ivRaw || !tagRaw || !encryptedRaw) {
    throw new Error("Invalid encrypted token format");
  }

  const decipher = crypto.createDecipheriv("aes-256-gcm", getEncryptionKey(), fromBase64Url(ivRaw));
  decipher.setAuthTag(fromBase64Url(tagRaw));

  return Buffer.concat([
    decipher.update(fromBase64Url(encryptedRaw)),
    decipher.final(),
  ]).toString("utf8");
}

export function sanitizeInstagramMedia(media: Record<string, unknown>): InstagramMediaItem {
  return {
    id: String(media.id || ""),
    caption: typeof media.caption === "string" ? media.caption : "",
    media_type: typeof media.media_type === "string" ? media.media_type : "",
    media_url: typeof media.media_url === "string" ? media.media_url : "",
    thumbnail_url:
      typeof media.thumbnail_url === "string" ? media.thumbnail_url : "",
    permalink: typeof media.permalink === "string" ? media.permalink : "",
    timestamp: typeof media.timestamp === "string" ? media.timestamp : "",
  };
}
